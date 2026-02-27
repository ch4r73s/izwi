using System.Security.Claims;
using dotnet_api.Data;
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
            .OrderBy(n => n.CreatedAt)
            .Select(n => new
            {
                n.Id,
                n.Title,
                n.Message,
                n.Type,
                n.DeliveryStatus,
                n.CreatedAt
            })
            .ToListAsync();

        var totalMessages = notifications.Count;
        var totalCost = totalMessages * client.SmsCostPerMessage;

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
                costPerSms = client.SmsCostPerMessage,
                totalCost
            },
            items = notifications
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

        var totalCost = sentCount * client.SmsCostPerMessage;

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
                costPerSms = client.SmsCostPerMessage,
                totalCost
            }
        };
    }
}
