using LetsTryDocDbApi.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LetsTryDocDbApi.BusinessLogic.Interface
{
    public interface IDocumentDbRepository
    {
        Task<Order> Insert(Order order);

        Task<Order> Get(long id);
    }
}
