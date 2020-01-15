using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Web;
using Microsoft.AspNet.SignalR;
using VideoDescription.Hubs;

namespace VideoDescription.Util
{
    public class Functions
    {
        public static void SendProgress(string progressMessage, int progressCount, int totalItems)
        {
            //IN ORDER TO INVOKE SIGNALR FUNCTIONALITY DIRECTLY FROM SERVER SIDE WE MUST USE THIS
            var hubContext = GlobalHost.ConnectionManager.GetHubContext<ProgressHub>();

            //CALCULATING PERCENTAGE BASED ON THE PARAMETERS SENT
            var percentage = (progressCount * 100) / totalItems;

            //PUSHING DATA TO ALL CLIENTS
            hubContext.Clients.All.AddProgress(progressMessage, percentage + "%");
        }
    }


    /// <summary>
    /// Preserve HttpContext.Current across async/await calls.  
    /// Usage: Set it at beginning of request and clear at end of request.
    /// </summary>
    static public class HttpContextProvider
    {
        /// <summary>
        /// Property to help ensure a non-null HttpContext.Current.
        /// Accessing the property will also set the original HttpContext.Current if it was null.
        /// </summary>
        static public HttpContext Current => HttpContext.Current ?? (HttpContext.Current = __httpContextAsyncLocal?.Value);

        /// <summary>
        /// MVC5 does not preserve HttpContext across async/await calls.  This can be used as a fallback when it is null.
        /// It is initialzed/cleared within BeginRequest()/EndRequest()
        /// MVC6 may have resolved this issue since constructor DI can pass in an HttpContextAccessor.
        /// </summary>
        static private AsyncLocal<HttpContext> __httpContextAsyncLocal = new AsyncLocal<HttpContext>();

        /// <summary>
        /// Make the current HttpContext.Current available across async/await boundaries.
        /// </summary>
        static public void OnBeginRequest()
        {
            __httpContextAsyncLocal.Value = HttpContext.Current;
        }

        /// <summary>
        /// Stops referencing the current httpcontext
        /// </summary>
        static public void OnEndRequest()
        {
            __httpContextAsyncLocal.Value = null;
        }
    }
}