using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Scalar.AspNetCore;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// ======================= SERVICES =======================
builder.Services.AddSingleton(TimeProvider.System);

// ======================= DATABASE =======================
builder.Services.AddDbContext<AppDbContext>(opt =>
    opt.UseSqlite(builder.Configuration.GetConnectionString("Default") ?? "Data Source=pedaltrack.db"));

// ======================= OPENAPI (.NET 9+) =======================
builder.Services.AddOpenApi();

// ======================= CORS =======================
builder.Services.AddCors(o =>
    o.AddPolicy("AllowAll", b =>
        b.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()));

// ======================= JWT =======================
var jwtKey = builder.Configuration["Jwt:Key"]
    ?? throw new InvalidOperationException("Jwt:Key não configurada em appsettings.");

var keyBytes = Encoding.ASCII.GetBytes(jwtKey);

builder.Services.AddAuthentication(o =>
{
    o.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    o.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(o =>
{
    o.RequireHttpsMetadata = !builder.Environment.IsDevelopment();
    o.SaveToken = true;
    o.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(keyBytes),
        ValidateIssuer = false,
        ValidateAudience = false,
        ClockSkew = TimeSpan.Zero
    };
});
builder.Services.AddAuthorization();

var app = builder.Build();

// ======================= MIGRATIONS + PRAGMA =======================
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.OpenConnection();
    db.Database.ExecuteSqlRaw("PRAGMA foreign_keys = ON;");
    db.Database.CloseConnection();
    db.Database.Migrate();
}

// ======================= PIPELINE =======================
if (app.Environment.IsDevelopment())
    app.MapOpenApi();
app.MapScalarApiReference();

app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();

// ======================= ROUTES =======================
var api = app.MapGroup("/api");
var auth = api.MapGroup("/auth");
var protected_ = api.MapGroup("/").RequireAuthorization();

// ======================= AUTH =======================
auth.MapPost("/register", async (RegisterDto dto, AppDbContext db, TimeProvider time) =>
{
    if (await db.Users.AnyAsync(u => u.Email == dto.Email))
        return Results.Conflict("Email já cadastrado.");

    var now = time.GetUtcNow().UtcDateTime;
    var user = new User
    {
        Name = dto.Name,
        Email = dto.Email,
        Password = BCrypt.Net.BCrypt.HashPassword(dto.Password),
        CreatedAt = now,
        UpdatedAt = now
    };

    db.Users.Add(user);
    await db.SaveChangesAsync();

    return Results.Created($"/api/users/{user.Id}", new UserDto(user.Id, user.Name, user.Email, user.CreatedAt));
})
.WithName("Register")
.WithSummary("Cadastra novo usuário");

auth.MapPost("/login", async (LoginDto dto, AppDbContext db, TimeProvider time) =>
{
    var user = await db.Users.FirstOrDefaultAsync(u => u.Email == dto.Email);
    if (user is null || !BCrypt.Net.BCrypt.Verify(dto.Password, user.Password))
        return Results.Unauthorized();

    var tokenHandler = new JwtSecurityTokenHandler();
    var tokenDescriptor = new SecurityTokenDescriptor
    {
        Subject = new ClaimsIdentity([
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Email,          user.Email)
        ]),
        Expires = time.GetUtcNow().UtcDateTime.AddHours(8),
        SigningCredentials = new SigningCredentials(
            new SymmetricSecurityKey(keyBytes),
            SecurityAlgorithms.HmacSha256Signature)
    };

    var token = tokenHandler.CreateToken(tokenDescriptor);
    return Results.Ok(new { AccessToken = tokenHandler.WriteToken(token) });
})
.WithName("Login")
.WithSummary("Autentica usuário e retorna JWT");

// ======================= BIKES =======================
protected_.MapPost("/bikes", async (CreateBikeDto dto, ClaimsPrincipal claims, AppDbContext db, TimeProvider time) =>
{
    var userId = claims.GetUserId();
    var now = time.GetUtcNow().UtcDateTime;

    var bike = new Bike
    {
        UserId = userId,
        Nickname = dto.Nickname,
        Brand = dto.Brand,
        Model = dto.Model,
        CreatedAt = now,
        UpdatedAt = now
    };

    db.Bikes.Add(bike);
    await db.SaveChangesAsync();

    return Results.Created($"/api/bikes/{bike.Id}", bike.ToDto());
})
.WithName("CreateBike")
.WithSummary("Cadastra nova bicicleta");

