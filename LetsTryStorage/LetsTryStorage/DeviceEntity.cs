using Microsoft.WindowsAzure.Storage.Table;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LetsTryStorage
{
    public class DeviceEntity : TableEntity
    {
        public DeviceEntity(string deviceType, string deviceId)
        {
            this.PartitionKey = deviceType;
            this.RowKey = deviceId;
        }

        public DeviceEntity()
        {

        }

        public string PropertyName { get; set; }
        public double LowerLimit { get; set; }
        public double UpperLimit { get; set; }

    }
}
