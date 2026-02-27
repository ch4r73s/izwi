using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using dotnet_api.Data;
using dotnet_api.Interfaces;
using dotnet_api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using SecurityClaim = System.Security.Claims.Claim;

namespace dotnet_api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class AuthController : ControllerBase
{
    private readonly IConfiguration _configuration;
    private readonly IAuthService _authService;
    private readonly ApplicationDbContext _dbContext;
    private readonly ILogger<AuthController> _logger;

    public AuthController(
        IConfiguration configuration,
        IAuthService authService,
        ApplicationDbContext dbContext,
        ILogger<AuthController> logger)
    {
        _configuration = configuration;
        _authService = authService;
        _dbContext = dbContext;
        _logger = logger;
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        try
        {
            var user = await _authService.ValidateUserAsync(request.Identifier, request.Password);

            if (user == null)
            {
                return Unauthorized(new { message = "Invalid credentials" });
            }

            var tokens = GenerateTokens(user);
            await _authService.UpdateLastLoginAsync(user.Id);

            return Ok(new
            {
                accessToken = tokens.AccessToken,
                refreshToken = tokens.RefreshToken,
                user = new
                {
                    id = user.Id,
                    username = user.Username,
                    email = user.Email,
                    displayName = user.DisplayName,
                    role = user.Role,
                    createdAt = user.CreatedAt,
                    lastLogin = DateTime.UtcNow,
                    isActive = user.IsActive
                }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Login failed for {Identifier}", request.Identifier);
            return StatusCode(500, new { message = "An error occurred during login" });
        }
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(request.Username) ||
                string.IsNullOrWhiteSpace(request.Email) ||
                string.IsNullOrWhiteSpace(request.DisplayName) ||
                string.IsNullOrWhiteSpace(request.Password))
            {
                return BadRequest(new { message = "Username, email, display name and password are required" });
            }

            if (await _authService.UserExistsAsync(request.Username, request.Email))
            {
                return BadRequest(new { message = "User already exists" });
            }

            var role = UserRoles.User;
            if (!string.IsNullOrWhiteSpace(request.Role))
            {
                if (!UserRoles.TryNormalize(request.Role, out role))
                {
                    return BadRequest(new { message = $"Invalid role. Allowed roles: {string.Join(", ", UserRoles.All)}" });
                }

                var isAdminCaller = User.IsInRole(UserRoles.Admin);
                if (!isAdminCaller && !string.Equals(role, UserRoles.User, StringComparison.Ordinal))
                {
                    return Forbid();
                }
            }

            var user = await _authService.CreateUserAsync(new User
            {
                Username = request.Username,
                Email = request.Email,
                DisplayName = request.DisplayName,
                Role = role,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
                CreatedAt = DateTime.UtcNow,
                IsActive = true
            });

            if (!string.Equals(user.Role, UserRoles.Admin, StringComparison.Ordinal))
            {
                var smsUsername = string.IsNullOrWhiteSpace(request.SmsUsername) ? user.Username : request.SmsUsername.Trim();
                var smsPassword = string.IsNullOrWhiteSpace(request.SmsPassword) ? request.Password : request.SmsPassword;

                var client = new Client
                {
                    UserId = user.Id,
                    Name = user.DisplayName,
                    Ssidn = string.IsNullOrWhiteSpace(request.Ssidn) ? $"SSIDN-{user.Username.ToUpperInvariant()}" : request.Ssidn.Trim(),
                    SmsCostPerMessage = 0.05m
                };
                await _dbContext.Clients.AddAsync(client);
                await _dbContext.SaveChangesAsync();

                var gateway = new SmsGateway
                {
                    Provider = "EBS",
                    Name = $"{user.DisplayName} Gateway",
                    IsActive = true
                };
                await _dbContext.SmsGateways.AddAsync(gateway);
                await _dbContext.SaveChangesAsync();

                await _dbContext.SmsGatewayCredentials.AddRangeAsync(
                    new SmsGatewayCredential
                    {
                        SmsGatewayId = gateway.Id,
                        Key = "username",
                        Value = smsUsername
                    },
                    new SmsGatewayCredential
                    {
                        SmsGatewayId = gateway.Id,
                        Key = "password",
                        Value = smsPassword
                    }
                );

                await _dbContext.ClientSmsGateways.AddAsync(new ClientSmsGateway
                {
                    ClientId = client.Id,
                    SmsGatewayId = gateway.Id
                });
                await _dbContext.SaveChangesAsync();
            }

            var tokens = GenerateTokens(user);

            return Ok(new
            {
                accessToken = tokens.AccessToken,
                refreshToken = tokens.RefreshToken,
                user = new
                {
                    id = user.Id,
                    username = user.Username,
                    email = user.Email,
                    displayName = user.DisplayName,
                    role = user.Role,
                    createdAt = user.CreatedAt
                }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Registration failed for {Username}", request.Username);
            return StatusCode(500, new { message = "An error occurred during registration" });
        }
    }

    [HttpPost("refresh")]
    public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest request)
    {
        try
        {
            var principal = GetPrincipalFromExpiredToken(request.RefreshToken);
            if (principal == null)
            {
                return Unauthorized(new { message = "Invalid refresh token" });
            }

            var userId = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new { message = "Invalid token claims" });
            }

            var user = await _authService.GetUserByIdAsync(userId);
            if (user == null)
            {
                return Unauthorized(new { message = "User not found" });
            }

            var tokens = GenerateTokens(user);
            return Ok(new { accessToken = tokens.AccessToken, refreshToken = tokens.RefreshToken });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Token refresh failed");
            return StatusCode(500, new { message = "An error occurred during token refresh" });
        }
    }

    [Authorize]
    [HttpPost("logout")]
    public async Task<IActionResult> Logout()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!string.IsNullOrEmpty(userId))
        {
            await _authService.LogoutUserAsync(userId);
        }

        return Ok(new { message = "Logged out successfully" });
    }

    [HttpPost("forgot-password")]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
    {
        try
        {
            await _authService.InitiatePasswordResetAsync(request.Identifier);
            return Ok(new { message = "If the user exists, a reset token has been generated" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Forgot password failed");
            return Ok(new { message = "If the user exists, a reset token has been generated" });
        }
    }

    [HttpPost("reset-password")]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
    {
        try
        {
            var success = await _authService.ResetPasswordAsync(request.Token, request.NewPassword);
            if (!success)
            {
                return BadRequest(new { message = "Invalid or expired reset token" });
            }

            return Ok(new { message = "Password reset successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Password reset failed");
            return StatusCode(500, new { message = "An error occurred during password reset" });
        }
    }

    private (string AccessToken, string RefreshToken) GenerateTokens(User user)
    {
        var jwtSettings = _configuration.GetSection("JwtSettings");
        var secretKey = jwtSettings["SecretKey"] ?? throw new InvalidOperationException("Missing JWT secret");

        var claims = new[]
        {
            new SecurityClaim(ClaimTypes.NameIdentifier, user.Id),
            new SecurityClaim(ClaimTypes.Name, user.DisplayName),
            new SecurityClaim(ClaimTypes.Email, user.Email),
            new SecurityClaim("username", user.Username),
            new SecurityClaim(ClaimTypes.Role, user.Role),
            new SecurityClaim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var accessToken = new JwtSecurityToken(
            issuer: jwtSettings["Issuer"],
            audience: jwtSettings["Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(15),
            signingCredentials: credentials
        );

        var refreshToken = new JwtSecurityToken(
            issuer: jwtSettings["Issuer"],
            audience: jwtSettings["Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddDays(7),
            signingCredentials: credentials
        );

        return (
            new JwtSecurityTokenHandler().WriteToken(accessToken),
            new JwtSecurityTokenHandler().WriteToken(refreshToken)
        );
    }

    private ClaimsPrincipal GetPrincipalFromExpiredToken(string token)
    {
        var jwtSettings = _configuration.GetSection("JwtSettings");
        var secretKey = jwtSettings["SecretKey"] ?? throw new InvalidOperationException("Missing JWT secret");

        var tokenValidationParameters = new TokenValidationParameters
        {
            ValidateAudience = true,
            ValidateIssuer = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtSettings["Issuer"],
            ValidAudience = jwtSettings["Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey)),
            ValidateLifetime = false
        };

        var tokenHandler = new JwtSecurityTokenHandler();
        var principal = tokenHandler.ValidateToken(token, tokenValidationParameters, out var securityToken);

        if (securityToken is not JwtSecurityToken jwtSecurityToken ||
            !jwtSecurityToken.Header.Alg.Equals(SecurityAlgorithms.HmacSha256, StringComparison.InvariantCultureIgnoreCase))
        {
            throw new SecurityTokenException("Invalid token");
        }

        return principal;
    }
}

public class LoginRequest
{
    public string Identifier { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

public class RegisterRequest
{
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string? Role { get; set; }
    public string? Ssidn { get; set; }
    public string? SmsUsername { get; set; }
    public string? SmsPassword { get; set; }
}

public class RefreshTokenRequest
{
    public string RefreshToken { get; set; } = string.Empty;
}

public class ForgotPasswordRequest
{
    public string Identifier { get; set; } = string.Empty;
}

public class ResetPasswordRequest
{
    public string Token { get; set; } = string.Empty;
    public string NewPassword { get; set; } = string.Empty;
}
