using Cbsp.Foundation.Network.Api.ConfigurationOptions;
using Cbsp.Foundation.Network.Api.Interfaces;
using Cbsp.Foundation.Network.Api.Models;
using Cbsp.Foundation.Network.Api.Responses;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Newtonsoft.Json;
using System;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Claims;
using System.Security.Principal;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace Cbsp.Foundation.Network.Api.Services
{
    public class AuthorizationService : IAuthorizationService
    {
        private readonly ILogger<AuthorizationService> _log;
        private readonly IOptions<AzAdOptions> _azAdOptions;
        private readonly ClaimsPrincipal _principal;
        private readonly IHttpContextAccessor _httpContextAccessor;
        private string AuthorizedGroupObjectId { get; set; }
        private readonly HttpClient _client;
        public AuthorizationService(
            ILogger<AuthorizationService> log, IOptions<AzAdOptions> adOptions, IHttpContextAccessor httpContextAccessor, HttpClient httpClient)
        {
            _log = log ?? throw new ArgumentNullException(nameof(log));
            _azAdOptions = adOptions ?? throw new ArgumentNullException(nameof(adOptions));
            AuthorizedGroupObjectId = _azAdOptions.Value.AuthorizedGroupObjectId;
            _client = httpClient ?? throw new ArgumentNullException(nameof(httpClient));
            _httpContextAccessor = httpContextAccessor ?? throw new ArgumentException((nameof(httpContextAccessor)));
            _principal = _httpContextAccessor?.HttpContext?.User;
        }

        public async Task<bool> IsAuthroziedUser(string authorizationHeader)
        {
            var principalData = await GetValidatedPrincipalData(authorizationHeader);

            return principalData != null ? true : false;
        }

        public async Task<PrincipalDataResponse> GetValidatedPrincipalData(string authorizationHeader)
        {
            if (String.IsNullOrEmpty(authorizationHeader) || !authorizationHeader.StartsWith("Bearer "))
            {
                return AuthorizationError("Bearer Token not provided or malformed");
            }

            if (!_principal.Identity.IsAuthenticated)
            {
                var exceptionMsg = $"Denying unauthenticated request.";
                return AuthorizationError(exceptionMsg);
            }

            PrincipalDataResponse principalDataRsp = GetPrincipalData();
            var accessToken = authorizationHeader.Replace("Bearer ", "");

            if (String.IsNullOrEmpty(accessToken))
            {
                var exceptionMsg = $"Missing authorization header although principal has been determined to have object id '{principalDataRsp.ObjectId}'.";
                return AuthorizationError(exceptionMsg);
            }

            _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

            await GetAadObject(principalDataRsp);

            // Authorization based on group
            if (principalDataRsp.Exception != null && AuthorizedGroupObjectId != null)
            {
                // Retrieve group
                string aadGroupUrl = $"https://graph.windows.net/{principalDataRsp.TenantId}/groups/{AuthorizedGroupObjectId}?api-version=1.6";
                HttpResponseMessage aadGroupResponse = await _client.GetAsync(aadGroupUrl);
                string groupContent = await aadGroupResponse.Content.ReadAsStringAsync();
                if (principalDataRsp.Exception != null)
                {
                    var excpMsg = $"Cannot authorize based on group with object id '{AuthorizedGroupObjectId}'. Error response on call to '{aadGroupUrl}'. Statuscode: '{aadGroupResponse.StatusCode}'. Response: {groupContent}";
                    _log.LogError(excpMsg);
                    principalDataRsp.Exception.Message += excpMsg;
                    return principalDataRsp;
                }

                dynamic aadGroup = JsonConvert.DeserializeObject(groupContent);
                _log.LogInformation($"Found displayname '{aadGroup.DisplayName}' for group with object id '{aadGroup.ObjectId}'");

                await GetAadObjectGroupMembership(principalDataRsp);
            }

            return principalDataRsp;
        }

        private PrincipalDataResponse AuthorizationError(string exceptionMsg)
        {
            _log.LogError(exceptionMsg);

            var principalDataRsp = new PrincipalDataResponse
            {
                Exception = new Models.TriggerException
                {
                    StatusCode = HttpStatusCode.Unauthorized,
                    Message = exceptionMsg
                }
            };
            return principalDataRsp;
        }

        private PrincipalDataResponse GetPrincipalData()
        {
            Claim objectId = _principal.FindFirst("http://schemas.microsoft.com/identity/claims/objectidentifier");
            Claim tenantId = _principal.FindFirst("http://schemas.microsoft.com/identity/claims/tenantid");

            PrincipalDataResponse principalDataRsp;
            if (objectId == null || tenantId == null)
            {
                bool isLocalEnvironment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT").Equals("local") ? true : false;

                if (isLocalEnvironment && _principal.Identity.AuthenticationType == "WebJobsAuthLevel")
                {
                    WindowsIdentity processIdentity = WindowsIdentity.GetCurrent();
                    string name = processIdentity.Name;

                    Claim authLevelClaim = _principal.FindFirst("http://schemas.microsoft.com/2017/07/functions/claims/authlevel");
                    principalDataRsp = new PrincipalDataResponse
                    {
                        IsLocal = true,
                        ObjectId = _azAdOptions.Value.SpnObjectId,
                        TenantId = _azAdOptions.Value.TenantId,
                        DisplayName = $"Development by '{name}' with auth level '{authLevelClaim.Value}'"
                    };
                    _log.LogInformation($"Local run: {principalDataRsp.DisplayName}");

                    return principalDataRsp;
                }
                else
                {
                    return null;
                }
            }
            else
            {
                principalDataRsp = new PrincipalDataResponse
                {
                    ObjectId = objectId.Value,
                    TenantId = tenantId.Value,
                    DisplayName = _principal.Identity.Name ?? "no display name"
                };
            }

            return principalDataRsp;
        }

        private async Task GetAadObject(PrincipalDataResponse principalDataRsp)
        {
            string aadObjectUrl = $"https://graph.windows.net/{principalDataRsp.TenantId}/directoryObjects/{principalDataRsp.ObjectId}?api-version=1.6";
            try
            {
                using (var aadObjectResponse = await _client.GetAsync(aadObjectUrl))
                {
                    string objectContent = await aadObjectResponse.Content.ReadAsStringAsync();
                    aadObjectResponse.EnsureSuccessStatusCode();

                    dynamic aadObject = JsonConvert.DeserializeObject(objectContent);
                    if (aadObject.ObjectType == "ServicePrincipal")
                    {
                        principalDataRsp.DisplayName = $"{aadObject.DisplayName} ({aadObject.AppId})";
                    }

                    _log.LogInformation($"Called by '{principalDataRsp.DisplayName}' with object id '{principalDataRsp.ObjectId}' and tenant id '{principalDataRsp.TenantId}'.");

                }
            }
            catch (HttpRequestException exp)
            {
                var exceptionMsg = $"Error response on call to '{aadObjectUrl}'. Statuscode: '{exp.Data["StatusCode"]}'. Response: {exp.Message}";
                principalDataRsp.Exception = (AuthorizationError(exceptionMsg)).Exception;
            }

            return;
        }

        private async Task GetAadObjectGroupMembership(PrincipalDataResponse principalDataRsp)
        {
            // Determine groups that the service principal is a member of
            string memberGroupsUrl = $"https://graph.windows.net/{principalDataRsp.TenantId}/directoryObjects/{principalDataRsp.ObjectId}/getMemberGroups?api-version=1.6";
            HttpContent postContent = new StringContent("{ \"securityEnabledOnly\": true }", Encoding.UTF8, "application/json");
            try
            {
                using (var membersGroupResponse = await _client.PostAsync(memberGroupsUrl, postContent))
                {
                    membersGroupResponse.EnsureSuccessStatusCode();

                    string membersGroupContent = await membersGroupResponse.Content.ReadAsStringAsync();

                    JsonDocument json = JsonDocument.Parse(membersGroupContent);
                    JsonElement valueElement = json.RootElement.GetProperty("value");
                    bool authorizedGroupFound = false;
                    int numberOfGroups = valueElement.GetArrayLength();
                    _log.LogInformation($"Found {numberOfGroups} groups of which the service principal '{principalDataRsp.DisplayName}' is a member.");

                    foreach (JsonElement arrayElement in valueElement.EnumerateArray())
                    {
                        if (arrayElement.GetString() == AuthorizedGroupObjectId)
                        {
                            authorizedGroupFound = true;
                            break;
                        }
                    }

                    if (!authorizedGroupFound)
                    {
                        _log.LogError($"Unauthorized. The service principal '{principalDataRsp.DisplayName}' is not a member of the {AuthorizedGroupObjectId} group.");
                    }
                    else
                    {
                        _log.LogInformation($"Authorized. The service principal '{principalDataRsp.DisplayName}' is a member of the {AuthorizedGroupObjectId} group.");
                    }
                }
            }
            catch (HttpRequestException exp)
            {
                var exceptionMsg = $"Error response on call to '{memberGroupsUrl}'. Statuscode: '{exp.Data["StatusCode"]}'. Response: {exp.Message}";
                principalDataRsp.Exception = (AuthorizationError(exceptionMsg)).Exception;
            }

            return;
        }
    }
}