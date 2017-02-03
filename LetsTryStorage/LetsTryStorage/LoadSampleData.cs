using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LetsTryStorage
{
    public class LoadSampleData
    {
        public static List<DeviceEntity> FromSampleDataFile()
        {
            string streamData="";
            StreamReader r = new StreamReader("..\\..\\SampleData.json");
            streamData = r.ReadToEnd();
            List<DeviceEntity> devices = JsonConvert.DeserializeObject<List<DeviceEntity>>(streamData);
            return devices;
        }
    }
}
