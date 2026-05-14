using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace dotnet_api.Migrations
{
    /// <inheritdoc />
    public partial class AddSmsPackagesAndClientPayments : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "SmsPackages",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    MaxSmsLimit = table.Column<int>(type: "int", nullable: true),
                    PricePerSms = table.Column<decimal>(type: "decimal(18,4)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SmsPackages", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "ClientPayments",
                columns: table => new
                {
                    Id = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    ClientId = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    PackageId = table.Column<int>(type: "int", nullable: false),
                    AmountPaid = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    SmsAllocated = table.Column<int>(type: "int", nullable: false),
                    SmsConsumed = table.Column<int>(type: "int", nullable: false),
                    PaidAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Notes = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ClientPayments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ClientPayments_Clients_ClientId",
                        column: x => x.ClientId,
                        principalTable: "Clients",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ClientPayments_SmsPackages_PackageId",
                        column: x => x.PackageId,
                        principalTable: "SmsPackages",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.InsertData(
                table: "SmsPackages",
                columns: new[] { "Id", "Description", "MaxSmsLimit", "Name", "PricePerSms" },
                values: new object[,]
                {
                    { 1, "Up to 5,000 SMS per month", 5000, "Starter", 0.0300m },
                    { 2, "Up to 10,000 SMS per month", 10000, "Business", 0.0250m },
                    { 3, "Above 10,000 SMS per month", null, "Enterprise", 0.0200m }
                });

            migrationBuilder.CreateIndex(
                name: "IX_ClientPayments_ClientId",
                table: "ClientPayments",
                column: "ClientId");

            migrationBuilder.CreateIndex(
                name: "IX_ClientPayments_PackageId",
                table: "ClientPayments",
                column: "PackageId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ClientPayments");

            migrationBuilder.DropTable(
                name: "SmsPackages");
        }
    }
}
