#r "Microsoft.ServiceBus"
#r "Newtonsoft.Json"

using System;
using System.Threading.Tasks;
using Microsoft.ApplicationInsights;
using Newtonsoft.Json;
using Microsoft.ServiceBus.Messaging;

public static void Run(BrokeredMessage inSbMsg, TraceWriter log)
{
    var appInsights = GetTelemetryClient();

    var msgStream = inSbMsg.GetBody<Stream>();
    StreamReader sr = new StreamReader(msgStream);

    string obj = sr.ReadToEnd();
    log.Info($"Object: {obj}");

    dynamic eventObj = JsonConvert.DeserializeObject(obj);

    List<Dictionary<string, string>> list = eventObj.Properties;
    string appName = eventObj.ApplicationName;
    //track an event
    appInsights.TrackEvent(appName, list[0]);
    // track a numeric value
    //appInsights.TrackMetric("Time Metric", DateTime.Now.Ticks);
    // track an exception
    //appInsights.TrackException(new Exception($"Random exception {DateTime.Now}"));

    // send data to azure
    appInsights.Flush();
}

private static TelemetryClient GetTelemetryClient()
{
    var telemetryClient = new TelemetryClient();
    telemetryClient.InstrumentationKey = "c330d56f-5262-4fe9-aa0c-0521af06fe91";
    return telemetryClient;
}