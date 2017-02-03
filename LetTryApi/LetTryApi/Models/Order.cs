using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace LetTryApi.Models
{
    public class Order
    {
        public Order()
        {

        }

        [JsonProperty(PropertyName = "id")]
        public string Id { get; set; }

        public string Status { get; set; }

        public MessageTypes.Message Message {get; set;}

        public override string ToString()
        {
            return JsonConvert.SerializeObject(this);
        }
    }
}