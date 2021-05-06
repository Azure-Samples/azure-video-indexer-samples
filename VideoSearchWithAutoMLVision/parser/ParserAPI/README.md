# Parser API

The parser code converts Video Indexer insight files into 10 second snapshots. In addition it calls out to a separate
classifier api to identify the contents of the key frame images.

## Environment variables

The following sample environment variables need to be set for the process to work:

```bash
"DEBUG": "True", # Enable process debugging
"KEY": "<basic auth key>"
```

## API Request/Response

### API Inputs POST

```json
{
    "values": [
      {
        "recordId": "100003490593495",
        "data":
           {
             <insight file json>
           }
      }
    ]
}
```

### API Outputs

```json
{
    "values": [
        {
            "recordId": "100003490593495",
            "errors": "",
            "data": {"0": {<1st segment json>}, "1": {<2nd segment json>}},
            "warnings": ""
        }
    ]
}
```

## Basic Authentication

The API will perform a simple check to determine whether the KEY Header has been set.

It will validate that the value passed as a header to call this API, namely:

```bash
Ocp-Apim-Subscription-Key: [KEY]
```

## Normal start

To start the application for normal usage, run the following command:

```bash
uvicorn app:app --reload --port 5000
```

## Build and Test

The majority of steps necessary to get you up and running are already done by the dev container. But this project uses the following:

- Python
- Pip

Once your container is up and running you should:

1. Open your test `.py` file (```tests/parser_api_test.py```) and set the Python interpreter to be your venv (bottom blue bar of VSCode)
2. Use the python test explorer plugin to run your tests or click the 'run test' prompt above your tests

## Deploy to Azure

The infra folder contains terraform files to deploy this to FastAPI container to Web
Apps for Linux running a Docker container.

Follow these commands to deploy:

### Build the docker image, tag and push to your Azure Container Registry (ACR) instance

1. Login to your Azure Container Registry instance:

  ```bash
  az acr login --name <acrname>
  ```

1. Build and tag and push the image to ACR:

```bash
cd ./parser
docker build -t parserapi ./ParserAPI/
docker tag parserapi:latest <acrname>.azurecr.io/parserapi
docker push <acrname>.azurecr.io/parserapi
```

### Deploy using the terraform scripts in infra

1. Create a resouce group to deploy to.
2. Identify a storage account for terraform to use. Create a blob container called 'parser-deploy'.
  Edit the infra/main.tf file at the top to use this storage account and container name.
3. Install [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
4. Edit the ./parser/ParserAPI/infra/example-dev.tfvars file for the variables required.
    Note this requires the docker url, docker username and docker password if not using a service principal. For dev and
    test purposes the ACR admin account can be used in the docker username and  password variables.
5. Run these commands to deploy to the resource group:

```bash
cd ./parser/ParserAPI/infra
terraform init
terraform plan -var-file=example-dev.tfvars
terraform apply -var-file=example-dev.tfvars
```

View the log in the Azure portal ```log stream``` option of the web app.

## Remote SSH debugging

To enable the ```SSH``` connection for development debugging if deployed to Azure Web Apps, deploy the file
[```Dockerfile_debug```](containers/Dockerfile_debug) which will enable the Azure Web App to bridge a connection to the
running docker instance. See the [Enable SSH](https://docs.microsoft.com/en-gb/azure/app-service/configure-custom-container?pivots=container-linux#enable-ssh)
for more info. This is useful for inspecting running processes and checking model binaries are deployed correctly.

The files [```ssdh_config```](containers/sshd_config) and [```startup.sh```](containers/startup.sh) are used only for
this debugging
```Dockerfile_debug```.

### Connecting to the container

- Once deployed, select the ```ssh``` option in the Azure portal on the web app
- Click ```Go```
- You should see green message at the bottom of the screen with ```SSH CONNECTION ESTABLISHED``` if successful
- The terminal session should then be available for input
