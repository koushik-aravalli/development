using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace LetTryApi.MessageTypes
{
    public class UpdateXchangeBoxCredit
    {
        public string Action { get; set; }
        public string BoxHardwareId { get; set; }
        public string BoxSerialNumber { get; set; }
        public string CompanyContext { get; set; }
        public string Type { get; set; }
        public string userCompanyName { get; set; }
        public List<Modification> Modifications { get; set; }
        
    }

    public class Modification
    {
        public double Credit { get; set; }
        public double UserId { get; set; }
    }  
}