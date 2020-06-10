using System;
using System.Threading.Tasks;
using Newtonsoft.Json;
using System.Net.Http;
using System.Net.Http.Headers;
using Cbsp.Foundation.Network.Api.Requests;
using Cbsp.Foundation.Network.Api.Responses;
using Cbsp.Foundation.Network.Api.Interfaces;
using Microsoft.Extensions.Options;
using Cbsp.Foundation.Network.Api.ConfigurationOptions;
using Cbsp.Foundation.Network.Api.Models;
using Microsoft.AspNetCore.Http;
using System.Linq;
using System.Text.RegularExpressions;
using Microsoft.Extensions.Logging;

namespace Cbsp.Foundation.Network.Api.Services
{

    /// <summary>
    /// Class
    /// <c>AzDevOpsService</c> Entry point for the service
    /// </summary>
    public partial class AzDevOpsRepoService : IAzDevOpsRepoService
    {
        private readonly ILogger<AzDevOpsRepoService> _log;
        private readonly IOptions<AzDevOpsOptions> _azDevOpsOptions;
        private readonly IOptions<AzKeyVaultOptions> _azKvOptions;
        private readonly HttpClient _client;
        private readonly IHttpContextAccessor _httpContextAccessor;
        public AzDevOpsRepoService(HttpClient httpClient,
                                   IOptions<AzDevOpsOptions> devopsOptions,
                                   IHttpContextAccessor httpContextAccessor,
                                   IOptions<AzKeyVaultOptions> azKvOptions,
                                   ILogger<AzDevOpsRepoService> log)
        {
            _log = log ?? throw new ArgumentNullException(nameof(log));
            _client = httpClient ?? throw new ArgumentNullException(nameof(httpClient));
            _azDevOpsOptions = devopsOptions ?? throw new ArgumentNullException((nameof(devopsOptions)));
            _azKvOptions = azKvOptions ?? throw new ArgumentNullException((nameof(azKvOptions)));
            _httpContextAccessor = httpContextAccessor ?? throw new ArgumentException((nameof(httpContextAccessor)));
        }

        public async Task<Repository> GetRepository(string repositoryName)
        {

            var reposUrl = $"https://dev.azure.com/{_azDevOpsOptions.Value.Organization}/{_azDevOpsOptions.Value.Project}/_apis/git/repositories?api-version=5.1";

            using (HttpResponseMessage response = await _client.GetAsync(reposUrl))
            {
                response.EnsureSuccessStatusCode();
                string responseBody = await response.Content.ReadAsStringAsync();
                dynamic rsp = JsonConvert.DeserializeObject(responseBody);
                var repository = new Repository
                {
                    Id = rsp.value[0].id
                };

                return repository;
            }
        }

        public async Task<Branch> GetBranch(string repositoryId, string branchName)
        {
            var getMasterBranchUrl = $"https://dev.azure.com/{_azDevOpsOptions.Value.Organization}/{_azDevOpsOptions.Value.Project}/_apis/git/repositories/{repositoryId}/refs?filter=heads/{branchName}&api-version=5.1";

            using (HttpResponseMessage response = await _client.GetAsync(getMasterBranchUrl))
            {
                response.EnsureSuccessStatusCode();
                string responseBody = await response.Content.ReadAsStringAsync();
                dynamic rsp = JsonConvert.DeserializeObject(responseBody);
                var branch = new Branch
                {
                    Id = rsp.value[0].objectId
                };
                return branch;
            }
        }

        public async Task<Branch> PostNewBranch(NewBranchRequest newBranchRequest)
        {
            var pushToNewBranchUrl = $"https://dev.azure.com/{_azDevOpsOptions.Value.Organization}/{_azDevOpsOptions.Value.Project}/_apis/git/repositories/{newBranchRequest.RepositoryId}/pushes?api-version=5.1";
            var requestBody = new AzDevopsGit
            {
                RefUpdates = new[]{new RefUpdate{
                        Name = $"refs/heads/{newBranchRequest.Name}",
                        OldObjectId = newBranchRequest.BranchId
                    }},
                Commits = new[]{new Commit{
                        Comment = newBranchRequest.Comment,
                        Changes = new [] {new Change{
                            ChangeType = "add",
                            Item = new Item{
                                Path = newBranchRequest.FileFullyQualifiedName
                            },
                            NewContent = new NewContent{
                                Content = $"{newBranchRequest.FileContent}",
                                ContentType = newBranchRequest.ContentType
                            }
                        }}
                    }}
            };

            string reqBody = JsonConvert.SerializeObject(requestBody);
            _log.LogInformation($"Invoking API: {pushToNewBranchUrl} with body {reqBody}");

            try
            {
                using (HttpResponseMessage response = await _client.PostAsJsonAsync(pushToNewBranchUrl, requestBody))
                {
                    if (response.StatusCode == System.Net.HttpStatusCode.Conflict)
                    {
                        _log.LogWarning("Conflict during New branch creation");
                        return new Branch
                        {
                            Name = newBranchRequest.Name,
                            Success = true
                        };
                    }

                    response.EnsureSuccessStatusCode();
                    string responseBody = await response.Content.ReadAsStringAsync();
                    _log.LogInformation($"Response Content: {responseBody}");
                    dynamic rsp = JsonConvert.DeserializeObject(responseBody);
                    var newBranch = new Branch
                    {
                        Name = newBranchRequest.Name,
                        FirstCommitId = rsp.commits[0].commitId,
                        Success = true
                    };
                    return newBranch;
                }
            }
            catch (Exception ex)
            {
                _log.LogError($"Branch creation failed {ex.InnerException}");
                return new Branch();
            }

        }

        public async Task<PullRequest> PostNewPullRequest(NewPullRequest newPullRequest)
        {
            var createNewPullRequesthUrl = $"https://dev.azure.com/{_azDevOpsOptions.Value.Organization}/{_azDevOpsOptions.Value.Project}/_apis/git/repositories/{newPullRequest.RepositoryId}/pullrequests?api-version=5.1";
            var requestBody = new
            {
                sourceRefName = $"refs/heads/{newPullRequest.SourceBranchName}",
                targetRefName = $"refs/heads/{newPullRequest.TargetBranchName}",
                title = $"Network SelfService - {newPullRequest.SourceBranchName}",
                description = "Adding ReadMe File"
            };

            string reqBody = JsonConvert.SerializeObject(requestBody);
            _log.LogInformation($"Invoking API: {createNewPullRequesthUrl} with body {reqBody}");

            using (HttpResponseMessage response = await _client.PostAsJsonAsync(createNewPullRequesthUrl, requestBody))
            {
                response.EnsureSuccessStatusCode();
                string responseBody = await response.Content.ReadAsStringAsync();
                _log.LogInformation($"Response Content: {responseBody}");
                var rsp = JsonConvert.DeserializeObject<PullRequest>(responseBody);

                return rsp;
            }
        }

    }

}
