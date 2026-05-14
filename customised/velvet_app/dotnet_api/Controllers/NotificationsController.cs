using System.Security.Claims;
using dotnet_api.Data;
using dotnet_api.Interfaces;
using dotnet_api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace dotnet_api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly INotificationService _notificationService;
    private readonly IAuthService _authService;
    private readonly ApplicationDbContext _dbContext;

    public NotificationsController(INotificationService notificationService, IAuthService authService, ApplicationDbContext dbContext)
    {
        _notificationService = notificationService;
        _authService = authService;
        _dbContext = dbContext;
    }

    [HttpGet("my")]
    public async Task<IActionResult> GetMyNotifications()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized();
        }

        var items = await _notificationService.GetForUserAsync(userId);
        return Ok(items);
    }

    [HttpGet("sent")]
    public async Task<IActionResult> GetMySentNotifications()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized();
        }

        var items = await _notificationService.GetSentByUserAsync(userId);
        return Ok(items);
    }

    [Authorize(Roles = "Admin")]
    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] int take = 100)
    {
        var items = await _notificationService.GetAdminErrorNotificationsAsync(take);
        return Ok(items);
    }

    [Authorize(Roles = "Admin,User")]
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateNotificationRequest request)
    {
        var senderUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var isAdmin = User.IsInRole("Admin");
        if (string.IsNullOrWhiteSpace(senderUserId))
        {
            return Unauthorized();
        }

        if (string.IsNullOrWhiteSpace(request.Title) || string.IsNullOrWhiteSpace(request.Message))
        {
            return BadRequest(new { message = "Title and message are required" });
        }

        if (!string.IsNullOrWhiteSpace(request.UserId))
        {
            if (!isAdmin && !string.Equals(request.UserId, senderUserId, StringComparison.Ordinal))
            {
                return Forbid();
            }

            var recipientInputs = request.Recipients?
                .Select(r => new NotificationRecipientInput(r.Name, r.PhoneNumber, r.Status, r.ErrorReason, r.GatewayMessageId, r.GatewayPayload));

            var item = await _notificationService.CreateForUserAsync(
                request.UserId,
                request.Title,
                request.Message,
                request.Type ?? "System",
                request.ReferenceId,
                senderUserId,
                request.DeliveryStatus ?? "Sent",
                request.ErrorDetails,
                request.RecipientsSummary,
                recipientInputs);

            return Ok(item);
        }

        var targetUserIds = request.UserIds?.Distinct().ToList() ?? new List<string>();

        if (targetUserIds.Count == 0)
        {
            if (isAdmin)
            {
                var allUsers = await _authService.GetAllUsersAsync();
                targetUserIds = allUsers
                    .Where(u => u.IsActive)
                    .Select(u => u.Id)
                    .ToList();
            }
            else
            {
                targetUserIds = [senderUserId];
            }
        }
        else if (!isAdmin && targetUserIds.Any(id => !string.Equals(id, senderUserId, StringComparison.Ordinal)))
        {
            return Forbid();
        }

        var bulkRecipientInputs = request.Recipients?
            .Select(r => new NotificationRecipientInput(r.Name, r.PhoneNumber, r.Status, r.ErrorReason, r.GatewayMessageId, r.GatewayPayload));

        var created = await _notificationService.CreateForUsersAsync(
            targetUserIds,
            request.Title,
            request.Message,
            request.Type ?? "System",
            request.ReferenceId,
            senderUserId,
            request.DeliveryStatus ?? "Sent",
            request.ErrorDetails,
            request.RecipientsSummary,
            bulkRecipientInputs);

        // Single-user send (self): return the notification object so the caller gets its ID.
        if (created.Count == 1) return Ok(created[0]);
        return Ok(new { created = created.Count });
    }

    [Authorize(Roles = "Admin,User,Guest")]
    [HttpPost("send-to-recipients")]
    public async Task<IActionResult> SendToRecipients([FromBody] SendToRecipientsRequest request)
    {
        var senderUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(senderUserId))
        {
            return Unauthorized();
        }

        if (request.RecipientIds == null || request.RecipientIds.Count == 0)
        {
            return BadRequest(new { message = "At least one recipient is required" });
        }

        if (string.IsNullOrWhiteSpace(request.Message))
        {
            return BadRequest(new { message = "Message is required" });
        }

        var client = await _dbContext.Clients.FirstOrDefaultAsync(c => c.UserId == senderUserId);
        if (client == null)
        {
            return NotFound(new { message = "Client profile not found for current user" });
        }

        var recipientIds = request.RecipientIds.Distinct().ToList();
        var recipients = await _dbContext.Recipients
            .Where(r => recipientIds.Contains(r.Id) && r.ClientId == client.Id)
            .ToListAsync();

        if (recipients.Count != recipientIds.Count)
        {
            return BadRequest(new { message = "One or more recipients do not belong to this user" });
        }

        foreach (var recipient in recipients)
        {
            await _notificationService.CreateForUserAsync(
                senderUserId,
                string.IsNullOrWhiteSpace(request.Title) ? $"SMS to {recipient.Name}" : request.Title,
                request.Message,
                "Sms",
                recipient.Id,
                senderUserId,
                request.SimulateError ? "Failed" : "Sent",
                request.SimulateError ? "Simulated send failure" : null);
        }

        return Ok(new
        {
            sent = recipients.Count,
            failed = request.SimulateError ? recipients.Count : 0
        });
    }

    [Authorize(Roles = "Admin,User")]
    [HttpPatch("{id}/delivery")]
    public async Task<IActionResult> UpdateDelivery(string id, [FromBody] UpdateDeliveryRequest request)
    {
        var callerUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var isAdmin = User.IsInRole("Admin");
        if (string.IsNullOrWhiteSpace(callerUserId)) return Unauthorized();

        var notification = await _dbContext.Notifications
            .Include(n => n.Recipients)
            .FirstOrDefaultAsync(n => n.Id == id);

        if (notification == null) return NotFound();
        if (!isAdmin && notification.CreatedByUserId != callerUserId) return Forbid();

        notification.DeliveryStatus = request.DeliveryStatus;
        if (request.ErrorDetails != null)
            notification.ErrorDetails = request.ErrorDetails;

        foreach (var r in request.Recipients ?? [])
        {
            var existing = notification.Recipients
                .FirstOrDefault(nr => nr.PhoneNumber == r.PhoneNumber);
            if (existing == null) continue;

            existing.Status = r.Status;
            if (r.GatewayMessageId != null) existing.GatewayMessageId = r.GatewayMessageId;
            if (r.ErrorReason != null) existing.ErrorReason = r.ErrorReason;
            if (r.GatewayPayload != null) existing.GatewayPayload = r.GatewayPayload;
            if (r.Status == "Delivered" && existing.DeliveredAt == null)
                existing.DeliveredAt = DateTime.UtcNow;
        }

        await _dbContext.SaveChangesAsync();
        return Ok(new { id = notification.Id, deliveryStatus = notification.DeliveryStatus });
    }

    [HttpPut("{id}/read")]
    public async Task<IActionResult> MarkAsRead(string id)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var isAdmin = User.IsInRole("Admin");

        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized();
        }

        var success = await _notificationService.MarkAsReadAsync(id, userId, isAdmin);
        return success ? Ok(new { message = "Marked as read" }) : NotFound();
    }

    [HttpPut("read-all")]
    public async Task<IActionResult> MarkAllAsRead()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized();
        }

        var count = await _notificationService.MarkAllAsReadAsync(userId);
        return Ok(new { updated = count });
    }

    [HttpPost("device-token")]
    public async Task<IActionResult> RegisterDeviceToken([FromBody] DeviceTokenRequest request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized();
        }

        if (string.IsNullOrWhiteSpace(request.Token))
        {
            return BadRequest(new { message = "Token is required" });
        }

        await _notificationService.RegisterDeviceTokenAsync(userId, request.Token, request.DeviceType ?? "Unknown");
        return Ok(new { message = "Device token registered" });
    }
}

