using Cbsp.Foundation.Network.Api.Models;

namespace Cbsp.Foundation.Network.Api.Requests
{
    public class NewBranchRequest {
        public string Name{ get; set; }
        public string RepositoryId { get; set; }
        public string BranchId { get; set; }
        public string FileFullyQualifiedName { get; set; }
        public string FileContent { get; set; }
        public string ContentType {get; set;}
        public string Comment {get; set;}
    }
}