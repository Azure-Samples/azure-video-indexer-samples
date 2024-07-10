import msal
import requests

def get_bearer_token(tenant_id, client_id, client_secret):
    authority = f"https://login.microsoftonline.com/{tenant_id}"
    app = msal.PublicClientApplication(client_id, authority=authority)
    
    # Device code flow
    flow = app.initiate_device_flow(scopes=["https://api.videoindexer.ai/user_impersonation"])
    print(flow["message"])

    result = app.acquire_token_by_device_flow(flow)
    
    if "access_token" in result:
        return result["access_token"]
    else:
        print(result.get("error"))
        print(result.get("error_description"))
        raise Exception("Could not obtain access token")


# Example usage
# client_id = '1e4e3b40-94f3-4796-ba76-3ed1a5005e77'
client_id = 'd37f7a87-e9d7-4e41-bef4-3134dc83df62'
tenant_id = '72f988bf-86f1-41af-91ab-2d7cd011db47'
# client_secret is not needed for public client applications using device code flow
# client_secret = 'your-client-secret-here'

bearer_token = get_bearer_token(tenant_id, client_id, None)