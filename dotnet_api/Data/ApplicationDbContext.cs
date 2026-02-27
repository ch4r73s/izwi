using dotnet_api.Models;
using Microsoft.EntityFrameworkCore;

namespace dotnet_api.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<Client> Clients => Set<Client>();
    public DbSet<Recipient> Recipients => Set<Recipient>();
    public DbSet<SmsGateway> SmsGateways => Set<SmsGateway>();
    public DbSet<SmsGatewayCredential> SmsGatewayCredentials => Set<SmsGatewayCredential>();
    public DbSet<ClientSmsGateway> ClientSmsGateways => Set<ClientSmsGateway>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<DeviceToken> DeviceTokens => Set<DeviceToken>();
    public DbSet<PasswordResetToken> PasswordResetTokens => Set<PasswordResetToken>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<User>()
            .HasIndex(u => u.Username)
            .IsUnique();

        modelBuilder.Entity<User>()
            .HasIndex(u => u.Email)
            .IsUnique();

        modelBuilder.Entity<User>()
            .HasIndex(u => u.Role);

        modelBuilder.Entity<Client>()
            .HasIndex(c => c.UserId)
            .IsUnique();

        modelBuilder.Entity<Client>()
            .HasIndex(c => c.Ssidn);

        modelBuilder.Entity<ClientSmsGateway>()
            .HasIndex(csg => csg.ClientId)
            .IsUnique();

        modelBuilder.Entity<ClientSmsGateway>()
            .HasIndex(csg => csg.SmsGatewayId);

        modelBuilder.Entity<SmsGateway>()
            .HasIndex(sg => sg.Provider);

        modelBuilder.Entity<SmsGatewayCredential>()
            .HasIndex(sgc => new { sgc.SmsGatewayId, sgc.Key })
            .IsUnique();

        modelBuilder.Entity<Recipient>()
            .HasIndex(r => r.ClientId);

        modelBuilder.Entity<Recipient>()
            .HasIndex(r => r.PhoneNumber);

        modelBuilder.Entity<Notification>()
            .HasIndex(n => n.UserId);

        modelBuilder.Entity<Notification>()
            .HasIndex(n => n.IsRead);

        modelBuilder.Entity<Notification>()
            .HasIndex(n => n.CreatedAt);

        modelBuilder.Entity<Notification>()
            .HasIndex(n => n.CreatedByUserId);

        modelBuilder.Entity<Notification>()
            .HasIndex(n => n.DeliveryStatus);

        modelBuilder.Entity<DeviceToken>()
            .HasIndex(dt => dt.UserId);

        modelBuilder.Entity<DeviceToken>()
            .HasIndex(dt => dt.Token)
            .IsUnique();

        modelBuilder.Entity<PasswordResetToken>()
            .HasIndex(prt => prt.Token)
            .IsUnique();

        modelBuilder.Entity<PasswordResetToken>()
            .HasIndex(prt => prt.UserId);

        modelBuilder.Entity<User>()
            .HasOne(u => u.ClientProfile)
            .WithOne(c => c.User)
            .HasForeignKey<Client>(c => c.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<User>()
            .HasMany(u => u.Notifications)
            .WithOne(n => n.User)
            .HasForeignKey(n => n.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<User>()
            .HasMany(u => u.SentNotifications)
            .WithOne(n => n.CreatedByUser)
            .HasForeignKey(n => n.CreatedByUserId)
            .OnDelete(DeleteBehavior.NoAction);

        modelBuilder.Entity<User>()
            .HasMany(u => u.DeviceTokens)
            .WithOne(dt => dt.User)
            .HasForeignKey(dt => dt.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<User>()
            .HasMany(u => u.PasswordResetTokens)
            .WithOne(prt => prt.User)
            .HasForeignKey(prt => prt.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Client>()
            .HasMany(c => c.Recipients)
            .WithOne(r => r.Client)
            .HasForeignKey(r => r.ClientId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Client>()
            .HasOne(c => c.ClientSmsGateway)
            .WithOne(csg => csg.Client)
            .HasForeignKey<ClientSmsGateway>(csg => csg.ClientId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<SmsGateway>()
            .HasMany(sg => sg.Credentials)
            .WithOne(sgc => sgc.SmsGateway)
            .HasForeignKey(sgc => sgc.SmsGatewayId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<SmsGateway>()
            .HasMany(sg => sg.ClientMappings)
            .WithOne(csg => csg.SmsGateway)
            .HasForeignKey(csg => csg.SmsGatewayId)
            .OnDelete(DeleteBehavior.Cascade);
    }

    public override int SaveChanges()
    {
        UpdateTimestamps();
        return base.SaveChanges();
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        UpdateTimestamps();
        return base.SaveChangesAsync(cancellationToken);
    }

    private void UpdateTimestamps()
    {
        var utcNow = DateTime.UtcNow;

        foreach (var entry in ChangeTracker.Entries())
        {
            if (entry.State != EntityState.Modified)
            {
                continue;
            }

            if (entry.Entity is User user)
            {
                user.UpdatedAt = utcNow;
            }
            else if (entry.Entity is DeviceToken deviceToken)
            {
                deviceToken.UpdatedAt = utcNow;
            }
            else if (entry.Entity is Client client)
            {
                client.UpdatedAt = utcNow;
            }
        }
    }
}
