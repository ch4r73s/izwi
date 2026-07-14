namespace dotnet_api.Services;

public static class SmsBillingHelper
{
    public static string ResolveTemplate(string template, string? recipientName)
    {
        var name = recipientName ?? "";

        return template
            .Replace("[Name]",      name, StringComparison.OrdinalIgnoreCase)
            .Replace("[FirstName]", name, StringComparison.OrdinalIgnoreCase)
            .Replace("{Name}",      name, StringComparison.OrdinalIgnoreCase)
            .Replace("{FirstName}", name, StringComparison.OrdinalIgnoreCase);
    }

    public static int ComputeUnits(string resolvedMessage) =>
        (int)Math.Ceiling(resolvedMessage.Length / 160.0);
}
