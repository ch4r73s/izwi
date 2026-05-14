using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace dotnet_api.Models;

public class Notification
{
    [Key]
    [MaxLength(50)]
    public string Id { get; set; } = Guid.NewGuid().ToString();

    [Required]
    [MaxLength(50)]
    public string UserId { get; set; } = string.Empty;

    [Required]
    [MaxLength(255)]
    public string Title { get; set; } = string.Empty;

    [Required]
    public string Message { get; set; } = string.Empty;

    [Required]
    [MaxLength(50)]
    public string Type { get; set; } = "System";

    [MaxLength(50)]
    public string? ReferenceId { get; set; }

    [MaxLength(50)]
    public string? CreatedByUserId { get; set; }

    [Required]
    [MaxLength(20)]
    public string DeliveryStatus { get; set; } = "Sent";

    [MaxLength(1000)]
    public string? ErrorDetails { get; set; }

    // JSON array: [{"name":"...","phone":"...","sent":true}, ...]
    public string? RecipientsSummary { get; set; }

    public bool IsRead { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime? ReadAt { get; set; }

    [ForeignKey("UserId")]
    public virtual User? User { get; set; }

    [ForeignKey("CreatedByUserId")]
    public virtual User? CreatedByUser { get; set; }

    public virtual ICollection<NotificationRecipient> Recipients { get; set; } = [];
}
