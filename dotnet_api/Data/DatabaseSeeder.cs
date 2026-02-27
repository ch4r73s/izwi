using dotnet_api.Models;

namespace dotnet_api.Data;

public static class DatabaseSeeder
{
    public static void SeedDatabase(ApplicationDbContext context)
    {
        var adminUser = EnsureUser(
            context,
            username: "admin@izwi.co.zw",
            email: "admin@izwi.co.zw",
            displayName: "Izwi Administrator",
            role: UserRoles.Admin,
            password: "Test123!"
        );

        var standardUser = EnsureUser(
            context,
            username: "user@izwi.co.zw",
            email: "user@izwi.co.zw",
            displayName: "Izwi Standard User",
            role: UserRoles.User,
            password: "Test123!"
        );

        EnsureClient(
            context,
            standardUser,
            "SSIDN-USER-001",
            smsUsername: "user@izwi.co.zw",
            smsPassword: "Test123!",
            smsCostPerMessage: 0.05m
        );

        var userClient = context.Clients.First(c => c.UserId == standardUser.Id);
        EnsureRecipientsForUser(context, userClient.Id);

        EnsureWelcomeNotification(
            context,
            userId: adminUser.Id,
            title: "Welcome to IZWI",
            message: "Your admin account is ready.",
            createdByUserId: adminUser.Id
        );

        EnsureWelcomeNotification(
            context,
            userId: standardUser.Id,
            title: "Welcome",
            message: "You can now create and send notifications.",
            createdByUserId: adminUser.Id
        );
    }

    private static User EnsureUser(
        ApplicationDbContext context,
        string username,
        string email,
        string displayName,
        string role,
        string password)
    {
        var existing = context.Users.FirstOrDefault(u => u.Email == email || u.Username == username);
        if (existing == null)
        {
            var user = new User
            {
                Username = username,
                Email = email,
                DisplayName = displayName,
                Role = role,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(password),
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            context.Users.Add(user);
            context.SaveChanges();
            return user;
        }

        // Keep test credentials deterministic on every startup.
        existing.Username = username;
        existing.Email = email;
        existing.DisplayName = displayName;
        existing.Role = role;
        existing.PasswordHash = BCrypt.Net.BCrypt.HashPassword(password);
        existing.IsActive = true;
        context.SaveChanges();
        return existing;
    }

    private static void EnsureClient(
        ApplicationDbContext context,
        User user,
        string ssidn,
        string smsUsername,
        string smsPassword,
        decimal smsCostPerMessage)
    {
        var existing = context.Clients.FirstOrDefault(c => c.UserId == user.Id);
        if (existing != null)
        {
            existing.Ssidn = ssidn;
            existing.SmsCostPerMessage = smsCostPerMessage;
            context.SaveChanges();

            EnsureSmsGatewayMapping(context, existing.Id, smsUsername, smsPassword, existing.Name);
            return;
        }

        var client = new Client
        {
            UserId = user.Id,
            Name = user.DisplayName,
            Ssidn = ssidn,
            SmsCostPerMessage = smsCostPerMessage
        };
        context.Clients.Add(client);
        context.SaveChanges();

        EnsureSmsGatewayMapping(context, client.Id, smsUsername, smsPassword, client.Name);
    }

    private static void EnsureSmsGatewayMapping(
        ApplicationDbContext context,
        string clientId,
        string smsUsername,
        string smsPassword,
        string clientName)
    {
        var mapping = context.ClientSmsGateways.FirstOrDefault(x => x.ClientId == clientId);
        if (mapping == null)
        {
            var gateway = new SmsGateway
            {
                Provider = "EBS",
                Name = $"{clientName} Gateway",
                IsActive = true
            };
            context.SmsGateways.Add(gateway);
            context.SaveChanges();

            context.SmsGatewayCredentials.AddRange(
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
            context.ClientSmsGateways.Add(new ClientSmsGateway
            {
                ClientId = clientId,
                SmsGatewayId = gateway.Id
            });
            context.SaveChanges();
            return;
        }

        var creds = context.SmsGatewayCredentials
            .Where(c => c.SmsGatewayId == mapping.SmsGatewayId)
            .ToList();

        var usernameCred = creds.FirstOrDefault(c => c.Key == "username");
        var passwordCred = creds.FirstOrDefault(c => c.Key == "password");

        if (usernameCred == null)
        {
            context.SmsGatewayCredentials.Add(new SmsGatewayCredential
            {
                SmsGatewayId = mapping.SmsGatewayId,
                Key = "username",
                Value = smsUsername
            });
        }
        else
        {
            usernameCred.Value = smsUsername;
        }

        if (passwordCred == null)
        {
            context.SmsGatewayCredentials.Add(new SmsGatewayCredential
            {
                SmsGatewayId = mapping.SmsGatewayId,
                Key = "password",
                Value = smsPassword
            });
        }
        else
        {
            passwordCred.Value = smsPassword;
        }

        context.SaveChanges();
    }

    private static void EnsureRecipientsForUser(ApplicationDbContext context, string clientId)
    {
        if (context.Recipients.Any(r => r.ClientId == clientId))
        {
            return;
        }

        context.Recipients.AddRange(
            new Recipient
            {
                ClientId = clientId,
                Name = "Tendai Moyo",
                PhoneNumber = "+263771234567",
                Email = "tendai.moyo@example.com",
                IsActive = true
            },
            new Recipient
            {
                ClientId = clientId,
                Name = "Rudo Dube",
                PhoneNumber = "+263772345678",
                Email = "rudo.dube@example.com",
                IsActive = true
            },
            new Recipient
            {
                ClientId = clientId,
                Name = "Farai Chikore",
                PhoneNumber = "+263773456789",
                Email = "farai.chikore@example.com",
                IsActive = true
            },
            new Recipient
            {
                ClientId = clientId,
                Name = "Nyasha Sibanda",
                PhoneNumber = "+263774567890",
                Email = "nyasha.sibanda@example.com",
                IsActive = true
            }
        );

        context.SaveChanges();
    }

    private static void EnsureWelcomeNotification(
        ApplicationDbContext context,
        string userId,
        string title,
        string message,
        string createdByUserId)
    {
        var exists = context.Notifications.Any(n =>
            n.UserId == userId &&
            n.Title == title &&
            n.Type == "System");

        if (exists)
        {
            return;
        }

        context.Notifications.Add(new Notification
        {
            UserId = userId,
            Title = title,
            Message = message,
            Type = "System",
            DeliveryStatus = "Sent",
            CreatedByUserId = createdByUserId
        });
        context.SaveChanges();
    }
}
