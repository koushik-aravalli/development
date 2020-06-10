using System.Threading.Tasks;
using Cbsp.Foundation.Network.Api.Models;
using Cbsp.Foundation.Network.Api.Requests;
using Cbsp.Foundation.Network.Api.Responses;

namespace Cbsp.Foundation.Network.Api.Interfaces
{
    public interface IAzDevOpsRepoService
    {
        Task<Branch> PostNewBranch(NewBranchRequest newBranchRequest);
        Task<Branch> GetBranch(string repositoryId, string branchName);
        Task<Repository> GetRepository(string repositoryName);
        Task<PullRequest> PostNewPullRequest(NewPullRequest newPullRequest);
    }
}
