using System.Net;
using Newtonsoft.Json;

namespace Cbsp.Foundation.Network.Api.Models
{
    public class TriggerException
    {
        public HttpStatusCode StatusCode { get; set; }
        public string Message { get; set; }

        public override string ToString()
        {
            return JsonConvert.SerializeObject(this);
        }
    }
}