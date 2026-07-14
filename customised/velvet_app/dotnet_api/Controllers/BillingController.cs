using System.Security.Claims;
using dotnet_api.Data;
using dotnet_api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace dotnet_api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize(Roles = "Admin,User,Guest")]
public class BillingController : ControllerBase
{
    private readonly ApplicationDbContext _dbContext;

    public BillingController(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    [HttpGet("my-summary")]
    public async Task<IActionResult> GetMySummary()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized();
        }

        var summary = await BuildSummaryAsync(userId);
        if (summary == null)
        {
            return NotFound(new { message = "Client profile not found for current user" });
        }

        return Ok(summary);
    }

    [Authorize(Roles = "Admin")]
    [HttpGet("user/{userId}/summary")]
    public async Task<IActionResult> GetUserSummary(string userId)
    {
        var summary = await BuildSummaryAsync(userId);
        if (summary == null)
        {
            return NotFound(new { message = "Client profile not found for selected user" });
        }

        return Ok(summary);
    }

    [HttpGet("my-invoice")]
    public async Task<IActionResult> GetMyInvoice([FromQuery] DateTime? from = null, [FromQuery] DateTime? to = null)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized();
        }

        var client = await _dbContext.Clients.FirstOrDefaultAsync(c => c.UserId == userId);
        if (client == null)
        {
            return NotFound(new { message = "Client profile not found for current user" });
        }

        var startDate = from ?? DateTime.UtcNow.AddMonths(-1);
        var endDate = to ?? DateTime.UtcNow;

        var notifications = await _dbContext.Notifications
            .Where(n => n.CreatedByUserId == userId &&
                        n.CreatedAt >= startDate &&
                        n.CreatedAt <= endDate &&
                        n.Type != "System")
            .Include(n => n.Recipients)
            .OrderBy(n => n.CreatedAt)
            .ToListAsync();

        var items = notifications.Select(n =>
        {
            var smsUnits = n.Recipients
                .Where(r => r.Status is "Sent" or "Delivered")
                .Sum(r => SmsBillingHelper.ComputeUnits(SmsBillingHelper.ResolveTemplate(n.Message, r.Name)));

            return new
            {
                n.Id,
                n.Title,
                n.Message,
                n.Type,
                n.DeliveryStatus,
                n.CreatedAt,
                smsUnits,
                cost = smsUnits * client.SmsCostPerMessage
            };
        }).ToList();

        var totalMessages = notifications.Count;
        var totalSmsUnits = items.Sum(i => i.smsUnits);
        var totalCost = totalSmsUnits * client.SmsCostPerMessage;

        var invoice = new
        {
            invoiceNumber = $"INV-{DateTime.UtcNow:yyyyMMddHHmmss}-{userId[..8]}",
            generatedAt = DateTime.UtcNow,
            period = new { from = startDate, to = endDate },
            client = new
            {
                client.Id,
                client.Name,
                client.Ssidn,
                client.SmsCostPerMessage
            },
            totals = new
            {
                totalMessages,
                totalSmsUnits,
                costPerSms = client.SmsCostPerMessage,
                totalCost
            },
            items
        };

        return Ok(invoice);
    }

    private async Task<object?> BuildSummaryAsync(string userId)
    {
        var client = await _dbContext.Clients.FirstOrDefaultAsync(c => c.UserId == userId);
        if (client == null)
        {
            return null;
        }

        var sentCount = await _dbContext.Notifications
            .CountAsync(n => n.CreatedByUserId == userId && n.Type != "System");

        var failedCount = await _dbContext.Notifications
            .CountAsync(n => n.CreatedByUserId == userId && (n.DeliveryStatus == "Failed" || n.Type == "Error"));

        var notifications = await _dbContext.Notifications
            .Where(n => n.CreatedByUserId == userId && n.Type != "System")
            .Include(n => n.Recipients)
            .ToListAsync();

        var totalSmsUnits = notifications.Sum(n => n.Recipients
            .Where(r => r.Status is "Sent" or "Delivered")
            .Sum(r => SmsBillingHelper.ComputeUnits(SmsBillingHelper.ResolveTemplate(n.Message, r.Name))));

        var totalCost = totalSmsUnits * client.SmsCostPerMessage;

        return new
        {
            client = new
            {
                client.Id,
                client.Name,
                client.Ssidn
            },
            billing = new
            {
                totalMessages = sentCount,
                failedMessages = failedCount,
                totalSmsUnits,
                costPerSms = client.SmsCostPerMessage,
                totalCost
            }
        };
    }
}
