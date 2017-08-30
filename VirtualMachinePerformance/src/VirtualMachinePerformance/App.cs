using System;
using System.Diagnostics;

namespace VirtualMachinePerformance
{
    public class App
    {

        public static void Main()
        {

            string prcName = Process.GetCurrentProcess().ProcessName;
            var counter = new PerformanceCounter("Process", "Working Set - Private", prcName);
            Console.WriteLine("{0}K", counter.RawValue / 1024);
            Console.ReadLine();

        }

    }
}
