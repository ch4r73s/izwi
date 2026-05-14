using dotnet_api.Interfaces;
using dotnet_api.Models;
using dotnet_api.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace dotnet_api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class UsersController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ApplicationDbContext _dbContext;

    public UsersController(IAuthService authService, ApplicationDbContext dbContext)
    {
        _authService = authService;
        _dbContext = dbContext;
    }

    [Authorize(Roles = "Admin")]
    [HttpGet("roles")]
    public IActionResult GetRoles()
    {
        return Ok(UserRoles.All);
    }

    [Authorize(Roles = "Admin")]
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var users = await _authService.GetAllUsersAsync();

        var response = users.Select(u => new
        {
            u.Id,
            u.Username,
            u.Email,
            u.DisplayName,
            u.Role,
            u.IsActive,
            u.CreatedAt,
            u.LastLogin
        });

        return Ok(response);
    }

    [Authorize(Roles = "Admin")]
    [HttpPost("addUser")]
    public async Task<IActionResult> AddUser([FromBody] AddUserRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Name))
        {
            return BadRequest(new { message = "Name and email are required" });
        }

        if (string.IsNullOrWhiteSpace(request.Ssidn))
        {
            return BadRequest(new { message = "ssidn is required" });
        }

        if (string.IsNullOrWhiteSpace(request.Password))
        {
            return BadRequest(new { message = "password is required" });
        }

        if (string.IsNullOrWhiteSpace(request.SmsUsername) || string.IsNullOrWhiteSpace(request.SmsPassword))
        {
            return BadRequest(new { message = "smsUsername and smsPassword are required" });
        }

        var username = string.IsNullOrWhiteSpace(request.Username)
            ? request.Email.Split('@')[0]
            : request.Username;

        if (await _authService.UserExistsAsync(username, request.Email))
        {
            return BadRequest(new { message = "User already exists" });
        }

        var normalizedSsidn = request.Ssidn.Trim();
        var ssidnExists = await _dbContext.Clients.AnyAsync(c => c.Ssidn == normalizedSsidn);
        if (ssidnExists)
        {
            return BadRequest(new { message = "Client with this ssidn already exists" });
        }

        var role = UserRoles.User;
        if (!string.IsNullOrWhiteSpace(request.Role))
        {
            if (!UserRoles.TryNormalize(request.Role, out role))
            {
                return BadRequest(new { message = $"Invalid role. Allowed roles: {string.Join(", ", UserRoles.All)}" });
            }
        }

        var generatedPassword = request.Password;

        var user = await _authService.CreateUserAsync(new User
        {
            Username = username,
            Email = request.Email,
            DisplayName = request.Name,
            Role = role,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(generatedPassword),
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        });

        var smsCostPerMessage = request.SmsCostPerMessage is > 0 ? request.SmsCostPerMessage.Value : 0.05m;

        await _dbContext.Clients.AddAsync(new Client
        {
            UserId = user.Id,
            Name = request.Name,
            Ssidn = request.Ssidn,
            SmsCostPerMessage = smsCostPerMessage
        });
        await _dbContext.SaveChangesAsync();

        var client = await _dbContext.Clients.FirstAsync(c => c.UserId == user.Id);
        var gateway = new SmsGateway
        {
            Provider = "EBS",
            Name = $"{request.Name} Gateway",
            IsActive = true
        };
        await _dbContext.SmsGateways.AddAsync(gateway);
        await _dbContext.SaveChangesAsync();

        await _dbContext.SmsGatewayCredentials.AddRangeAsync(
            new SmsGatewayCredential
            {
                SmsGatewayId = gateway.Id,
                Key = "username",
                Value = request.SmsUsername.Trim()
            },
            new SmsGatewayCredential
            {
                SmsGatewayId = gateway.Id,
                Key = "password",
                Value = request.SmsPassword
            }
        );

        await _dbContext.ClientSmsGateways.AddAsync(new ClientSmsGateway
        {
            ClientId = client.Id,
            SmsGatewayId = gateway.Id
        });
        await _dbContext.SaveChangesAsync();

        return Ok(new
        {
            message = "User added successfully",
            user = new
            {
                user.Id,
                user.Username,
                user.Email,
                user.DisplayName,
                user.Role
            },
            client = new
            {
                userId = user.Id,
                ssidn = request.Ssidn,
                smsGatewayId = gateway.Id,
                smsCostPerMessage
            },
            temporaryPassword = generatedPassword
        });
    }

    [AllowAnonymous]
    [HttpPost("registerUser")]
    public async Task<IActionResult> RegisterUser([FromBody] RegisterUserRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Identifier) || string.IsNullOrWhiteSpace(request.Password))
        {
            return BadRequest(new { message = "Identifier and password are required" });
        }

        var user = await _authService.GetUserByUsernameOrEmailAsync(request.Identifier);
        if (user == null)
        {
            return NotFound(new { message = "User not found" });
        }

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);
        await _authService.UpdateUserAsync(user);

        return Ok(new { message = "Password set successfully" });
    }

    [Authorize(Roles = "Admin")]
    [HttpPut("{id}/role")]
    public async Task<IActionResult> UpdateRole(string id, [FromBody] UpdateUserRoleRequest request)
    {
        if (!UserRoles.TryNormalize(request.Role, out var normalizedRole))
        {
            return BadRequest(new { message = $"Invalid role. Allowed roles: {string.Join(", ", UserRoles.All)}" });
        }

        var user = await _authService.GetUserByIdAsync(id);
        if (user == null)
        {
            return NotFound(new { message = "User not found" });
        }

        var callerUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.Equals(callerUserId, user.Id, StringComparison.Ordinal) &&
            !string.Equals(normalizedRole, UserRoles.Admin, StringComparison.Ordinal))
        {
            return BadRequest(new { message = "Admin users cannot remove their own admin role" });
        }

        user.Role = normalizedRole;
        await _authService.UpdateUserAsync(user);

        return Ok(new
        {
            message = "User role updated successfully",
            user = new
            {
                user.Id,
                user.Username,
                user.Email,
                user.DisplayName,
                user.Role
            }
        });
    }
}

public class AddUserRequest
{
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Username { get; set; }
    public string? Role { get; set; }
    public string? Password { get; set; }
    public string Ssidn { get; set; } = string.Empty;
    public string SmsUsername { get; set; } = string.Empty;
    public string SmsPassword { get; set; } = string.Empty;
    public decimal? SmsCostPerMessage { get; set; }
}

public class RegisterUserRequest
{
    public string Identifier { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

public class UpdateUserRoleRequest
{
    public string Role { get; set; } = string.Empty;
}