protected_.MapGet("/bikes", async (ClaimsPrincipal claims, AppDbContext db) =>
{
    var userId = claims.GetUserId();
    var bikes = await db.Bikes
        .AsNoTracking()
        .Where(b => b.UserId == userId)
        .Include(b => b.Parts)
        .ToListAsync();

    return Results.Ok(bikes.Select(b => b.ToDto()));
})
.WithName("GetBikes")
.WithSummary("Lista bicicletas do usuário autenticado");

protected_.MapGet("/bikes/{id:int}", async (int id, ClaimsPrincipal claims, AppDbContext db) =>
{
    var userId = claims.GetUserId();
    var bike = await db.Bikes
        .AsNoTracking()
        .Where(b => b.Id == id && b.UserId == userId)
        .Include(b => b.Parts)
        .FirstOrDefaultAsync();

    return bike is null
        ? Results.NotFound("Bicicleta não encontrada.")
        : Results.Ok(bike.ToDto());
})
.WithName("GetBike")
.WithSummary("Retorna bicicleta por ID");

protected_.MapPut("/bikes/{id:int}", async (int id, UpdateBikeDto dto, ClaimsPrincipal claims, AppDbContext db, TimeProvider time) =>
{
    var userId = claims.GetUserId();
    var bike = await db.Bikes.FirstOrDefaultAsync(b => b.Id == id && b.UserId == userId);
    if (bike is null) return Results.NotFound("Bicicleta não encontrada.");

    bike.Nickname = dto.Nickname ?? bike.Nickname;
    bike.Brand = dto.Brand ?? bike.Brand;
    bike.Model = dto.Model ?? bike.Model;
    bike.UpdatedAt = time.GetUtcNow().UtcDateTime;

    await db.SaveChangesAsync();
    return Results.Ok(bike.ToDto());
})
.WithName("UpdateBike")
.WithSummary("Atualiza dados da bicicleta");

protected_.MapDelete("/bikes/{id:int}", async (int id, ClaimsPrincipal claims, AppDbContext db) =>
{
    var userId = claims.GetUserId();
    var bike = await db.Bikes.FirstOrDefaultAsync(b => b.Id == id && b.UserId == userId);
    if (bike is null) return Results.NotFound("Bicicleta não encontrada.");

    db.Bikes.Remove(bike);
    await db.SaveChangesAsync();
    return Results.NoContent();
})
.WithName("DeleteBike")
.WithSummary("Remove bicicleta");

// ======================= RIDES (antigo UsageRecord) =======================
protected_.MapPost("/bikes/{bikeId:int}/rides", async (
    int bikeId,
    CreateRideDto dto,
    ClaimsPrincipal claims,
    AppDbContext db,
    TimeProvider time) =>
{
    var userId = claims.GetUserId();
    var bike = await db.Bikes
        .Include(b => b.Parts)
        .FirstOrDefaultAsync(b => b.Id == bikeId && b.UserId == userId);

    if (bike is null)
        return Results.NotFound("Bicicleta não encontrada.");

    if (dto.DistanceKm <= 0)
        return Results.BadRequest("Distância deve ser maior que zero.");

    var now = time.GetUtcNow().UtcDateTime;

    var ride = new Ride
    {
        BikeId = bikeId,
        DistanceKm = dto.DistanceKm,
        Terrain = dto.Terrain,
        RiddenAt = dto.RiddenAt ?? now,
        CreatedAt = now
    };
    db.Rides.Add(ride);

    // RF04 — distribuir km para todas as peças ativas (RN01)
    var newAlerts = new List<MaintenanceAlert>();
    foreach (var part in bike.Parts.Where(p => p.Status == PartStatus.Active))
    {
        part.KmRidden += dto.DistanceKm;

        // RF08 — alertar quando atingir 90% da vida útil (RN07: apenas uma vez por ciclo)
        var progress = part.KmRidden / part.ExpectedDurationKm;
        if (progress >= 0.9 && !part.AlertSent)
        {
            part.AlertSent = true;
            newAlerts.Add(new MaintenanceAlert
            {
                BikeId = bikeId,
                PartId = part.Id,
                Message = $"Peça '{part.Name}' atingiu {progress:P0} da vida útil esperada.",
                TriggeredAt = now,
                CreatedAt = now
            });
        }
    }

    if (newAlerts.Count > 0)
        db.MaintenanceAlerts.AddRange(newAlerts);

    await db.SaveChangesAsync();

    return Results.Created($"/api/bikes/{bikeId}/rides/{ride.Id}", ride);
})
.WithName("CreateRide")
.WithSummary("Registra passeio e distribui km para peças ativas");

