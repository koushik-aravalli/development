using System;

namespace Cbsp.Foundation.Network.Api.ConfigurationOptions
{
    public class AzAdOptions
    {
        public string TenantId { get; set; }
        public string SpnObjectId { get; set; }
        private string _authorizedGroupObjectId;

        public string AuthorizedGroupObjectId
        {
            get => _authorizedGroupObjectId;
            set => Guid.TryParse(value, out Guid _authorizedGroupObjectId);
        }
    }
}