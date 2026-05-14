using System.Net.Http.Headers;
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
    private readonly IHttpClientFactory _httpClientFactory;

    public MessageGatewayApiController(ApplicationDbContext dbContext, IHttpClientFactory httpClientFactory)
    {
        _dbContext = dbContext;
        _httpClientFactory = httpClientFactory;
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

        var provider        = link.SmsGateway.Provider;
        var smsEndpoint     = credentials.FirstOrDefault(c => c.Key == "endpoint")?.Value;
        var smsUsername     = credentials.FirstOrDefault(c => c.Key == "username")?.Value;
        var smsPassword     = credentials.FirstOrDefault(c => c.Key == "password")?.Value;
        var apiKey          = credentials.FirstOrDefault(c => c.Key == "api_key")?.Value;
        var senderId        = credentials.FirstOrDefault(c => c.Key == "sender_id")?.Value;
        var statusEndpoint  = credentials.FirstOrDefault(c => c.Key == "status_endpoint")?.Value;

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
            statusEndpoint,
        });
    }

    [HttpGet("message-status/{messageId}")]
    public async Task<IActionResult> GetMessageStatus(string messageId)
    {
        var callerUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(callerUserId)) return Unauthorized();

        var client = await _dbContext.Clients.FirstOrDefaultAsync(c => c.UserId == callerUserId);
        if (client == null) return NotFound(new { message = "Client profile not found" });

        var link = await _dbContext.ClientSmsGateways
            .Include(csg => csg.SmsGateway)
            .FirstOrDefaultAsync(csg => csg.ClientId == client.Id);
        if (link == null) return NotFound(new { message = "No SMS gateway configured" });

        var credentials = await _dbContext.SmsGatewayCredentials
            .Where(c => c.SmsGatewayId == link.SmsGatewayId)
            .ToListAsync();

        var statusEndpoint = credentials.FirstOrDefault(c => c.Key == "status_endpoint")?.Value;
        var apiKey         = credentials.FirstOrDefault(c => c.Key == "api_key")?.Value;

        if (string.IsNullOrWhiteSpace(statusEndpoint))
            return NotFound(new { message = "Status endpoint not configured for this gateway" });

        if (string.IsNullOrWhiteSpace(apiKey))
            return StatusCode(500, new { message = "API key not configured" });

        var httpClient = _httpClientFactory.CreateClient();
        httpClient.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", apiKey);

        var url = $"{statusEndpoint.TrimEnd('/')}/{messageId}";
        var response = await httpClient.GetAsync(url);
        var body = await response.Content.ReadAsStringAsync();

        return StatusCode((int)response.StatusCode, body);
    }
}