protected_.MapGet("/bikes/{bikeId:int}/rides", async (int bikeId, ClaimsPrincipal claims, AppDbContext db) =>
{
    var userId = claims.GetUserId();
    if (!await db.Bikes.AnyAsync(b => b.Id == bikeId && b.UserId == userId))
        return Results.NotFound("Bicicleta não encontrada.");

    var rides = await db.Rides
        .AsNoTracking()
        .Where(r => r.BikeId == bikeId)
        .OrderByDescending(r => r.RiddenAt)
        .ToListAsync();

    return Results.Ok(rides);
})
.WithName("GetRides")
.WithSummary("Histórico de passeios da bicicleta");

// ======================= PARTS (PEÇAS) =======================
protected_.MapPost("/bikes/{bikeId:int}/parts", async (
    int bikeId,
    CreatePartDto dto,
    ClaimsPrincipal claims,
    AppDbContext db,
    TimeProvider time) =>
{
    var userId = claims.GetUserId();
    if (!await db.Bikes.AnyAsync(b => b.Id == bikeId && b.UserId == userId))
        return Results.NotFound("Bicicleta não encontrada.");

    if (dto.ExpectedDurationKm <= 0)
        return Results.BadRequest("Duração esperada deve ser maior que zero.");

    var now = time.GetUtcNow().UtcDateTime;
    var part = new Part
    {
        BikeId = bikeId,
        Name = dto.Name,
        ExpectedDurationKm = dto.ExpectedDurationKm,
        PricePaid = dto.PricePaid,
        InstalledAt = dto.InstalledAt ?? now,
        KmRidden = 0,
        Status = PartStatus.Active,
        AlertSent = false,
        CreatedAt = now
    };

    db.Parts.Add(part);
    await db.SaveChangesAsync();

    return Results.Created($"/api/bikes/{bikeId}/parts/{part.Id}", part.ToDto());
})
.WithName("CreatePart")
.WithSummary("Instala nova peça na bicicleta");

protected_.MapGet("/bikes/{bikeId:int}/parts", async (int bikeId, ClaimsPrincipal claims, AppDbContext db) =>
{
    var userId = claims.GetUserId();
    if (!await db.Bikes.AnyAsync(b => b.Id == bikeId && b.UserId == userId))
        return Results.NotFound("Bicicleta não encontrada.");

    var parts = await db.Parts
        .AsNoTracking()
        .Where(p => p.BikeId == bikeId)
        .OrderByDescending(p => p.CreatedAt)
        .ToListAsync();

    return Results.Ok(parts.Select(p => p.ToDto()));
})
.WithName("GetParts")
.WithSummary("Lista peças da bicicleta com progresso de desgaste");

protected_.MapGet("/bikes/{bikeId:int}/parts/{partId:int}", async (
    int bikeId, int partId, ClaimsPrincipal claims, AppDbContext db) =>
{
    var userId = claims.GetUserId();
    if (!await db.Bikes.AnyAsync(b => b.Id == bikeId && b.UserId == userId))
        return Results.NotFound("Bicicleta não encontrada.");

    var part = await db.Parts.AsNoTracking().FirstOrDefaultAsync(p => p.Id == partId && p.BikeId == bikeId);
    return part is null ? Results.NotFound("Peça não encontrada.") : Results.Ok(part.ToDto());
})
.WithName("GetPart")
.WithSummary("Retorna peça por ID com progresso");

