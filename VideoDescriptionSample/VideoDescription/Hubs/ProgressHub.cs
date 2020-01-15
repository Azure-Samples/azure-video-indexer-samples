using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using Microsoft.AspNet.SignalR;

namespace VideoDescription.Hubs
{
    public class ProgressHub : Hub
    {
        public override Task OnConnected()
        {
            signalConnectionId(this.Context.ConnectionId);
            return base.OnConnected();
        }

        private void signalConnectionId(string signalConnectionId)
        {
            Clients.Client(signalConnectionId).signalConnectionId(signalConnectionId);
        }
    }
}