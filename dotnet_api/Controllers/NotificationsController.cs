using System.Security.Claims;
using dotnet_api.Data;
using dotnet_api.Interfaces;
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

            var item = await _notificationService.CreateForUserAsync(
                request.UserId,
                request.Title,
                request.Message,
                request.Type ?? "System",
                request.ReferenceId,
                senderUserId,
                request.DeliveryStatus ?? "Sent",
                request.ErrorDetails);

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

        var count = await _notificationService.CreateForUsersAsync(
            targetUserIds,
            request.Title,
            request.Message,
            request.Type ?? "System",
            request.ReferenceId,
            senderUserId,
            request.DeliveryStatus ?? "Sent",
            request.ErrorDetails);

        return Ok(new { created = count });
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
