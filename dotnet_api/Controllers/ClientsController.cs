using System.Security.Claims;
using dotnet_api.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace dotnet_api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize(Roles = "Admin,User,Guest")]
public class ClientsController : ControllerBase
{
    private readonly ApplicationDbContext _dbContext;

    public ClientsController(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    [HttpGet("my")]
    public async Task<IActionResult> GetMyClient()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized();
        }

        var client = await _dbContext.Clients.FirstOrDefaultAsync(c => c.UserId == userId);
        return client == null ? NotFound(new { message = "Client profile not found" }) : Ok(client);
    }

    [HttpPut("my")]
    public async Task<IActionResult> UpdateMyClient([FromBody] UpdateClientRequest request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized();
        }

        var client = await _dbContext.Clients.FirstOrDefaultAsync(c => c.UserId == userId);
        if (client == null)
        {
            return NotFound(new { message = "Client profile not found" });
        }

        if (!string.IsNullOrWhiteSpace(request.Name))
        {
            client.Name = request.Name.Trim();
        }

        if (!string.IsNullOrWhiteSpace(request.Ssidn))
        {
            client.Ssidn = request.Ssidn.Trim();
        }

        if (request.SmsCostPerMessage is > 0 && User.IsInRole("Admin"))
        {
            client.SmsCostPerMessage = request.SmsCostPerMessage.Value;
        }

        await _dbContext.SaveChangesAsync();
        return Ok(client);
    }

    [Authorize(Roles = "Admin")]
    [HttpGet("user/{userId}")]
    public async Task<IActionResult> GetByUser(string userId)
    {
        var client = await _dbContext.Clients.FirstOrDefaultAsync(c => c.UserId == userId);
        return client == null ? NotFound(new { message = "Client profile not found" }) : Ok(client);
    }
}

public class UpdateClientRequest
{
    public string? Name { get; set; }
    public string? Ssidn { get; set; }
    public decimal? SmsCostPerMessage { get; set; }
}
