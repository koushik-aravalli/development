using System;
using System.Net.Http.Headers;
using Cbsp.Foundation.Network.Api.ConfigurationOptions;
using Cbsp.Foundation.Network.Api.Interfaces;
using Cbsp.Foundation.Network.Api.Responses;
using Cbsp.Foundation.Network.Api.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.Azure.Functions.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;

[assembly: FunctionsStartup(typeof(Cbsp.Foundation.Network.Api.Startup))]

namespace Cbsp.Foundation.Network.Api
{
    public class Startup : FunctionsStartup
    {
        public override void Configure(IFunctionsHostBuilder builder)
        {
            var environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT");

            builder.Services.AddOptions<AzDevOpsOptions>()
                                                    .Configure<IConfiguration>((settings, configuration) =>
                                                                            {
                                                                                configuration.GetSection("AzDevopsOptions").Bind(settings);
                                                                            });

            builder.Services.AddOptions<AzAdOptions>()
                                                    .Configure<IConfiguration>((settings, configuration) =>
                                                                            {
                                                                                configuration.GetSection("AzAdOptions").Bind(settings);
                                                                            });

            builder.Services.AddOptions<AzKeyVaultOptions>()
                                                    .Configure<IConfiguration>((settings, configuration) =>
                                                                            {
                                                                                configuration.GetSection("AzKeyVaultOptions").Bind(settings);
                                                                            });

            builder.Services.AddSingleton<IHttpContextAccessor, HttpContextAccessor>();

            builder.Services.AddMvcCore().AddNewtonsoftJson();

            var monitor = builder.Services.BuildServiceProvider().GetService<IOptionsMonitor<AzDevOpsOptions>>();

            string devopsPersonalAccessToken, devopsRepoPersonalAccessToken = "";
            PrincipalDataResponse principalDataResponse;
            if (!environment.Equals("local"))
            {
                devopsPersonalAccessToken = (builder.Services.BuildServiceProvider()
                                                            .GetService<IOptionsMonitor<AzKeyVaultOptions>>()).CurrentValue.PatSecret;
                devopsRepoPersonalAccessToken = (builder.Services.BuildServiceProvider()
                                                            .GetService<IOptionsMonitor<AzKeyVaultOptions>>()).CurrentValue.RepoPatSecret;
                principalDataResponse = new PrincipalDataResponse
                {
                    ObjectId = (builder.Services.BuildServiceProvider()
                                                            .GetService<IOptionsMonitor<AzAdOptions>>()).CurrentValue.SpnObjectId,
                    TenantId = (builder.Services.BuildServiceProvider()
                                                            .GetService<IOptionsMonitor<AzAdOptions>>()).CurrentValue.TenantId
                };
            }
            else
            {
                devopsPersonalAccessToken = devopsRepoPersonalAccessToken = monitor.CurrentValue.PersonalAccessToken;
                principalDataResponse = new PrincipalDataResponse()
                {  
                    IsLocal = true
                };
            }

            builder.Services.AddTransient<IAuthorizationService, AuthorizationService>().AddHttpClient();

            builder.Services.AddHttpClient<IAzDevOpsPipelineService, AzDevOpsPipelineService>(c =>
            {
                c.DefaultRequestHeaders.Accept.Add(new System.Net.Http.Headers.MediaTypeWithQualityHeaderValue("application/json"));
                c.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic", Convert.ToBase64String(System.Text.ASCIIEncoding.ASCII.GetBytes(string.Format("{0}:{1}", "", devopsPersonalAccessToken))));
            });

            builder.Services.AddHttpClient<IAzDevOpsRepoService, AzDevOpsRepoService>(c =>
            {
                c.DefaultRequestHeaders.Accept.Add(new System.Net.Http.Headers.MediaTypeWithQualityHeaderValue("application/json"));
                c.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic", Convert.ToBase64String(System.Text.ASCIIEncoding.ASCII.GetBytes(string.Format("{0}:{1}", "", devopsRepoPersonalAccessToken))));
            });
        }
    }
}