using Cbsp.Foundation.Network.Api.Models;

namespace  Cbsp.Foundation.Network.Api.Responses
{
    public class PrincipalDataResponse{
        public string ObjectId { get; set; }
        public string TenantId { get; set; }
        public string DisplayName { get; set; }
        public bool IsLocal { get; set; }
        public TriggerException Exception { get; set; }

    }
}