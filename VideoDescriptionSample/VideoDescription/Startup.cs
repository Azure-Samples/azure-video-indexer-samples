using Microsoft.Owin;
using Owin;

[assembly: OwinStartupAttribute(typeof(VideoDescription.Startup))]
namespace VideoDescription
{
    public partial class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            //ConfigureAuth(app);

            app.MapSignalR();
        }
    }
}
