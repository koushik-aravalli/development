using Cbsp.Foundation.Network.Api.Models;

namespace Cbsp.Foundation.Network.Api.Requests
{
    public class TriggerArtifactsPublishRequestBody {
        public string BranchName { get; set; }
        public string FileName { get; set; }
        public string FileContent { get; set; }
        public string FileContentType { get; set; }
        public string FilePath { get; set; }
    }
}
