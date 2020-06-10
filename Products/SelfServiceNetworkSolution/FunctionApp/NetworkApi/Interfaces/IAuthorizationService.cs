using System.Threading.Tasks;
using Cbsp.Foundation.Network.Api.Models;
using Cbsp.Foundation.Network.Api.Responses;
using Microsoft.AspNetCore.Http;

namespace Cbsp.Foundation.Network.Api.Interfaces
{
    public interface IAuthorizationService
    {
        Task<bool> IsAuthroziedUser(string accessToken);

        Task<PrincipalDataResponse> GetValidatedPrincipalData(string accessToken);
    }

}