// RF07 — Trocar peça (RN03: sem herança de dados, RN04: registro imutável)
protected_.MapPost("/bikes/{bikeId:int}/parts/{partId:int}/exchange", async (
    int bikeId,
    int partId,
    ExchangePartDto dto,
    ClaimsPrincipal claims,
    AppDbContext db,
    TimeProvider time) =>
{
    var userId = claims.GetUserId();
    if (!await db.Bikes.AnyAsync(b => b.Id == bikeId && b.UserId == userId))
        return Results.NotFound("Bicicleta não encontrada.");

    var part = await db.Parts.FirstOrDefaultAsync(p => p.Id == partId && p.BikeId == bikeId);
    if (part is null) return Results.NotFound("Peça não encontrada.");
    if (part.Status != PartStatus.Active) return Results.Conflict("Peça já foi trocada.");

    var now = time.GetUtcNow().UtcDateTime;

    // Encerra a peça atual
    part.Status = PartStatus.Replaced;

    // Cria registro histórico imutável (RN04)
    var exchange = new PartExchange
    {
        PartId = part.Id,
        BikeId = bikeId,
        PartName = part.Name,
        ExpectedDurationKm = part.ExpectedDurationKm,
        ActualKmReached = part.KmRidden,
        PricePaidAtTime = part.PricePaid,
        Notes = dto.Notes,
        ExchangedAt = now,
        CreatedAt = now
    };

    db.PartExchanges.Add(exchange);
    await db.SaveChangesAsync();

    return Results.Created($"/api/bikes/{bikeId}/parts/{partId}/exchanges/{exchange.Id}", exchange);
})
.WithName("ExchangePart")
.WithSummary("Registra troca de peça (histórico imutável)");

protected_.MapGet("/bikes/{bikeId:int}/parts/{partId:int}/exchanges", async (
    int bikeId, int partId, ClaimsPrincipal claims, AppDbContext db) =>
{
    var userId = claims.GetUserId();
    if (!await db.Bikes.AnyAsync(b => b.Id == bikeId && b.UserId == userId))
        return Results.NotFound("Bicicleta não encontrada.");

    var exchanges = await db.PartExchanges
        .AsNoTracking()
        .Where(e => e.PartId == partId && e.BikeId == bikeId)
        .OrderByDescending(e => e.ExchangedAt)
        .ToListAsync();

    return Results.Ok(exchanges);
})
.WithName("GetPartExchanges")
.WithSummary("Histórico de trocas de uma peça");

// ======================= MAINTENANCE CHECKLIST =======================
protected_.MapPost("/bikes/{bikeId:int}/checklists", async (
    int bikeId,
    CreateChecklistDto dto,
    ClaimsPrincipal claims,
    AppDbContext db,
    TimeProvider time) =>
{
    var userId = claims.GetUserId();
    if (!await db.Bikes.AnyAsync(b => b.Id == bikeId && b.UserId == userId))
        return Results.NotFound("Bicicleta não encontrada.");

    var now = time.GetUtcNow().UtcDateTime;
    var checklist = new MaintenanceChecklist
    {
        BikeId = bikeId,
        ExecutedAt = dto.ExecutedAt ?? now,
        ItemsChecked = dto.ItemsChecked,
        Notes = dto.Notes,
        CreatedAt = now
    };

    db.MaintenanceChecklists.Add(checklist);
    await db.SaveChangesAsync();

    return Results.Created($"/api/bikes/{bikeId}/checklists/{checklist.Id}", checklist);
})
.WithName("CreateChecklist")
.WithSummary("Registra execução de checklist de manutenção");

protected_.MapGet("/bikes/{bikeId:int}/checklists", async (int bikeId, ClaimsPrincipal claims, AppDbContext db) =>
{
    var userId = claims.GetUserId();
    if (!await db.Bikes.AnyAsync(b => b.Id == bikeId && b.UserId == userId))
        return Results.NotFound("Bicicleta não encontrada.");

    var checklists = await db.MaintenanceChecklists
        .AsNoTracking()
        .Where(c => c.BikeId == bikeId)
        .OrderByDescending(c => c.ExecutedAt)
        .ToListAsync();

    return Results.Ok(checklists);
})
.WithName("GetChecklists")
.WithSummary("Histórico de checklists de manutenção");

// ======================= ALERTS =======================
protected_.MapGet("/bikes/{bikeId:int}/alerts", async (int bikeId, ClaimsPrincipal claims, AppDbContext db) =>
{
    var userId = claims.GetUserId();
    if (!await db.Bikes.AnyAsync(b => b.Id == bikeId && b.UserId == userId))
        return Results.NotFound("Bicicleta não encontrada.");

    var alerts = await db.MaintenanceAlerts
        .AsNoTracking()
        .Where(a => a.BikeId == bikeId)
        .OrderByDescending(a => a.TriggeredAt)
        .ToListAsync();

    return Results.Ok(alerts);
})
.WithName("GetAlerts")
.WithSummary("Alertas de manutenção da bicicleta");

