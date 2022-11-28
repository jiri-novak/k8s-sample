using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.OpenApi.Models;
using TestApp;

var builder = WebApplication.CreateBuilder(args);

builder.Configuration.AddKeyPerFile(directoryPath: "/mnt/keyvault-secrets", optional: true, reloadOnChange: true);
builder.Services.Configure<AppConfig>(builder.Configuration);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHealthChecks();
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.All;
    options.ForwardedHostHeaderName = "X-ORIGINAL-HOST";
    options.ForwardLimit = 2;
    options.KnownProxies.Clear();
    options.KnownNetworks.Clear();
});

var app = builder.Build();

var pathBase = Environment.GetEnvironmentVariable("ASPNETCORE_PATHBASE") ?? "/";

app.Use((context, next) =>
{
    context.Request.PathBase = new PathString(pathBase);
    return next.Invoke();
});
app.UseForwardedHeaders();
app.UseSwagger(c =>
{
    c.RouteTemplate = "swagger/{documentName}/swagger.json";
    c.PreSerializeFilters.Add((swaggerDoc, httpReq) =>
    {
        swaggerDoc.Servers = new[] {
            new OpenApiServer {
                Url = $"{httpReq.Scheme}://{httpReq.Host.Value}{pathBase}",
                Description = "Default"
            }
        };
    });
});
app.UseSwaggerUI();
app.MapHealthChecks("/health", new HealthCheckOptions { Predicate = _ => true });
app.MapControllers();

app.Run();
