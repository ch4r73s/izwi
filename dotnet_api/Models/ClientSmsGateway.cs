using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace dotnet_api.Models;

public class ClientSmsGateway
{
    [Key]
    [MaxLength(50)]
    public string Id { get; set; } = Guid.NewGuid().ToString();

    [Required]
    [MaxLength(50)]
    public string ClientId { get; set; } = string.Empty;

    [Required]
    [MaxLength(50)]
    public string SmsGatewayId { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey("ClientId")]
    public virtual Client? Client { get; set; }

    [ForeignKey("SmsGatewayId")]
    public virtual SmsGateway? SmsGateway { get; set; }
}
