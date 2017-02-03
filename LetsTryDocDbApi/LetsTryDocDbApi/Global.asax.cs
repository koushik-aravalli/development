using AutoMapper;
using LetsTryDocDbApi.Dtos;
using LetsTryDocDbApi.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Http;
using System.Web.Routing;

namespace LetsTryDocDbApi
{
    public class WebApiApplication : System.Web.HttpApplication
    {
        protected void Application_Start()
        {
            Mapper.Initialize(cfg => cfg.CreateMap<Order, OrderDto>().ReverseMap());


            GlobalConfiguration.Configure(WebApiConfig.Register);
        }
    }
}
