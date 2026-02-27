using dotnet_api.Data;
using dotnet_api.Interfaces;
using dotnet_api.Models;
using Microsoft.EntityFrameworkCore;

namespace dotnet_api.Services;

public class NotificationService : INotificationService
{
    private readonly ApplicationDbContext _context;

    public NotificationService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<IReadOnlyList<Notification>> GetForUserAsync(string userId)
    {
        return await _context.Notifications
            .Where(n => n.UserId == userId)
            .OrderByDescending(n => n.CreatedAt)
            .ToListAsync();
    }

    public async Task<IReadOnlyList<Notification>> GetSentByUserAsync(string senderUserId)
    {
        return await _context.Notifications
            .Where(n => n.CreatedByUserId == senderUserId)
            .OrderByDescending(n => n.CreatedAt)
            .ToListAsync();
    }

    public async Task<IReadOnlyList<Notification>> GetAdminErrorNotificationsAsync(int take = 100)
    {
        return await _context.Notifications
            .Where(n => n.DeliveryStatus == "Failed" || n.Type == "Error")
            .OrderByDescending(n => n.CreatedAt)
            .Take(Math.Max(1, Math.Min(take, 500)))
            .ToListAsync();
    }

    public async Task<IReadOnlyList<Notification>> GetAllAsync(int take = 100)
    {
        return await _context.Notifications
            .OrderByDescending(n => n.CreatedAt)
            .Take(Math.Max(1, Math.Min(take, 500)))
            .ToListAsync();
    }

    public async Task<Notification> CreateForUserAsync(string userId, string title, string message, string type, string? referenceId, string? createdByUserId, string deliveryStatus = "Sent", string? errorDetails = null)
    {
        var notification = new Notification
        {
            UserId = userId,
            Title = title,
            Message = message,
            Type = type,
            ReferenceId = referenceId,
            CreatedByUserId = createdByUserId,
            DeliveryStatus = string.IsNullOrWhiteSpace(deliveryStatus) ? "Sent" : deliveryStatus,
            ErrorDetails = errorDetails
        };

        await _context.Notifications.AddAsync(notification);
        await _context.SaveChangesAsync();

        return notification;
    }

    public async Task<int> CreateForUsersAsync(IEnumerable<string> userIds, string title, string message, string type, string? referenceId, string? createdByUserId, string deliveryStatus = "Sent", string? errorDetails = null)
    {
        var ids = userIds.Distinct().ToList();
        if (ids.Count == 0)
        {
            return 0;
        }

        var notifications = ids.Select(id => new Notification
        {
            UserId = id,
            Title = title,
            Message = message,
            Type = type,
            ReferenceId = referenceId,
            CreatedByUserId = createdByUserId,
            DeliveryStatus = string.IsNullOrWhiteSpace(deliveryStatus) ? "Sent" : deliveryStatus,
            ErrorDetails = errorDetails
        });

        await _context.Notifications.AddRangeAsync(notifications);
        await _context.SaveChangesAsync();

        return ids.Count;
    }

    public async Task<bool> MarkAsReadAsync(string notificationId, string userId, bool canReadAny = false)
    {
        var query = _context.Notifications.AsQueryable();

        if (!canReadAny)
        {
            query = query.Where(n => n.UserId == userId);
        }

        var notification = await query.FirstOrDefaultAsync(n => n.Id == notificationId);
        if (notification == null)
        {
            return false;
        }

        notification.IsRead = true;
        notification.ReadAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<int> MarkAllAsReadAsync(string userId)
    {
        var unread = await _context.Notifications
            .Where(n => n.UserId == userId && !n.IsRead)
            .ToListAsync();

        foreach (var item in unread)
        {
            item.IsRead = true;
            item.ReadAt = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();
        return unread.Count;
    }

    public async Task RegisterDeviceTokenAsync(string userId, string token, string deviceType)
    {
        var existing = await _context.DeviceTokens.FirstOrDefaultAsync(dt => dt.Token == token);

        if (existing == null)
        {
            await _context.DeviceTokens.AddAsync(new DeviceToken
            {
                UserId = userId,
                Token = token,
                DeviceType = deviceType,
                IsActive = true
            });
        }
        else
        {
            existing.UserId = userId;
            existing.DeviceType = deviceType;
            existing.IsActive = true;
        }

        await _context.SaveChangesAsync();
    }
}
