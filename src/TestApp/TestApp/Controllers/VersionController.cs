using Microsoft.AspNetCore.Mvc;

namespace TestApp.Controllers;

[ApiController]
[Route("[controller]")]
public class VersionController : ControllerBase
{

    [HttpGet]
    public string? Get()
    {
        return "2.0";
    }
}