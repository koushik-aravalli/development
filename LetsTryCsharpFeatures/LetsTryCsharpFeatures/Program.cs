using System;
using System.Collections.Generic;
using System.Linq;

namespace LetsTryCsharpFeatures
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var noOfChocWithEmps = new List<int>() { 1, 2, 3 };
            int noOfNewChocs = 5;
            // Create Square matrix with size of no of emps
            // Assign input as first row, input can already have same 
            var assignedChoclatesMatrix = new int[noOfChocWithEmps.Count, noOfChocWithEmps.Count];

            // Loop over all to add 1 except one
            for (int row = 0; row < noOfChocWithEmps.Count(); row++)
            {
                for (int col = 0; col < noOfChocWithEmps.Count(); col++)
                {
                    if(col == row)
                    {
                        assignedChoclatesMatrix[row, col] = noOfChocWithEmps[col];
                    }
                    else
                    {
                        assignedChoclatesMatrix[row, col] = noOfChocWithEmps[col] + noOfNewChocs;
                    }
                }
            }
            //string input = "name";
            //var x = new GetEventResponse(Prefix);
            //Console.WriteLine(x(input));
            //x = new GetEventResponse(Suffix);
            //Console.WriteLine(x(input));
            Console.ReadLine();
        }

        public delegate string GetEventResponse(string input);

        public static string Suffix(string input)
        {
            return input + "-Suffix";
        }
        public static string Prefix(string input)
        {
            return "Prefix-"+input;
        }
    }
}