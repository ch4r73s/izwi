using System.Security.Claims;
using dotnet_api.Data;
using dotnet_api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace dotnet_api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize(Roles = "Admin,User,Guest")]
public class RecipientsController : ControllerBase
{
    private readonly ApplicationDbContext _dbContext;

    public RecipientsController(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    [HttpGet("my")]
    public async Task<IActionResult> GetMyRecipients()
    {
        var client = await GetCurrentClientAsync();
        if (client == null)
        {
            return NotFound(new { message = "Client profile not found for current user" });
        }

        var recipients = await _dbContext.Recipients
            .Where(r => r.ClientId == client.Id)
            .OrderBy(r => r.Name)
            .ToListAsync();

        return Ok(recipients);
    }

    [HttpPost]
    public async Task<IActionResult> AddRecipient([FromBody] CreateRecipientRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Name) || string.IsNullOrWhiteSpace(request.PhoneNumber))
        {
            return BadRequest(new { message = "Name and phoneNumber are required" });
        }

        var client = await GetCurrentClientAsync();
        if (client == null)
        {
            return NotFound(new { message = "Client profile not found for current user" });
        }

        var recipient = new Recipient
        {
            ClientId = client.Id,
            Name = request.Name.Trim(),
            PhoneNumber = request.PhoneNumber.Trim(),
            Email = request.Email?.Trim(),
            IsActive = true
        };

        await _dbContext.Recipients.AddAsync(recipient);
        await _dbContext.SaveChangesAsync();

        return Ok(recipient);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteRecipient(string id)
    {
        var client = await GetCurrentClientAsync();
        if (client == null)
        {
            return NotFound(new { message = "Client profile not found for current user" });
        }

        var recipient = await _dbContext.Recipients
            .FirstOrDefaultAsync(r => r.Id == id && r.ClientId == client.Id);

        if (recipient == null)
        {
            return NotFound(new { message = "Recipient not found" });
        }

        _dbContext.Recipients.Remove(recipient);
        await _dbContext.SaveChangesAsync();

        return Ok(new { message = "Recipient deleted successfully" });
    }

    private async Task<Client?> GetCurrentClientAsync()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(userId))
        {
            return null;
        }

        return await _dbContext.Clients.FirstOrDefaultAsync(c => c.UserId == userId);
    }
}

public class CreateRecipientRequest
{
    public string Name { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string? Email { get; set; }
}
