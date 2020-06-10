namespace Cbsp.Foundation.Network.Api.Models
{
    public class PullRequest
    {
        public string PullRequestId { get; set; }
        public string Status { get; set; }
        public string SourceBranchName { get; set; }
        public string TargetBranchName { get; set; }
        public string RepositoryId { get; set; }
    }
}