using System;
using System.Runtime.Serialization;
using System.Text.Json.Serialization;
using Cbsp.Foundation.Network.Api.Models;
using Newtonsoft.Json.Converters;

namespace Cbsp.Foundation.Network.Api.Requests
{
    public class TriggerNetworkPipelineRequestBody
    {
        public VnetEnvironment Environment { get; set; }
        public Subnet Subnet { get; set; }
        public DomainNameServer DNS { get; set; }
        public Delegation Delegation { get; set; }
        public bool LoadBalancer { get; set; }
        public bool DisableJITPIM { get; set; }
        private NetworkType _networkType;
        public string NetworkType
        {
            get => _networkType.ToString();
            set => Enum.TryParse<NetworkType>(value, true, out _networkType);
        }
    }

    public enum NetworkType
    {
        [EnumMember( Value = "IaaS" )]
        IaaS,
        [EnumMember( Value = "ADB" )]
        ADB
    }
}