public class CreateNotificationRequest
{
    public string? UserId { get; set; }
    public List<string>? UserIds { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string? Type { get; set; }
    public string? ReferenceId { get; set; }
    public string? DeliveryStatus { get; set; }
    public string? ErrorDetails { get; set; }
    public string? RecipientsSummary { get; set; }
    public List<NotificationRecipientRequest>? Recipients { get; set; }
}

public class NotificationRecipientRequest
{
    public string? Name { get; set; }
    public string PhoneNumber { get; set; } = string.Empty;
    public string Status { get; set; } = "Sent";
    public string? ErrorReason { get; set; }
    public string? GatewayMessageId { get; set; }
    public string? GatewayPayload { get; set; }
}

public class DeviceTokenRequest
{
    public string Token { get; set; } = string.Empty;
    public string? DeviceType { get; set; }
}

public class SendToRecipientsRequest
{
    public List<string> RecipientIds { get; set; } = new();
    public string? Title { get; set; }
    public string Message { get; set; } = string.Empty;
    public bool SimulateError { get; set; }
}

public class UpdateDeliveryRequest
{
    public string DeliveryStatus { get; set; } = "Sent";
    public string? ErrorDetails { get; set; }
    public List<UpdateRecipientDeliveryRequest>? Recipients { get; set; }
}

public class UpdateRecipientDeliveryRequest
{
    public string PhoneNumber { get; set; } = string.Empty;
    public string Status { get; set; } = "Sent";
    public string? GatewayMessageId { get; set; }
    public string? ErrorReason { get; set; }
    public string? GatewayPayload { get; set; }
}
