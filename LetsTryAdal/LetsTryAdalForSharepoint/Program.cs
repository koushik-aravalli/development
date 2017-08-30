using Microsoft.IdentityModel.Clients.ActiveDirectory;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;

namespace LetsTryAdalForSharepoint
{
    public class Program
    {
        static string clientId = "bbfdc332-c426-4617-8ee3-78fbfe75e2dd";
        static string clientSecret = "Aiihrai8pausa+UoMyD1172pOazIeJbTQMlUWubLao0=";
        static string tenant = "e64eed3b-130b-4001-b50d-f867ed318682";
        static string authority = "https://login.microsoftonline.com/";
        static string url = "https://mobsat.sharepoint.com";
        static string formDataUri = "/sites/site-provisioning/_api/contextinfo";

        public static void Main(string[] args)
        {

            var run = new Program();

            run.RunAsync();

            Console.ReadLine();
        }

        public async Task RunAsync()
        {
            try
            {
                var token = await GetSharePointAccessToken(url);

            //await RestClient.PostAsync(null, "/sites/site-provisioning/_api/contextinfo", "https://mobsat.sharepoint.com", data );

                using (var client = new HttpClient())
                {

                    // Overwrite with Postman for testing
                    //code = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6IlZXVkljMVdEMVRrc2JiMzAxc2FzTTVrT3E1USIsImtpZCI6IlZXVkljMVdEMVRrc2JiMzAxc2FzTTVrT3E1USJ9.eyJhdWQiOiJodHRwczovL21vYnNhdC5zaGFyZXBvaW50LmNvbSIsImlzcyI6Imh0dHBzOi8vc3RzLndpbmRvd3MubmV0L2U2NGVlZDNiLTEzMGItNDAwMS1iNTBkLWY4NjdlZDMxODY4Mi8iLCJpYXQiOjE1MDEyMzc5OTMsIm5iZiI6MTUwMTIzNzk5MywiZXhwIjoxNTAxMjQxODkzLCJhY3IiOiIxIiwiYWlvIjoiQVNRQTIvOERBQUFBUjVGVTZ4NjRpNWpGU2N2czM5UmI1UWE4NHJHS3JHcXBpZDRwcmlucExiWT0iLCJhbXIiOlsicHdkIl0sImFwcF9kaXNwbGF5bmFtZSI6IlNQTyBBdXRvbWF0aWMgU2l0ZSBQcm92aXNpb25pbmciLCJhcHBpZCI6ImJiZmRjMzMyLWM0MjYtNDYxNy04ZWUzLTc4ZmJmZTc1ZTJkZCIsImFwcGlkYWNyIjoiMSIsImZhbWlseV9uYW1lIjoiQXJhdmFsbGkiLCJnaXZlbl9uYW1lIjoiS291c2hpayIsImlwYWRkciI6IjQ2LjIzNS4xNTguMjkiLCJuYW1lIjoiQVJBVkFMTEksIEtvdXNoaWsiLCJvaWQiOiIxMTA4NTM0Yy1jOTQ3LTRlMGMtYjhkNy1mNjk4OGE2MTMwN2EiLCJvbnByZW1fc2lkIjoiUy0xLTUtMjEtMjA0NjcwMjkzNS0yMjc4MTk4OTY1LTE1NTMwMzUwNjAtMzQ0MiIsInBsYXRmIjoiMyIsInB1aWQiOiIxMDAzMDAwMDk4QzM1NUU1Iiwic2NwIjoiQWxsU2l0ZXMuV3JpdGUiLCJzdWIiOiJZNnNFbkpLSUhrNHdvRWtVb1M0UDE3X2Q2QjBna3BBY1N6SDBfRXF6LVBFIiwidGlkIjoiZTY0ZWVkM2ItMTMwYi00MDAxLWI1MGQtZjg2N2VkMzE4NjgyIiwidW5pcXVlX25hbWUiOiJLb3VzaGlrLkFyYXZhbGxpQG1hcmxpbmsuY29tIiwidXBuIjoiS291c2hpay5BcmF2YWxsaUBtYXJsaW5rLmNvbSIsInZlciI6IjEuMCJ9.XCfqfKknQkrJWeFfSdvq-i0KY5XRsEoAc6fg2L5wkP3yfYD7d5joO75CORdYvGWVtk9sXuJSw_sLJlLTMfGHOgcTf7f2UtBTX-12L_q9lOsqdXEGnZvHC2Y73xpnPGqDvSwiRR9ZxWH9d8kCSGner2vbp4gyOoJN1q6jeMivFxoZ2VeZwGYei9Cn23MPzbSVyuA3r9gSNbEnzQH59tLblDsbL8cuTgJ1-RFVDkAzjn0idg-FUQABhGmyMq51bdaKlcopx2UCyL_zEPk1Nx133283n4fTS0g-6L0g_Y3zf1nVlM9OHuZSxC0Fs17CJqGIwEl0847T0C7tM-JgoqW8kA";

                    // Form Data with XML Encoded - Not working
                    //var formDigestHeader = new Dictionary<string, string>() { { "Accept", "application/json;odata=verbose" }, { "Authorization", $"Bearer {token}" } };
                    //var formUrlEncodedContentForFormDigestValue = new FormUrlEncodedContent(formDigestHeader.ToList<KeyValuePair<string, string>>());

                    client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                    client.DefaultRequestHeaders.Authorization = AuthenticationHeaderValue.Parse($"Bearer {token}");
                    var formDigestRsp = await client.PostAsync(url + formDataUri, null);
                    var rspData = await formDigestRsp.Content.ReadAsStringAsync();
                }
            }
            catch (Exception e)
            {
                Console.WriteLine(e.InnerException);
            }
        }

        internal async Task<string> GetSharePointAccessToken(string sharePointUrl)
        {
            var appCred = new ClientCredential(clientId, clientSecret);
            var authContext = new AuthenticationContext(
                authority + tenant);

            var resource = new Uri(sharePointUrl).GetLeftPart(System.UriPartial.Authority);

            var authResult = await authContext.AcquireTokenAsync(resource, appCred);
            return authResult.AccessToken;
        }
    }
}
