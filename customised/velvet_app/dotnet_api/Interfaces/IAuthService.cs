using dotnet_api.Models;

namespace dotnet_api.Interfaces;

public interface IAuthService
{
    Task<User?> ValidateUserAsync(string identifier, string password);
    Task<User> CreateUserAsync(User user);
    Task<bool> UserExistsAsync(string username, string email);
    Task<User?> GetUserByIdAsync(string userId);
    Task<User?> GetUserByUsernameOrEmailAsync(string identifier);
    Task<IReadOnlyList<User>> GetAllUsersAsync();
    Task UpdateLastLoginAsync(string userId);
    Task LogoutUserAsync(string userId);
    Task<bool> InitiatePasswordResetAsync(string identifier);
    Task<bool> ResetPasswordAsync(string token, string newPassword);
    Task<User> UpdateUserAsync(User user);
}