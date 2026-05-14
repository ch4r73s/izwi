using System.Security.Claims;
using dotnet_api.Data;
using dotnet_api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace dotnet_api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class TemplatesController : ControllerBase
{
    private readonly ApplicationDbContext _db;

    public TemplatesController(ApplicationDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var client = await GetCallerClient();
        if (client == null) return NotFound(new { message = "Client profile not found." });

        var templates = await _db.NotificationTemplates
            .Where(t => t.ClientId == client.Id)
            .OrderByDescending(t => t.CreatedAt)
            .Select(t => new { t.Id, t.Name, t.Title, t.Body, t.CreatedAt })
            .ToListAsync();

        return Ok(templates);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateTemplateRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Name) || string.IsNullOrWhiteSpace(request.Body))
            return BadRequest(new { message = "Name and body are required." });

        var client = await GetCallerClient();
        if (client == null) return NotFound(new { message = "Client profile not found." });

        var template = new NotificationTemplate
        {
            ClientId = client.Id,
            Name = request.Name.Trim(),
            Title = request.Title?.Trim() ?? string.Empty,
            Body = request.Body.Trim(),
        };

        _db.NotificationTemplates.Add(template);
        await _db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetAll), new { id = template.Id }, new
        {
            template.Id,
            template.Name,
            template.Title,
            template.Body,
            template.CreatedAt,
        });
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(string id)
    {
        var client = await GetCallerClient();
        if (client == null) return NotFound(new { message = "Client profile not found." });

        var template = await _db.NotificationTemplates
            .FirstOrDefaultAsync(t => t.Id == id && t.ClientId == client.Id);

        if (template == null) return NotFound(new { message = "Template not found." });

        _db.NotificationTemplates.Remove(template);
        await _db.SaveChangesAsync();

        return NoContent();
    }

    private async Task<Client?> GetCallerClient()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(userId)) return null;
        return await _db.Clients.FirstOrDefaultAsync(c => c.UserId == userId);
    }
}

public record CreateTemplateRequest(string Name, string? Title, string Body);
