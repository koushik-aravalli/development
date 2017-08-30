using Microsoft.ServiceBus.Messaging;
using System;
using System.Xml.Serialization;

namespace LetsTryServicebus
{
    public class Program
    {
        public static void Main(string[] args)
        {

            var connStr = "Endpoint=sb://joblistener.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=2dbSubxtP/pGSepImH0YnLUxBXFD0XBi7+KFLV3PTn4=";
            var queueName = "listener-queue";
            var client = QueueClient.CreateFromConnectionString(connStr,queueName);

            Console.WriteLine("Build Message");
            var obj = new { name = "test", dateTime=DateTime.UtcNow.ToString("yyyy-MM-dd hh:mm:ss") };
            var msg = new BrokeredMessage(new XmlSerializer(obj.GetType()));

            msg.SessionId = "convoy";

            client.Send(msg);

            Console.WriteLine("Sent Message");
            Console.ReadLine();
        }
    }
}