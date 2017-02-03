using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using Swashbuckle.Swagger.Annotations;
using System.Threading.Tasks;
using LetTryApi.Contracts;
using LetTryApi.Models;

namespace LetTryApi.Controllers
{
    public class OrderController : ApiController
    {

        public IDocumentDbRepo _documentDbRepo { get; set; }

        // GET api/values
        [SwaggerOperation("GetAll")]
        public IEnumerable<string> Get()
        {
            return new string[] { "value1", "value2" };
        }

        // GET api/values/5
        [SwaggerOperation("GetById")]
        [SwaggerResponse(HttpStatusCode.OK)]
        [SwaggerResponse(HttpStatusCode.NotFound)]
        [HttpGet]
        public string Get(int id)
        {
            return "value";
        }

        // POST api/values
        [SwaggerOperation("Create")]
        [SwaggerResponse(HttpStatusCode.Created)]
        [HttpPost]
        public async Task<IHttpActionResult> Post([FromBody]Order order)
        {
            Order result = await _documentDbRepo.CreateOrder(order);
            return Ok(result);
        }

        // PUT api/values/5
        [SwaggerOperation("Update")]
        [SwaggerResponse(HttpStatusCode.OK)]
        [SwaggerResponse(HttpStatusCode.NotFound)]
        [HttpPut]
        public async Task<IHttpActionResult> Put(int id, [FromBody]Order updatedOrder)
        {
            Order currentOrder = _documentDbRepo.GetOrder(updatedOrder.Id);
            Order result = await _documentDbRepo.ReplaceOrderDocument(currentOrder.Id, updatedOrder);
            return Ok(result);
        }

        // DELETE api/values/5
        [SwaggerOperation("Delete")]
        [SwaggerResponse(HttpStatusCode.OK)]
        [SwaggerResponse(HttpStatusCode.NotFound)]
        [HttpDelete]
        public async Task<IHttpActionResult> Delete(string id)
        {
            await _documentDbRepo.DeleteOrder(id);
            return Ok();
        }
    }

}
