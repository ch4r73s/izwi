using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace dotnet_api.Migrations
{
    /// <inheritdoc />
    public partial class RefactorSmsGatewayCredentials : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "SmsGateways",
                columns: table => new
                {
                    Id = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Provider = table.Column<string>(type: "nvarchar(60)", maxLength: 60, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(120)", maxLength: 120, nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SmsGateways", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "ClientSmsGateways",
                columns: table => new
                {
                    Id = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    ClientId = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    SmsGatewayId = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ClientSmsGateways", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ClientSmsGateways_Clients_ClientId",
                        column: x => x.ClientId,
                        principalTable: "Clients",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ClientSmsGateways_SmsGateways_SmsGatewayId",
                        column: x => x.SmsGatewayId,
                        principalTable: "SmsGateways",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "SmsGatewayCredentials",
                columns: table => new
                {
                    Id = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    SmsGatewayId = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Key = table.Column<string>(type: "nvarchar(60)", maxLength: 60, nullable: false),
                    Value = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SmsGatewayCredentials", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SmsGatewayCredentials_SmsGateways_SmsGatewayId",
                        column: x => x.SmsGatewayId,
                        principalTable: "SmsGateways",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ClientSmsGateways_ClientId",
                table: "ClientSmsGateways",
                column: "ClientId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ClientSmsGateways_SmsGatewayId",
                table: "ClientSmsGateways",
                column: "SmsGatewayId");

            migrationBuilder.CreateIndex(
                name: "IX_SmsGatewayCredentials_SmsGatewayId_Key",
                table: "SmsGatewayCredentials",
                columns: new[] { "SmsGatewayId", "Key" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_SmsGateways_Provider",
                table: "SmsGateways",
                column: "Provider");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ClientSmsGateways");

            migrationBuilder.DropTable(
                name: "SmsGatewayCredentials");

            migrationBuilder.DropTable(
                name: "SmsGateways");
        }
    }
}
