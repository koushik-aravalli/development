using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LetsSimulateDevice
{
    public class CallLog
    {
        public CallLog()
        {

        }

        public string SubscriberId { get; set; }

        public double Downloaded { get; set; }
        public double Uploaded { get; set; }
        public DateTime TimeStamp { get; set; }
    }
}
