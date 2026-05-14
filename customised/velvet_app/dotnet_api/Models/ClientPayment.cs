using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace dotnet_api.Models;

public class ClientPayment
{
    [Key]
    [MaxLength(50)]
    public string Id { get; set; } = Guid.NewGuid().ToString();

    [Required]
    [MaxLength(50)]
    public string ClientId { get; set; } = string.Empty;

    [Required]
    public int PackageId { get; set; }

    [Column(TypeName = "decimal(18,2)")]
    public decimal AmountPaid { get; set; }

    // Stored at payment creation so future price changes don't affect this allocation
    public int SmsAllocated { get; set; }

    public int SmsConsumed { get; set; } = 0;

    public DateTime PaidAt { get; set; } = DateTime.UtcNow;

    [MaxLength(200)]
    public string? Notes { get; set; }

    [ForeignKey("ClientId")]
    public virtual Client? Client { get; set; }

    [ForeignKey("PackageId")]
    public virtual SmsPackage? Package { get; set; }
}
