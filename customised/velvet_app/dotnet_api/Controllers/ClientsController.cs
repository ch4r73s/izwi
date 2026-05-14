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
            return Unauthorized();

        var client = await _dbContext.Clients
            .Include(c => c.Payments)
                .ThenInclude(p => p.Package)
            .FirstOrDefaultAsync(c => c.UserId == userId);

        if (client == null)
            return NotFound(new { message = "Client profile not found" });

        return Ok(BuildClientResponse(client));
    }

    [HttpPost("my/record-sms")]
    public async Task<IActionResult> RecordSmsSent([FromBody] RecordSmsRequest request)
    {
        if (request.Count <= 0)
            return BadRequest(new { message = "Count must be greater than zero." });

        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(userId))
            return Unauthorized();

        var client = await _dbContext.Clients
            .Include(c => c.Payments)
            .FirstOrDefaultAsync(c => c.UserId == userId);

        if (client == null)
            return NotFound(new { message = "Client profile not found" });

        // Deduct from oldest payments with remaining SMS first (FIFO)
        var activePayments = client.Payments
            .Where(p => p.SmsConsumed < p.SmsAllocated)
            .OrderBy(p => p.PaidAt)
            .ToList();

        var remaining = request.Count;
        foreach (var payment in activePayments)
        {
            if (remaining <= 0) break;
            var available = payment.SmsAllocated - payment.SmsConsumed;
            var deduct = Math.Min(remaining, available);
            payment.SmsConsumed += deduct;
            remaining -= deduct;
        }

        await _dbContext.SaveChangesAsync();

        var totalAllocated = client.Payments.Sum(p => p.SmsAllocated);
        var totalConsumed = client.Payments.Sum(p => p.SmsConsumed);

        return Ok(new
        {
            recorded = request.Count - remaining,
            totalAllocated,
            totalConsumed,
            totalRemaining = totalAllocated - totalConsumed,
        });
    }

    [HttpPut("my")]
    public async Task<IActionResult> UpdateMyClient([FromBody] UpdateClientRequest request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(userId))
            return Unauthorized();

        var client = await _dbContext.Clients.FirstOrDefaultAsync(c => c.UserId == userId);
        if (client == null)
            return NotFound(new { message = "Client profile not found" });

        if (!string.IsNullOrWhiteSpace(request.Name))
            client.Name = request.Name.Trim();

        if (!string.IsNullOrWhiteSpace(request.Ssidn))
            client.Ssidn = request.Ssidn.Trim();

        if (request.SmsCostPerMessage is > 0 && User.IsInRole("Admin"))
            client.SmsCostPerMessage = request.SmsCostPerMessage.Value;

        await _dbContext.SaveChangesAsync();
        return Ok(client);
    }

    [Authorize(Roles = "Admin")]
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var clients = await _dbContext.Clients
            .Include(c => c.User)
            .Include(c => c.Payments)
                .ThenInclude(p => p.Package)
            .OrderBy(c => c.Name)
            .ToListAsync();

        return Ok(clients.Select(c =>
        {
            var response = BuildClientResponse(c);
            return new
            {
                response.id,
                response.name,
                response.ssidn,
                response.smsCostPerMessage,
                response.createdAt,
                response.subscription,
                user = c.User == null ? null : new
                {
                    c.User.Id,
                    c.User.Username,
                    c.User.Email,
                    c.User.Role,
                    c.User.IsActive
                }
            };
        }));
    }

    [Authorize(Roles = "Admin")]
    [HttpGet("user/{userId}")]
    public async Task<IActionResult> GetByUser(string userId)
    {
        var client = await _dbContext.Clients
            .Include(c => c.Payments)
                .ThenInclude(p => p.Package)
            .FirstOrDefaultAsync(c => c.UserId == userId);

        return client == null
            ? NotFound(new { message = "Client profile not found" })
            : Ok(BuildClientResponse(client));
    }

    [Authorize(Roles = "Admin")]
    [HttpGet("packages")]
    public async Task<IActionResult> GetPackages()
    {
        var packages = await _dbContext.SmsPackages
            .OrderBy(p => p.Id)
            .Select(p => new
            {
                p.Id,
                p.Name,
                p.Description,
                p.MaxSmsLimit,
                p.PricePerSms,
            })
            .ToListAsync();

        return Ok(packages);
    }

    private static dynamic BuildClientResponse(dotnet_api.Models.Client c)
    {
        var payments = c.Payments.OrderBy(p => p.PaidAt).ToList();
        var totalAllocated = payments.Sum(p => p.SmsAllocated);
        var totalConsumed = payments.Sum(p => p.SmsConsumed);
        var currentPackage = payments.OrderByDescending(p => p.PaidAt).FirstOrDefault()?.Package;

        return new
        {
            id = c.Id,
            name = c.Name,
            ssidn = c.Ssidn,
            smsCostPerMessage = c.SmsCostPerMessage,
            createdAt = c.CreatedAt,
            subscription = new
            {
                currentPackage = currentPackage == null ? null : new
                {
                    currentPackage.Id,
                    currentPackage.Name,
                    currentPackage.Description,
                    currentPackage.MaxSmsLimit,
                    currentPackage.PricePerSms,
                },
                totalAllocated,
                totalConsumed,
                totalRemaining = totalAllocated - totalConsumed,
                payments = payments.Select(p => new
                {
                    p.Id,
                    p.AmountPaid,
                    p.SmsAllocated,
                    p.SmsConsumed,
                    smsRemaining = p.SmsAllocated - p.SmsConsumed,
                    p.PaidAt,
                    p.Notes,
                    package = p.Package == null ? null : new
                    {
                        p.Package.Id,
                        p.Package.Name,
                        p.Package.PricePerSms,
                    },
                }),
            },
        };
    }
}

public class UpdateClientRequest
{
    public string? Name { get; set; }
    public string? Ssidn { get; set; }
    public decimal? SmsCostPerMessage { get; set; }
}

public class RecordSmsRequest
{
    public int Count { get; set; }
}
