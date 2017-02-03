using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Microsoft.Azure; // Namespace for CloudConfigurationManager
using Microsoft.WindowsAzure.Storage; // Namespace for CloudStorageAccount
using Microsoft.WindowsAzure.Storage.Table; // Namespace for Table storage types
using Microsoft.WindowsAzure.Storage.Blob;
using System.IO;
using System.Xml;
using System.Net.Http;

namespace LetsTryStorage
{
    class Program
    {

        // Parse the connection string and return a reference to the storage account.
        public static CloudStorageAccount storageAccount = CloudStorageAccount.Parse(
            CloudConfigurationManager.GetSetting("StorageConnectionString"));

        //Create Table Client
        public static CloudTableClient tableClient = storageAccount.CreateCloudTableClient();

        //Create Blob Client
        public static CloudBlobClient blobClient = storageAccount.CreateCloudBlobClient();

        public static void Main(string[] args)
        {
            //Create Devices Table and load data from the SampleData.json file
            CreateTableAndLoadData();

            //Retrive data to check
            GetRecord("SID0003-RO1 Dummy3");

            //Console.WriteLine(Content.ReadAsStringAsync());
        }

        private static void CreateTableAndLoadData()
        {
            // Retrieve a reference to the table.
            CloudTable table = tableClient.GetTableReference("Devices");

            // Create the table if it doesn't exist.
            table.CreateIfNotExists();

            TableBatchOperation batchOperation = new TableBatchOperation();

            List<DeviceEntity> devices = LoadSampleData.FromSampleDataFile();

            foreach(DeviceEntity d in devices)
            {
                batchOperation.Insert(d);
            }

            table.ExecuteBatch(batchOperation);

        }

        private static void GetRecord(string rowKey)
        {
            // Retrieve a reference to the table.
            CloudTable table = tableClient.GetTableReference("Devices");

            // Create a retrieve operation that takes a customer entity.
            TableOperation retrieveOperation = TableOperation.Retrieve<DeviceEntity>("VSAT", rowKey);

            TableResult retrievedResult = table.Execute(retrieveOperation);

            // Print the phone number of the result.
            if (retrievedResult.Result != null)
            {
                Console.WriteLine(((DeviceEntity)retrievedResult.Result).LowerLimit);
                Console.WriteLine(((DeviceEntity)retrievedResult.Result).UpperLimit);
            }
            else
                Console.WriteLine("No Data retrieved.");
        }

    }
}
