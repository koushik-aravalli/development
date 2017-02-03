using MySql.Data.MySqlClient;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LetsSimulateDevice
{
    public class VsatRepository
    {

        private MySqlConnection connection;
        private string server;
        private string database;
        private string uid;
        private string password;

        //Constructor
        public VsatRepository()
        {
            Initialize();
        }

        //Initialize values
        private void Initialize()
        {
            server = "10.107.130.13";
            database = "Insight";
            uid = "insight_admin";
            password = "insight_admin";
            string connectionString;
            connectionString = "SERVER=" + server + ";" + "DATABASE=" +
            database + ";" + "UID=" + uid + ";" + "PASSWORD=" + password + ";";

            connection = new MySqlConnection(connectionString);
        }

        //open connection to database
        private bool OpenConnection()
        {
            try
            {
                connection.Open();
                return true;
            }
            catch (MySqlException ex)
            {
                //When handling errors, you can your application's response based 
                //on the error number.
                //The two most common error numbers when connecting are as follows:
                //0: Cannot connect to server.
                //1045: Invalid user name and/or password.
                Console.WriteLine(ex.Message);
                return false;
            }
        }

        //Close connection
        private bool CloseConnection()
        {
            try
            {
                connection.Close();
                return true;
            }
            catch (MySqlException ex)
            {
                Console.WriteLine(ex.Message);
                return false;
            }
        }
        
        //Select statement
        private List<CallLog> GetCallLog(string subscriberId)
        {
            string query = "SELECT SUBSCRIBER_ID AS SubscriberId, DOWNSTREAM_VOLUME AS Downloaded, UPSTREAM_VOLUME AS Uploaded, TIME_STAMP as TimeStamp " +
                           " FROM rpt_sur " +
                           " WHERE SUBSCRIBER_ID = '" + subscriberId  + "' "+
                           " AND TIME_STAMP between DATE_SUB(NOW() , INTERVAL 15 MINUTE) AND NOW() " +
                           " ORDER BY TIME_STAMP DESC";

            List<CallLog> aList = new List<CallLog>();

            if (this.OpenConnection() == true)
            {
                try
                {
                    MySqlCommand cmd = new MySqlCommand(query, connection);
                    MySqlDataReader reader = cmd.ExecuteReader();

                    while (reader.Read())
                    {
                        CallLog c = new CallLog();
                        c.SubscriberId = reader["SubscriberId"].ToString();
                        c.Downloaded = Convert.ToDouble(reader["Downloaded"].ToString());
                        c.Uploaded = Convert.ToDouble(reader["Uploaded"].ToString());
                        c.TimeStamp = Convert.ToDateTime(reader["TimeStamp"].ToString());

                        aList.Add(c);
                    }
                }
                finally
                {
                    CloseConnection();
                }
            }
            else
            {
                Console.WriteLine("No Connection");
            }

            return aList;
        }

        public List<CallLog> ConnectToVsatCollectionManager(string subscriberId)
        {
            return GetCallLog(subscriberId);
        }
    }
}
