using dotnet_api.Models;

namespace dotnet_api.Interfaces;

public interface INotificationService
{
    Task<IReadOnlyList<Notification>> GetForUserAsync(string userId);
    Task<IReadOnlyList<Notification>> GetSentByUserAsync(string senderUserId);
    Task<IReadOnlyList<Notification>> GetAdminErrorNotificationsAsync(int take = 100);
    Task<IReadOnlyList<Notification>> GetAllAsync(int take = 100);
    Task<Notification> CreateForUserAsync(string userId, string title, string message, string type, string? referenceId, string? createdByUserId, string deliveryStatus = "Sent", string? errorDetails = null, string? recipientsSummary = null);
    Task<int> CreateForUsersAsync(IEnumerable<string> userIds, string title, string message, string type, string? referenceId, string? createdByUserId, string deliveryStatus = "Sent", string? errorDetails = null, string? recipientsSummary = null);
    Task<bool> MarkAsReadAsync(string notificationId, string userId, bool canReadAny = false);
    Task<int> MarkAllAsReadAsync(string userId);
    Task RegisterDeviceTokenAsync(string userId, string token, string deviceType);
}
