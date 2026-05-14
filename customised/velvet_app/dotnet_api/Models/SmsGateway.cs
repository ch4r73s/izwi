using System.ComponentModel.DataAnnotations;

namespace dotnet_api.Models;

public class SmsGateway
{
    [Key]
    [MaxLength(50)]
    public string Id { get; set; } = Guid.NewGuid().ToString();

    [Required]
    [MaxLength(60)]
    public string Provider { get; set; } = "EBS";

    [Required]
    [MaxLength(120)]
    public string Name { get; set; } = "Default EBS Gateway";

    public bool IsActive { get; set; } = true;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public virtual ICollection<SmsGatewayCredential> Credentials { get; set; } =
        new List<SmsGatewayCredential>();
    public virtual ICollection<ClientSmsGateway> ClientMappings { get; set; } =
        new List<ClientSmsGateway>();
}
