using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.AspNetCore.Mvc;

namespace LetsTryAppInsights.Controllers
{
    [Route("api/[controller]")]
    public class ValuesController : Controller
    {
        public TelemetryClient _telemetry = new TelemetryClient(TelemetryConfiguration.Active);

        public ValuesController()
        {
            _telemetry.InstrumentationKey = "afd1ae9b-0d73-4ceb-b25f-9a9c0a00dc60";
        }
        // GET api/values
        [HttpGet]
        public IEnumerable<string> Get()
        {
            _telemetry.TrackEvent($"Now into : {HttpContext.Request.Path}");

            return new string[] { "value1", "value2" };
        }

        // GET api/values/5
        [HttpGet("{id}")]
        public string Get(int id)
        {
            _telemetry.TrackEvent($"Now into : {HttpContext.Request.Path}");
            if (id == 1)
                return "value";
            else
            {
                var e = new Exception("some stacktrace");
                _telemetry.TrackException(e, new Dictionary<string, string>() {{"Id", id.ToString()}});
                throw e;
            }
        }

        // POST api/values
        [HttpPost]
        public void Post([FromBody]string value)
        {
        }

        // PUT api/values/5
        [HttpPut("{id}")]
        public void Put(int id, [FromBody]string value)
        {
        }

        // DELETE api/values/5
        [HttpDelete("{id}")]
        public void Delete(int id)
        {
        }
    }
}
