using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using dotnet_api.Data;
using Microsoft.EntityFrameworkCore;

namespace dotnet_api.Services;

public class DeliveryStatusWorker : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ILogger<DeliveryStatusWorker> _logger;

    private static readonly TimeSpan _interval = TimeSpan.FromMinutes(3);

    public DeliveryStatusWorker(
        IServiceScopeFactory scopeFactory,
        IHttpClientFactory httpClientFactory,
        ILogger<DeliveryStatusWorker> logger)
    {
        _scopeFactory = scopeFactory;
        _httpClientFactory = httpClientFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await RetryPendingSendsAsync(stoppingToken);
                await CheckDeliveryStatusesAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "DeliveryStatusWorker iteration failed");
            }

            await Task.Delay(_interval, stoppingToken);
        }
    }

    // Phase 1: recipients saved as Pending with no gateway ID — SMS was never sent.
    private async Task RetryPendingSendsAsync(CancellationToken ct)
    {
        using var scope = _scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

        var unsent = await db.NotificationRecipients
            .Where(r => r.Status == "Pending" && r.GatewayMessageId == null)
            .Include(r => r.Notification)
            .ToListAsync(ct);

        if (unsent.Count == 0) return;

        _logger.LogInformation("DeliveryStatusWorker retrying {Count} unsent recipients", unsent.Count);

        var byUser = unsent.GroupBy(r =>
            r.Notification!.CreatedByUserId ?? r.Notification.UserId);

        foreach (var group in byUser)
        {
            var userId = group.Key;
            if (string.IsNullOrWhiteSpace(userId)) continue;

            var client = await db.Clients.FirstOrDefaultAsync(c => c.UserId == userId, ct);
            if (client == null) continue;

            var link = await db.ClientSmsGateways
                .Include(csg => csg.SmsGateway)
                .FirstOrDefaultAsync(csg => csg.ClientId == client.Id, ct);
            if (link == null) continue;

            var creds = await db.SmsGatewayCredentials
                .Where(c => c.SmsGatewayId == link.SmsGatewayId)
                .ToListAsync(ct);

            var provider = link.SmsGateway.Provider?.ToLowerInvariant() ?? "";
            var endpoint = creds.FirstOrDefault(c => c.Key == "endpoint")?.Value;
            var apiKey   = creds.FirstOrDefault(c => c.Key == "api_key")?.Value;
            var senderId = creds.FirstOrDefault(c => c.Key == "sender_id")?.Value;
            var username = creds.FirstOrDefault(c => c.Key == "username")?.Value;
            var password = creds.FirstOrDefault(c => c.Key == "password")?.Value;

            if (string.IsNullOrWhiteSpace(endpoint)) continue;

            var httpClient = _httpClientFactory.CreateClient();

            var clientPayments = await db.ClientPayments
                .Where(p => p.ClientId == client.Id && p.SmsConsumed < p.SmsAllocated)
                .OrderBy(p => p.PaidAt)
                .ToListAsync(ct);

            foreach (var recipient in group)
            {
                var resolvedMessage = ResolveTemplate(recipient.Notification!.Message, recipient.Name);
                try
                {
                    string? gatewayId = null;
                    bool success;

                    if (provider == "tumirai")
                    {
                        if (string.IsNullOrWhiteSpace(apiKey)) continue;

                        var req = new HttpRequestMessage(HttpMethod.Post, endpoint);
                        req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
                        // Stable idempotency key so a crash-and-retry doesn't double-send.
                        req.Headers.Add("Idempotency-Key",
                            $"{recipient.PhoneNumber.TrimStart('+')}-retry-{recipient.Id}");
                        req.Content = new StringContent(
                            JsonSerializer.Serialize(new
                            {
                                to        = recipient.PhoneNumber,
                                sender_id = senderId ?? "",
                                text      = resolvedMessage,
                            }),
                            Encoding.UTF8, "application/json");

                        var resp = await httpClient.SendAsync(req, ct);
                        success = resp.IsSuccessStatusCode;

                        if (success)
                        {
                            try
                            {
                                var body = await resp.Content.ReadAsStringAsync(ct);
                                using var doc = JsonDocument.Parse(body);
                                if (doc.RootElement.TryGetProperty("data", out var data) &&
                                    data.TryGetProperty("id", out var idEl))
                                    gatewayId = idEl.GetString();
                            }
                            catch { /* ignore parse errors */ }
                        }
                    }
                    else
                    {
                        var qs = $"user={Uri.EscapeDataString(username ?? "")}" +
                                 $"&password={Uri.EscapeDataString(password ?? "")}" +
                                 $"&msisdn={Uri.EscapeDataString(recipient.PhoneNumber)}" +
                                 $"&message={Uri.EscapeDataString(resolvedMessage)}";
                        var resp = await httpClient.GetAsync($"{endpoint.TrimEnd('?')}?{qs}", ct);
                        success = resp.IsSuccessStatusCode;
                    }

                    recipient.Status = success ? "Sent" : "Failed";
                    if (gatewayId != null) recipient.GatewayMessageId = gatewayId;

                    if (success)
                    {
                        var units = (int)Math.Ceiling(resolvedMessage.Length / 160.0);
                        var remaining = units;
                        foreach (var payment in clientPayments)
                        {
                            if (remaining <= 0) break;
                            var available = payment.SmsAllocated - payment.SmsConsumed;
                            var deduct = Math.Min(remaining, available);
                            payment.SmsConsumed += deduct;
                            remaining -= deduct;
                        }
                    }

                    _logger.LogInformation(
                        "Retry send {Phone} → {Status} (gateway: {GatewayId})",
                        recipient.PhoneNumber, recipient.Status, gatewayId ?? "none");
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Retry send failed for {Phone}", recipient.PhoneNumber);
                }
            }

            // Recompute parent notification delivery status.
            foreach (var notifGroup in group.GroupBy(r => r.NotificationId))
            {
                var notification = notifGroup.First().Notification!;
                var all = await db.NotificationRecipients
                    .Where(r => r.NotificationId == notification.Id)
                    .ToListAsync(ct);

                var sentCount    = all.Count(r => r.Status is "Sent" or "Delivered");
                var failedCount  = all.Count(r => r.Status == "Failed");
                var pendingCount = all.Count(r => r.Status == "Pending");

                notification.DeliveryStatus =
                    pendingCount > 0                          ? "Pending"
                    : failedCount == 0                        ? "Sent"
                    : sentCount   == 0                        ? "Failed"
                    :                                           "Partial";
            }
        }

        await db.SaveChangesAsync(ct);
    }

    // Phase 2: recipients with a gateway ID — check if delivery was confirmed.
    private async Task CheckDeliveryStatusesAsync(CancellationToken ct)
    {
        using var scope = _scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

        var pending = await db.NotificationRecipients
            .Where(r => r.GatewayMessageId != null && r.DeliveredAt == null)
            .Include(r => r.Notification)
            .ToListAsync(ct);

        if (pending.Count == 0) return;

        _logger.LogInformation("DeliveryStatusWorker checking {Count} sent recipients", pending.Count);

        var byUser = pending.GroupBy(r =>
            r.Notification!.CreatedByUserId ?? r.Notification.UserId);

        foreach (var group in byUser)
        {
            var userId = group.Key;
            if (string.IsNullOrWhiteSpace(userId)) continue;

            var client = await db.Clients.FirstOrDefaultAsync(c => c.UserId == userId, ct);
            if (client == null) continue;

            var link = await db.ClientSmsGateways
                .Include(csg => csg.SmsGateway)
                .FirstOrDefaultAsync(csg => csg.ClientId == client.Id, ct);
            if (link == null) continue;

            var creds = await db.SmsGatewayCredentials
                .Where(c => c.SmsGatewayId == link.SmsGatewayId)
                .ToListAsync(ct);

            var apiKey = creds.FirstOrDefault(c => c.Key == "api_key")?.Value;

            if (string.IsNullOrWhiteSpace(apiKey))
            {
                _logger.LogWarning("Phase2 skipping client {ClientId} — api_key missing", client.Id);
                continue;
            }

            var httpClient = _httpClientFactory.CreateClient();
            httpClient.DefaultRequestHeaders.Authorization =
                new AuthenticationHeaderValue("Bearer", apiKey);

            foreach (var recipient in group)
            {
                try
                {
                    var url = $"https://tumirai.co.zw/v1/messages/{recipient.GatewayMessageId}";
                    _logger.LogInformation("Phase2 GET {Url}", url);
                    var response = await httpClient.GetAsync(url, ct);
                    if (!response.IsSuccessStatusCode)
                    {
                        _logger.LogWarning("Phase2 {Url} → {StatusCode}", url, (int)response.StatusCode);
                        continue;
                    }

                    var body = await response.Content.ReadAsStringAsync(ct);
                    recipient.GatewayPayload = body;
                    using var doc = JsonDocument.Parse(body);

                    DateTime? deliveredAt = null;
                    decimal? costAmount = null;
                    string? costCurrency = null;

                    // Tumirai status endpoint returns a flat object:
                    // {"id":"...","status":"delivered","provider_status":"DELIVERED","delivered_at":"2026-04-29T13:42:17+02:00"}
                    // The send endpoint wraps fields under "data" and may include cost.
                    // Support both shapes.
                    var root = doc.RootElement;
                    var dataEl = root.TryGetProperty("data", out var nested) ? nested : root;

                    if (dataEl.TryGetProperty("delivered_at", out var dat) &&
                        dat.ValueKind != JsonValueKind.Null)
                    {
                        var dateStr = dat.GetString() ?? "";
                        // ISO 8601 with offset (e.g. "2026-04-29T13:42:17+02:00") — keep wall time.
                        if (DateTimeOffset.TryParse(dateStr, out var dto))
                            deliveredAt = dto.DateTime;
                        else if (DateTime.TryParse(dateStr, out var dt))
                            deliveredAt = dt;
                    }

                    if (dataEl.TryGetProperty("cost", out var cost))
                    {
                        if (cost.TryGetProperty("amount", out var amt) &&
                            amt.ValueKind == JsonValueKind.Number)
                            costAmount = amt.GetDecimal();
                        if (cost.TryGetProperty("currency", out var cur))
                            costCurrency = cur.GetString();
                    }

                    if (costAmount != null) recipient.CostAmount = costAmount;
                    if (costCurrency != null) recipient.CostCurrency = costCurrency;

                    if (deliveredAt != null && recipient.DeliveredAt == null)
                    {
                        recipient.DeliveredAt = deliveredAt;
                        _logger.LogInformation(
                            "Recipient {Phone} DeliveredAt={DeliveredAt} (gateway: {GatewayId})",
                            recipient.PhoneNumber, deliveredAt, recipient.GatewayMessageId);
                    }
                    else if (deliveredAt == null)
                    {
                        _logger.LogDebug(
                            "Recipient {Phone} — no delivered_at in response (gateway: {GatewayId})",
                            recipient.PhoneNumber, recipient.GatewayMessageId);
                    }

                    if (recipient.Status == "Pending")
                    {
                        recipient.Status = "Sent";
                        _logger.LogInformation(
                            "Recipient {Phone} Pending→Sent (gateway: {GatewayId})",
                            recipient.PhoneNumber, recipient.GatewayMessageId);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Status check failed for gateway ID {GatewayId}",
                        recipient.GatewayMessageId);
                }
            }
        }

        await db.SaveChangesAsync(ct);
    }

    private static string ResolveTemplate(string template, string? recipientName)
    {
        var name = recipientName ?? "";

        return template
            .Replace("[Name]",      name, StringComparison.OrdinalIgnoreCase)
            .Replace("[FirstName]", name, StringComparison.OrdinalIgnoreCase)
            .Replace("{Name}",      name, StringComparison.OrdinalIgnoreCase)
            .Replace("{FirstName}", name, StringComparison.OrdinalIgnoreCase);
    }
}
