using System.Security.Claims;
using dotnet_api.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace dotnet_api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize(Roles = "Admin,User,Guest")]
public class MessageGatewayApiController : ControllerBase
{
    private readonly ApplicationDbContext _dbContext;

    public MessageGatewayApiController(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    [HttpGet("credentials")]
    public async Task<IActionResult> GetCredentials([FromQuery] string? userId = null)
    {
        var callerUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(callerUserId))
        {
            return Unauthorized();
        }

        var targetUserId = callerUserId;
        if (User.IsInRole("Admin") && !string.IsNullOrWhiteSpace(userId))
        {
            targetUserId = userId;
        }

        var client = await _dbContext.Clients.FirstOrDefaultAsync(c => c.UserId == targetUserId);
        if (client == null)
        {
            return NotFound(new { message = "Client profile not found for current user" });
        }

        var link = await _dbContext.ClientSmsGateways
            .Include(csg => csg.SmsGateway)
            .FirstOrDefaultAsync(csg => csg.ClientId == client.Id);
        if (link == null)
        {
            return NotFound(new { message = "No SMS gateway mapped to this client" });
        }

        var credentials = await _dbContext.SmsGatewayCredentials
            .Where(c => c.SmsGatewayId == link.SmsGatewayId)
            .ToListAsync();

        var provider    = link.SmsGateway.Provider;
        var smsEndpoint = credentials.FirstOrDefault(c => c.Key == "endpoint")?.Value;
        var smsUsername = credentials.FirstOrDefault(c => c.Key == "username")?.Value;
        var smsPassword = credentials.FirstOrDefault(c => c.Key == "password")?.Value;
        var apiKey      = credentials.FirstOrDefault(c => c.Key == "api_key")?.Value;
        var senderId    = credentials.FirstOrDefault(c => c.Key == "sender_id")?.Value;

        if (string.IsNullOrWhiteSpace(smsEndpoint))
            return NotFound(new { message = "SMS gateway endpoint is not configured." });

        return Ok(new
        {
            provider,
            smsEndpoint,
            smsUsername,
            smsPassword,
            apiKey,
            senderId,
        });
    }
}
