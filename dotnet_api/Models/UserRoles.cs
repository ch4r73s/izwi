namespace dotnet_api.Models;

public static class UserRoles
{
    public const string Admin = "Admin";
    public const string User = "User";
    public const string Guest = "Guest";

    public static readonly string[] All = [Admin, User, Guest];

    public static bool TryNormalize(string? input, out string normalizedRole)
    {
        normalizedRole = string.Empty;
        if (string.IsNullOrWhiteSpace(input))
        {
            return false;
        }

        normalizedRole = input.Trim().ToLowerInvariant() switch
        {
            "admin" => Admin,
            "user" => User,
            "guest" => Guest,
            _ => string.Empty
        };

        return !string.IsNullOrEmpty(normalizedRole);
    }
}
