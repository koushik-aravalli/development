using Cbsp.Foundation.Network.Api.Models;

namespace Cbsp.Foundation.Network.Api.Requests
{
    public class NewPullRequest
    {
        public string Status { get; set; }
        public string SourceBranchName { get; set; }
        public string TargetBranchName { get; set; }
        public string RepositoryId { get; set; }
    }
}