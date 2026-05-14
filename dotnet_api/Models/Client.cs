using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace dotnet_api.Models;

public class Client
{
    [Key]
    [MaxLength(50)]
    public string Id { get; set; } = Guid.NewGuid().ToString();

    [Required]
    [MaxLength(50)]
    public string UserId { get; set; } = string.Empty;

    [Required]
    [MaxLength(120)]
    public string Name { get; set; } = string.Empty;

    [Required]
    [MaxLength(50)]
    public string Ssidn { get; set; } = string.Empty;

    [Column(TypeName = "decimal(18,4)")]
    public decimal SmsCostPerMessage { get; set; } = 0.05m;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey("UserId")]
    public virtual User? User { get; set; }

    public virtual ClientSmsGateway? ClientSmsGateway { get; set; }
    public virtual ICollection<Recipient> Recipients { get; set; } = new List<Recipient>();
    public virtual ICollection<NotificationTemplate> Templates { get; set; } = new List<NotificationTemplate>();
    public virtual ICollection<ClientPayment> Payments { get; set; } = new List<ClientPayment>();
}
