using dotnet_api.Data;
using dotnet_api.Interfaces;
using dotnet_api.Models;
using Microsoft.EntityFrameworkCore;

namespace dotnet_api.Services;

public class AuthService : IAuthService
{
    private readonly ApplicationDbContext _context;

    public AuthService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<User?> ValidateUserAsync(string identifier, string password)
    {
        var user = await GetUserByUsernameOrEmailAsync(identifier);
        if (user == null || !user.IsActive)
        {
            return null;
        }

        return BCrypt.Net.BCrypt.Verify(password, user.PasswordHash) ? user : null;
    }

    public async Task<User> CreateUserAsync(User user)
    {
        await _context.Users.AddAsync(user);
        await _context.SaveChangesAsync();
        return user;
    }

    public Task<bool> UserExistsAsync(string username, string email)
    {
        return _context.Users.AnyAsync(u => u.Username == username || u.Email == email);
    }

    public Task<User?> GetUserByIdAsync(string userId)
    {
        return _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
    }

    public Task<User?> GetUserByUsernameOrEmailAsync(string identifier)
    {
        return _context.Users.FirstOrDefaultAsync(u => u.Username == identifier || u.Email == identifier);
    }

    public async Task<IReadOnlyList<User>> GetAllUsersAsync()
    {
        return await _context.Users
            .OrderBy(u => u.Username)
            .ToListAsync();
    }

    public async Task UpdateLastLoginAsync(string userId)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null)
        {
            return;
        }

        user.LastLogin = DateTime.UtcNow;
        await _context.SaveChangesAsync();
    }

    public Task LogoutUserAsync(string userId)
    {
        return Task.CompletedTask;
    }

    public async Task<bool> InitiatePasswordResetAsync(string identifier)
    {
        var user = await GetUserByUsernameOrEmailAsync(identifier);
        if (user == null)
        {
            return false;
        }

        var token = new PasswordResetToken
        {
            UserId = user.Id,
            Token = Guid.NewGuid().ToString("N"),
            ExpiresAt = DateTime.UtcNow.AddHours(24)
        };

        await _context.PasswordResetTokens.AddAsync(token);
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> ResetPasswordAsync(string token, string newPassword)
    {
        var resetToken = await _context.PasswordResetTokens
            .Include(rt => rt.User)
            .FirstOrDefaultAsync(rt => rt.Token == token && !rt.IsUsed);

        if (resetToken?.User == null || !resetToken.IsValid)
        {
            return false;
        }

        resetToken.User.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
        resetToken.IsUsed = true;

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<User> UpdateUserAsync(User user)
    {
        _context.Users.Update(user);
        await _context.SaveChangesAsync();
        return user;
    }
}