// ======================= HISTORY (CONSOLIDADO) =======================
protected_.MapGet("/bikes/{bikeId:int}/history", async (int bikeId, ClaimsPrincipal claims, AppDbContext db) =>
{
    var userId = claims.GetUserId();
    if (!await db.Bikes.AnyAsync(b => b.Id == bikeId && b.UserId == userId))
        return Results.NotFound("Bicicleta não encontrada.");

    var rides = await db.Rides
        .AsNoTracking().Where(r => r.BikeId == bikeId)
        .OrderByDescending(r => r.RiddenAt).ToListAsync();

    var exchanges = await db.PartExchanges
        .AsNoTracking().Where(e => e.BikeId == bikeId)
        .OrderByDescending(e => e.ExchangedAt).ToListAsync();

    var checklists = await db.MaintenanceChecklists
        .AsNoTracking().Where(c => c.BikeId == bikeId)
        .OrderByDescending(c => c.ExecutedAt).ToListAsync();

    return Results.Ok(new { Rides = rides, PartExchanges = exchanges, Checklists = checklists });
})
.WithName("GetHistory")
.WithSummary("Histórico consolidado: passeios, trocas e checklists");

app.Run();

// ======================= EXTENSIONS =======================
static class ClaimsExtensions
{
    public static int GetUserId(this ClaimsPrincipal claims)
        => int.Parse(claims.FindFirstValue(ClaimTypes.NameIdentifier)!);
}

// ======================= MODELS =======================
public class User
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public string Email { get; set; } = "";
    public string Password { get; set; } = "";
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public ICollection<Bike> Bikes { get; set; } = [];
}

public class Bike
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public User? User { get; set; }
    public string Nickname { get; set; } = "";
    public string Brand { get; set; } = "";
    public string Model { get; set; } = "";
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public ICollection<Part> Parts { get; set; } = [];
    public ICollection<Ride> Rides { get; set; } = [];
    public ICollection<MaintenanceAlert> MaintenanceAlerts { get; set; } = [];
    public ICollection<MaintenanceChecklist> MaintenanceChecklists { get; set; } = [];
}

public enum PartStatus { Active, Replaced }

public class Part
{
    public int Id { get; set; }
    public int BikeId { get; set; }
    public Bike? Bike { get; set; }
    public string Name { get; set; } = "";
    public double ExpectedDurationKm { get; set; }
    public double KmRidden { get; set; }
    public decimal PricePaid { get; set; }
    public DateTime InstalledAt { get; set; }
    public PartStatus Status { get; set; } = PartStatus.Active;
    public bool AlertSent { get; set; }
    public DateTime CreatedAt { get; set; }

    // RF06 — calculado, não persistido
    public double ProgressPercent => ExpectedDurationKm > 0
        ? Math.Round(KmRidden / ExpectedDurationKm * 100, 1)
        : 0;

    public bool IsOverLimit => KmRidden > ExpectedDurationKm;
}

