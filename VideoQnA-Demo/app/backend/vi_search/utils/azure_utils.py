import subprocess


def get_azd_env_values() -> dict:
    """
    These values should be defined in the Azure DevOps pipeline.
    - AZURE_OPENAI_API_KEY (Azure OpenAI API key)
    - AZURE_OPENAI_CHATGPT_DEPLOYMENT (Azure OpenAI Chat LLM deployment name)
    - AZURE_OPENAI_EMBEDDINGS_DEPLOYMENT (Azure OpenAI embeddings model deployment name)
    - AZURE_OPENAI_RESOURCE_GROUP (Resource Group name of the Azure OpenAI resource)
    - AZURE_OPENAI_SERVICE (Azure OpenAI resource name)
    - AZURE_SEARCH_KEY (Azure AI Search API key)
    - AZURE_SEARCH_SERVICE (Azure AI Search resource name)
    - AZURE_SEARCH_LOCATION (Azure AI Search instance location, e.g. ukwest)
    - AZURE_SEARCH_SERVICE_RESOURCE_GROUP (Resource Group name of the Azure AI Search resource)
    - AZURE_TENANT_ID (Azure Tenant ID)
    """
    try:
        output = subprocess.check_output(["azd", "env", "get-values"])
        output = output.decode().split("\n")

        azd_env_values = {}
        for line in output:
            if line:
                key, value = line.split("=", 1)
                azd_env_values[key] = value[1:-1]
    except Exception as e:
        import os

        # read values from environment variables
        azd_env_values = {
            "AZURE_OPENAI_API_KEY": os.getenv("AZURE_OPENAI_API_KEY"),
            "AZURE_OPENAI_CHATGPT_DEPLOYMENT": os.getenv("AZURE_OPENAI_CHATGPT_DEPLOYMENT"),
            "AZURE_OPENAI_EMBEDDINGS_DEPLOYMENT": os.getenv("AZURE_OPENAI_EMBEDDINGS_DEPLOYMENT"),
            "AZURE_OPENAI_RESOURCE_GROUP": os.getenv("AZURE_OPENAI_RESOURCE_GROUP"),
            "AZURE_OPENAI_SERVICE": os.getenv("AZURE_OPENAI_SERVICE"),
            "AZURE_SEARCH_KEY": os.getenv("AZURE_SEARCH_KEY"),
            "AZURE_SEARCH_SERVICE": os.getenv("AZURE_SEARCH_SERVICE"),
            "AZURE_SEARCH_LOCATION": os.getenv("AZURE_SEARCH_LOCATION"),
            "AZURE_SEARCH_SERVICE_RESOURCE_GROUP": os.getenv("AZURE_SEARCH_SERVICE_RESOURCE_GROUP"),
            "AZURE_TENANT_ID": os.getenv("AZURE_TENANT_ID"),
        }

    return azd_env_values
