using LetTryApi.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LetTryApi.Contracts
{
    public interface IDocumentDbRepo
    {
        Task<Order> CreateOrder(Order order);
        Order GetOrder(string orderId);
        Task<Order> ReplaceOrderDocument(string orderId, Order updatedOrder);
        Task DeleteOrder(string orderId);
    }
}
