using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Web.Optimization;
using System.Web.Routing;
using VideoDescription.Util;

namespace VideoDescription
{
    public class MvcApplication : System.Web.HttpApplication
    {
        protected void Application_Start()
        {
            AreaRegistration.RegisterAllAreas();
            FilterConfig.RegisterGlobalFilters(GlobalFilters.Filters);
            RouteConfig.RegisterRoutes(RouteTable.Routes);
            BundleConfig.RegisterBundles(BundleTable.Bundles);
        }

        public MvcApplication() // constructor
        {
            PreRequestHandlerExecute += new EventHandler(OnPreRequestHandlerExecute);
            EndRequest += new EventHandler(OnEndRequest);
        }

        protected void OnPreRequestHandlerExecute(object sender, EventArgs e)
        {
            HttpContextProvider.OnBeginRequest();   // preserves HttpContext.Current for use across async/await boundaries.            
        }

        protected void OnEndRequest(object sender, EventArgs e)
        {
            HttpContextProvider.OnEndRequest();
        }
    }
}
