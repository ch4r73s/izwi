using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace dotnet_api.Models;

public class NotificationRecipient
{
    [Key]
    [MaxLength(50)]
    public string Id { get; set; } = Guid.NewGuid().ToString();

    [Required]
    [MaxLength(50)]
    public string NotificationId { get; set; } = string.Empty;

    [MaxLength(255)]
    public string? Name { get; set; }

    [Required]
    [MaxLength(30)]
    public string PhoneNumber { get; set; } = string.Empty;

    [Required]
    [MaxLength(20)]
    public string Status { get; set; } = "Sent"; // "Sent" | "Failed"

    [MaxLength(500)]
    public string? ErrorReason { get; set; }

    [MaxLength(100)]
    public string? GatewayMessageId { get; set; }

    public string? GatewayPayload { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime? UpdatedAt { get; set; }

    public DateTime? DeliveredAt { get; set; }

    [Column(TypeName = "decimal(18,6)")]
    public decimal? CostAmount { get; set; }

    [MaxLength(10)]
    public string? CostCurrency { get; set; }

    [ForeignKey("NotificationId")]
    public virtual Notification? Notification { get; set; }
}

public record NotificationRecipientInput(
    string? Name,
    string PhoneNumber,
    string Status,
    string? ErrorReason = null,
    string? GatewayMessageId = null,
    string? GatewayPayload = null);
