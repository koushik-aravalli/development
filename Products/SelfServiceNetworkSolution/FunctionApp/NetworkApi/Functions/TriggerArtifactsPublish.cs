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
using Cbsp.Foundation.Network.Api.ConfigurationOptions;
using Microsoft.Extensions.Options;
using Cbsp.Foundation.Network.Api.Models;

namespace Cbsp.Foundation.Network.Api.Functions
{
    public class TriggerArtifactsPublish
    {
        private readonly IAzDevOpsRepoService _azDevOpsRepoService;
        private readonly ILogger<TriggerArtifactsPublish> _log;
        private readonly IOptions<AzDevOpsOptions> _azDevopsOptions;
        private string RepositoryName { get; set; }
        private string HeadBranchName { get; set; }

        public TriggerArtifactsPublish(IAzDevOpsRepoService azDevOpsRepoService, ILogger<TriggerArtifactsPublish> log, IOptions<AzDevOpsOptions> azDevopsOptions)
        {
            _azDevOpsRepoService = azDevOpsRepoService ?? throw new ArgumentNullException(nameof(azDevOpsRepoService));
            _log = log ?? throw new ArgumentNullException(nameof(log));
            _azDevopsOptions = azDevopsOptions ?? throw new ArgumentNullException(nameof(azDevopsOptions));
            RepositoryName = _azDevopsOptions.Value.RepositoryName;
            HeadBranchName = _azDevopsOptions.Value.SourceBranch;
        }

        [FunctionName("TriggerArtifactsPublish")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = null)] HttpRequest req)
        {
            _log.LogInformation($"Azure Function running in environment: {Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT")}");

            string requestBody = Regex.Replace(await new StreamReader(req.Body).ReadToEndAsync(), @"\t|\n|\r", "");
            try
            {
                var incommingRequest = JsonConvert.DeserializeObject<TriggerArtifactsPublishRequestBody>(requestBody);
                _log.LogInformation($"Commit File {incommingRequest.FileName} to the new branch");

                var repository = await _azDevOpsRepoService.GetRepository(RepositoryName);
                var branch = await _azDevOpsRepoService.GetBranch(repository.Id, HeadBranchName);

                var newBranchRequest = new NewBranchRequest
                {
                    RepositoryId = repository.Id,
                    BranchId = branch.Id,
                    Name = incommingRequest.BranchName,
                    FileFullyQualifiedName = incommingRequest.FilePath,
                    FileContent = incommingRequest.FileContent,
                    ContentType = incommingRequest.FileContentType,
                    Comment = $"Initial commit File {incommingRequest.FileName} commited into branch {incommingRequest.BranchName}.",
                };

                var newBranch = await _azDevOpsRepoService.PostNewBranch(newBranchRequest);

                if(newBranch.Success){
                    var newPr = new NewPullRequest(){
                        RepositoryId = repository.Id,
                        SourceBranchName = newBranch.Name,
                        TargetBranchName = HeadBranchName
                    };
                    var pr = await _azDevOpsRepoService.PostNewPullRequest(newPr);
                }

                return new OkResult();
            }
            catch (Exception ex)
            {
                _log.LogError(ex.Message);
                return new BadRequestObjectResult(ex.Message);
            }
        }
    }
}