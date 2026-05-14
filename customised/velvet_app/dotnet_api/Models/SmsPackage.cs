using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace dotnet_api.Models;

public class SmsPackage
{
    [Key]
    public int Id { get; set; }

    [Required]
    [MaxLength(50)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(200)]
    public string Description { get; set; } = string.Empty;

    // null means no upper cap (Enterprise tier)
    public int? MaxSmsLimit { get; set; }

    [Column(TypeName = "decimal(18,4)")]
    public decimal PricePerSms { get; set; }

    public virtual ICollection<ClientPayment> Payments { get; set; } = new List<ClientPayment>();
}
