using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Text.RegularExpressions;
using Cbsp.Foundation.Network.Api.Requests;
using Cbsp.Foundation.Network.Api.Interfaces;

namespace Cbsp.Foundation.Network.Api.Functions
{
    public class TriggerNetworkPipeline
    {
        private readonly IAuthorizationService _authorizationService;
        private readonly IAzDevOpsPipelineService _azDevOpsPipelineService;
        private readonly ILogger<TriggerNetworkPipeline> _log;

        public TriggerNetworkPipeline(IAzDevOpsPipelineService azDevopsPipelineService,
                                      IAuthorizationService authorizationService,
                                      ILogger<TriggerNetworkPipeline> log)
        {
            _azDevOpsPipelineService = azDevopsPipelineService ?? throw new ArgumentNullException(nameof(azDevopsPipelineService));
            _authorizationService = authorizationService ?? throw new ArgumentNullException(nameof(authorizationService));
            _log = log ?? throw new ArgumentNullException(nameof(log));
        }

        [FunctionName("TriggerNetworkPipeline")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = null)] HttpRequest req)
        {
            _log.LogInformation($"Azure Function running in environment: {Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT")}");
            bool isValidateOnly = Convert.ToBoolean(req.Query["validate"]);

            var authorizedUser = await _authorizationService.GetValidatedPrincipalData(req.Headers["Authorization"]);

            if(authorizedUser?.Exception !=null && !authorizedUser.IsLocal){
                return new UnauthorizedResult();
            }

            string requestBody = Regex.Replace(await new StreamReader(req.Body).ReadToEndAsync(), @"\t|\n|\r", "");
            try
            {
                var incommingRequest = JsonConvert.DeserializeObject<HighPrivilageTrigger<TriggerNetworkPipelineRequestBody>>(requestBody);
                _log.LogInformation($"{incommingRequest.TriggerData.Environment}");

                // Search for Build Definition
                var buildDefinition = await _azDevOpsPipelineService.GetBuildDefinition();

                // Queue the build
                string triggerDataInfo = Regex.Replace(JsonConvert.SerializeObject(incommingRequest.TriggerData), @"\t|\n|\r", "");
                var buildQueue = await _azDevOpsPipelineService.PostQueueBuild(rawjson: triggerDataInfo, shouldDeploy: isValidateOnly);

                var rsp = JsonConvert.SerializeObject(new { BuildDefinition = buildDefinition, Queue = buildQueue });

                _log.LogDebug($"Queue instance information Build number: {buildQueue.BuildNumber} \n \t ==> Started at {buildQueue.QueueTime} \n \t Check Status at : {buildQueue.Url}");

                if (buildQueue.Exception == null)
                {
                    return new AcceptedResult($"/api/GetPipelineStatus/{buildQueue.Id}",null);
                }

                return new JsonResult(new { BuildDefinition = buildDefinition, BuildQueue = buildQueue });

            }
            catch (System.Exception)
            {
                return new NotFoundResult();
            }

        }
    }
}