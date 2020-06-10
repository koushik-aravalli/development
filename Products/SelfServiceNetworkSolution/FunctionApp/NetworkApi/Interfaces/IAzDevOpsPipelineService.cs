using System.Threading.Tasks;
using Cbsp.Foundation.Network.Api.Models;
using Cbsp.Foundation.Network.Api.Requests;
using Cbsp.Foundation.Network.Api.Responses;

namespace Cbsp.Foundation.Network.Api.Interfaces
{
    public interface IAzDevOpsPipelineService
    {
        Task<BuildDefinitionResponse> GetBuildDefinition();
        Task<PipelineQueueResponse> PostQueueBuild(string rawjson, bool shouldDeploy);
        Task<BuildDefinitionResponse> GetBuildQueueStatus(string buildId);
    }

}
