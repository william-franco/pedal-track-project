using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PedalTrackBackend.Migrations
{
    /// <inheritdoc />
    public partial class AddBikePhoto : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "PhotoBase64",
                table: "Bikes",
                type: "TEXT",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "PhotoBase64",
                table: "Bikes");
        }
    }
}
