using LetsSimulateDevice;
using Microsoft.Azure.Devices.Client;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LetSimulateDevice
{
    class Program
    {

        static DeviceClient deviceClient;
        static string iotHubUri = "Ship1.azure-devices.net";
        static string deviceKey = "SmWC1SQX6GD3uYMCwo/mcng4U3lC7MY8o2IkHGeDu/s=";

        static void Main(string[] args)
        {
            Console.WriteLine("Simulated device\n");
            deviceClient = DeviceClient.Create(iotHubUri, new DeviceAuthenticationWithRegistrySymmetricKey("myFirstDevice", deviceKey), TransportType.Http1);

            //SendDeviceToCloudMessagesAsync();
            SendDeviceUsageAsync();
            Console.ReadLine();
        }

        private static async void SendDeviceToCloudMessagesAsync()
        {
            double avgWindSpeed = 10; // m/s
            Random rand = new Random();

            while (true)
            {
                double currentWindSpeed = avgWindSpeed + rand.NextDouble() * 4 - 2;

                var telemetryDataPoint = new
                {
                    deviceId = "myFirstDevice",
                    windSpeed = currentWindSpeed
                };
                var messageString = JsonConvert.SerializeObject(telemetryDataPoint);
                var message = new Message(Encoding.ASCII.GetBytes(messageString));

                await deviceClient.SendEventAsync(message);
                Console.WriteLine("{0} > Sending message: {1}", DateTime.Now, messageString);

                Task.Delay(1000).Wait();
            }
        }

        private static async void SendDeviceUsageAsync()
        {
            VsatRepository repo = new VsatRepository();

            while (true)
            {
                var calllogs = repo.ConnectToVsatCollectionManager("SID6994-RO1 Ocean Sapphire");
                
                var messageString = JsonConvert.SerializeObject(calllogs);
                var message = new Message(Encoding.ASCII.GetBytes(messageString));

                await deviceClient.SendEventAsync(message);
                Console.WriteLine("{0} > Sending message: {1}", DateTime.Now, messageString);

                Task.Delay(60000).Wait();
            }
        }

    }
}
