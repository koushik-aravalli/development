using LetTryApi.Contracts;
using LetTryApi.Models;
using Microsoft.Azure;
using Microsoft.Azure.Documents;
using Microsoft.Azure.Documents.Client;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web;

namespace LetTryApi.Repositories
{

    public class DocumentDbRepo : IDocumentDbRepo
    {
        private string EndpointUri = CloudConfigurationManager.GetSetting("EndpointUri");
        private string PrimaryKey = CloudConfigurationManager.GetSetting("PrimaryKey");
        private string DatabaseName = CloudConfigurationManager.GetSetting("MarlinkDocumentDb");
        private string CollectionName = CloudConfigurationManager.GetSetting("OrderCollection");
        private DocumentClient client;

        public DocumentDbRepo()
        {
            DocumentClient docDbclient = new DocumentClient(new Uri(EndpointUri),PrimaryKey);
        }

        private async Task CreateDatabaseIfNotExists(string databaseName)
        {
            // Check to verify a database with the id=FamilyDB does not exist
            try
            {
                await this.client.ReadDatabaseAsync(UriFactory.CreateDatabaseUri(databaseName));
            }
            catch (DocumentClientException de)
            {
                // If the database does not exist, create a new database
                if (de.StatusCode == HttpStatusCode.NotFound)
                {
                    await this.client.CreateDatabaseAsync(new Database { Id = databaseName });
                }
                else
                {
                    throw;
                }
            }
        }

        private async Task CreateDocumentCollectionIfNotExists(string databaseName, string collectionName)
        {
            try
            {
                await this.client.ReadDocumentCollectionAsync(UriFactory.CreateDocumentCollectionUri(databaseName, collectionName));
            }
            catch (DocumentClientException de)
            {
                // If the document collection does not exist, create a new collection
                if (de.StatusCode == HttpStatusCode.NotFound)
                {
                    DocumentCollection collectionInfo = new DocumentCollection();
                    collectionInfo.Id = collectionName;

                    // Configure collections for maximum query flexibility including string range queries.
                    collectionInfo.IndexingPolicy = new IndexingPolicy(new RangeIndex(DataType.String) { Precision = -1 });

                    // Here we create a collection with 400 RU/s.
                    await this.client.CreateDocumentCollectionAsync(
                        UriFactory.CreateDatabaseUri(databaseName),
                        collectionInfo,
                        new RequestOptions { OfferThroughput = 400 });
                }
                else
                {
                    throw;
                }
            }
        }

        public async Task<Order> CreateOrder(Order order)
        {
            Order result = null;
            try
            {
                result = (dynamic) await this.client.ReadDocumentAsync(UriFactory.CreateDocumentUri(DatabaseName, CollectionName, order.Id));

            }
            catch (DocumentClientException readException)
            {
                if(readException.StatusCode == HttpStatusCode.NotFound)
                {
                    try
                    {
                        result = (dynamic) await this.client.CreateDocumentAsync(UriFactory.CreateDocumentCollectionUri(DatabaseName, CollectionName), order);
                    }
                    catch (DocumentClientException createException)
                    {
                        throw createException;
                    }

                }
            }
            return result;
        }

        public Order GetOrder(string orderId)
        {
            Order order = null;
            try
            {
                // Set some common query options
                FeedOptions queryOptions = new FeedOptions { MaxItemCount = -1 };

                // Here we find the Andersen family via its LastName
                IQueryable<Order> orderQuery = this.client.CreateDocumentQuery<Order>(
                        UriFactory.CreateDocumentCollectionUri(DatabaseName, CollectionName), queryOptions)
                        .Where(o => o.Id == orderId);

                order = orderQuery.First();
            }
            catch (DocumentClientException readException)
            {
                throw readException;
            }

            return order;

        }

        public async Task<Order> ReplaceOrderDocument(string orderId, Order updatedOrder)
        {
            Order result = null;
            try
            {
                result = (dynamic) await this.client.ReplaceDocumentAsync(UriFactory.CreateDocumentUri(DatabaseName, CollectionName, orderId), updatedOrder);
            }
            catch (DocumentClientException de)
            {
                throw de;
            }
            return result;
        }

        public async Task DeleteOrder(string orderId)
        {
            try
            {
                await this.client.DeleteDocumentAsync(UriFactory.CreateDocumentUri(DatabaseName, CollectionName, orderId));
            }
            catch (DocumentClientException deleteExp)
            {
                throw deleteExp;
            }
        }
    }
}