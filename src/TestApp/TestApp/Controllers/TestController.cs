using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace TestApp.Controllers;

[ApiController]
[Route("[controller]")]
public class TestController : ControllerBase
{
    private readonly IOptionsSnapshot<AppConfig> _options;

    public TestController(IOptionsSnapshot<AppConfig> options)
    {
        _options = options;
    }

    [HttpGet]
    public string? Get()
    {
        return _options.Value.Sample;
    }
}