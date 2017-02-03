using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using Swashbuckle.Swagger.Annotations;
using LetsTryDocDbApi.Dtos;
using LetsTryDocDbApi.BusinessLogic.Interface;

namespace LetsTryDocDbApi.Controllers
{
    public class OrdersController : ApiController
    {

        IDocumentDbRepository DocumentDbRepo { get; set; }

        public OrdersController(IDocumentDbRepository repo)
        {
            DocumentDbRepo = repo;
        }

        // POST api/values
        [SwaggerOperation("Create")]
        [SwaggerResponse(HttpStatusCode.Created)]
        public void Post([FromBody]OrderDto order)
        {

        }

        // PUT api/values/5
        [SwaggerOperation("Update")]
        [SwaggerResponse(HttpStatusCode.OK)]
        [SwaggerResponse(HttpStatusCode.NotFound)]
        public void Put(int id, [FromBody]string value)
        {

        }

        // DELETE api/values/5
        [SwaggerOperation("Delete")]
        [SwaggerResponse(HttpStatusCode.OK)]
        [SwaggerResponse(HttpStatusCode.NotFound)]
        public void Delete(int id)
        {

        }
    }
}