public class Ride
{
    public int Id { get; set; }
    public int BikeId { get; set; }
    public Bike? Bike { get; set; }
    public double DistanceKm { get; set; }
    public string Terrain { get; set; } = "";
    public DateTime RiddenAt { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class PartExchange
{
    public int Id { get; set; }
    public int PartId { get; set; }
    public Part? Part { get; set; }
    public int BikeId { get; set; }
    public string PartName { get; set; } = "";   // snapshot do nome
    public double ExpectedDurationKm { get; set; }         // snapshot
    public double ActualKmReached { get; set; }
    public decimal PricePaidAtTime { get; set; }         // snapshot do preço
    public string? Notes { get; set; }         // RN05: opcional
    public DateTime ExchangedAt { get; set; }
    public DateTime CreatedAt { get; set; }
    // RN04: sem nenhum endpoint de PUT/DELETE nesta entidade
}

public class MaintenanceAlert
{
    public int Id { get; set; }
    public int BikeId { get; set; }
    public Bike? Bike { get; set; }
    public int PartId { get; set; }
    public Part? Part { get; set; }
    public string Message { get; set; } = "";
    public DateTime TriggeredAt { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class MaintenanceChecklist
{
    public int Id { get; set; }
    public int BikeId { get; set; }
    public Bike? Bike { get; set; }
    public DateTime ExecutedAt { get; set; }
    public string ItemsChecked { get; set; } = ""; // JSON ou CSV dos itens marcados
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; }
}

// ======================= DTOs =======================
public record RegisterDto(string Name, string Email, string Password);
public record LoginDto(string Email, string Password);
public record UserDto(int Id, string Name, string Email, DateTime CreatedAt);

public record CreateBikeDto(string Nickname, string Brand, string Model);
public record UpdateBikeDto(string? Nickname, string? Brand, string? Model);

public record BikeDto(
    int Id, int UserId, string Nickname, string Brand, string Model,
    DateTime CreatedAt, DateTime UpdatedAt,
    IEnumerable<PartDto> Parts);

public record CreateRideDto(double DistanceKm, string Terrain, DateTime? RiddenAt);

public record CreatePartDto(
    string Name,
    double ExpectedDurationKm,
    decimal PricePaid,
    DateTime? InstalledAt);

public record PartDto(
    int Id, int BikeId, string Name,
    double ExpectedDurationKm, double KmRidden,
    double ProgressPercent, bool IsOverLimit,
    decimal PricePaid, DateTime InstalledAt,
    PartStatus Status, bool AlertSent, DateTime CreatedAt);

public record ExchangePartDto(string? Notes);

public record CreateChecklistDto(
    DateTime? ExecutedAt,
    string ItemsChecked,
    string? Notes);

// ======================= MAPPERS =======================
static class Mappers
{
    public static BikeDto ToDto(this Bike b) => new(
        b.Id, b.UserId, b.Nickname, b.Brand, b.Model,
        b.CreatedAt, b.UpdatedAt,
        b.Parts.Select(p => p.ToDto()));

    public static PartDto ToDto(this Part p) => new(
        p.Id, p.BikeId, p.Name,
        p.ExpectedDurationKm, p.KmRidden,
        p.ProgressPercent, p.IsOverLimit,
        p.PricePaid, p.InstalledAt,
        p.Status, p.AlertSent, p.CreatedAt);
}

// ======================= DB CONTEXT =======================
public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Bike> Bikes => Set<Bike>();
    public DbSet<Ride> Rides => Set<Ride>();
    public DbSet<Part> Parts => Set<Part>();
    public DbSet<PartExchange> PartExchanges => Set<PartExchange>();
    public DbSet<MaintenanceAlert> MaintenanceAlerts => Set<MaintenanceAlert>();
    public DbSet<MaintenanceChecklist> MaintenanceChecklists => Set<MaintenanceChecklist>();

    protected override void OnModelCreating(ModelBuilder m)
    {
        m.Entity<User>()
            .HasIndex(u => u.Email).IsUnique();

        m.Entity<User>()
            .HasMany(u => u.Bikes).WithOne(b => b.User!).HasForeignKey(b => b.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        m.Entity<Bike>()
            .HasMany(b => b.Parts).WithOne(p => p.Bike).HasForeignKey(p => p.BikeId)
            .OnDelete(DeleteBehavior.Cascade);

        m.Entity<Bike>()
            .HasMany(b => b.Rides).WithOne(r => r.Bike).HasForeignKey(r => r.BikeId)
            .OnDelete(DeleteBehavior.Cascade);

        m.Entity<Bike>()
            .HasMany(b => b.MaintenanceAlerts).WithOne(a => a.Bike).HasForeignKey(a => a.BikeId)
            .OnDelete(DeleteBehavior.Cascade);

        m.Entity<Bike>()
            .HasMany(b => b.MaintenanceChecklists).WithOne(c => c.Bike).HasForeignKey(c => c.BikeId)
            .OnDelete(DeleteBehavior.Cascade);

        m.Entity<Part>()
            .HasMany<PartExchange>().WithOne(e => e.Part).HasForeignKey(e => e.PartId)
            .OnDelete(DeleteBehavior.Restrict); // RN04: preserva histórico

        m.Entity<Part>()
            .Property(p => p.Status).HasConversion<string>();

        m.Entity<Part>()
            .Property(p => p.PricePaid).HasColumnType("TEXT"); // SQLite decimal

        m.Entity<PartExchange>()
            .Property(e => e.PricePaidAtTime).HasColumnType("TEXT");
    }
}
