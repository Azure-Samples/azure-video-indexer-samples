# How to create a logic app flow for video indexer #

A step-by-step guide to export video insights from [Video Indexer](https://azure.microsoft.com/en-us/products/ai-video-indexer/) using [Azure Logic Apps](https://azure.microsoft.com/en-us/products/logic-apps/)

## Introduction ##

Video indexer is a cloud service that uses AI to analyse and index video and audio content. It can get insights like faces, emotions, topics, keywords, transcripts, and more. You can use video indexer to improve your video content, make searchable metadata, create captions, and build engaging apps.  In this code sample, we will show you how to make a logic app flow that exports the indexed videos insights from a specific account and store them in a blob storage and Azure Data Explorer and create a dashboard displaying the account data.
You can also view a video tutorial on our [YouTube channel](https://www.youtube.com/watch?v=yMqJufR9Rfs), this video tutorial will demonstrate how to set up the Logic App and run operations against a Video Indexer account.

## Prerequisites ##

- An Azure account with an active subscription. If you don't have one, you can create a [free account](https://azure.microsoft.com/free/?ref=microsoft.com&utm_source=microsoft.com&utm_medium=docs&utm_campaign=visualstudio).
- A video indexer account, You can sign up for a free trial [here](https://www.videoindexer.ai/accounts/b3d3896f-ddb1-4adc-89f9-ab4d431316d5/videos/e7f3928d4f?location=eastus).
- Subscribe to Video Indexer APIs [here](https://learn.microsoft.com/en-us/azure/azure-video-indexer/video-indexer-use-apis#subscribe-to-the-api).
- Azure Storage account, with a designated container ex: videos.
- Optional: Create Azure Data Explorer cluster, you can use [this article](https://learn.microsoft.com/en-us/azure/data-explorer/create-cluster-and-database?tabs=free).

## Steps ##

1. [Create and configure a logic app in Azure portal](#create-and-configure-the-logic-app-in-azure-portal)
2. [Set up Parameters](#set-up-parameters)
3. [Configure the trigger and video indexer connector](#configure-the-trigger-and-the-video-indexer-connector)
4. [Export video data to Azure Storage Blob](#export-video-data-to-azure-storage-blob)
5. Optional: [Export video data to Azure Data Explorer](#optional-export-the-video-index-to-azure-data-explorer)
6. [Test the logic app flow](#test-the-logic-app-flow)

### Create and configure the logic app in Azure portal ###

To create a logic app, follow these steps:

- Sign in to the [Azure Portal](https://portal.azure.com/).
- Select Create a resource in the upper left corner of the portal.
- Search for logic app and select it.
- Select Create.
- On the Create logic app page, enter a name for your logic app, select a subscription, a resource group and a location.
- Select Review + create and then Create.
- You will also need to configure a Managed Identity, this for the "Get Access Token" HTTP action:
- Expend the Settings on the left pane and select Identity
- Under System assigned change the status to "On" and click Save
- Click on Azure role assignments
- Click on Add role assignment, set scope to "resource group", select the Video Indexer account resource group and set the role to "Contributor".
- Click Save.
- Click on Add role assignment, set scope to "Storage", Select the storage subscription and resource and set the role to "Storage blob data contributor”.
- Click Save.

### Set up Parameters ###

Click parameters at the top of the designer, click create parameter for each of the following:

- Name: account_id, Type: string, Default value: Video indexer account id.
- Name: account_ name, Type: string, Default value: Video indexer account name.
- Name: account_rg, Type: string, Default value: Video indexer account resource group.
- Name: subscription_id, Type: string, Default value: your subscription id.

__NOTE:__ All values can be located in the Video Indexer resource blade.

### Configure the trigger and the video indexer connector ###

#### Configure the Logic App trigger ####

- In the Designer area, click “Add a trigger”, search for “Schedule” and select "Recurrence”.
- You can set it to run daily, hourly, or every minute. To optimize, limit the get video list call to only retrieve new videos created after the last recurrence, in this code sample we will not get into this logic. 

#### Configure Video Indexer get access token connector ####

- Select New step and then select HTTP.
- Set name as Get Access Token.
- URL: https://management.azure.com/subscriptions/@{parameters('subscription_id')}/resourceGroups/@{parameters('account_rg')}/providers/Microsoft.VideoIndexer/accounts/@{parameters('account_name')}/generateAccessToken?api-version=2024-01-01
- Set method as POST.
- Body
{
"permissionType": "Contributor",
"scope": "Account"
}
- In Advanced parameters select Authentication:
  - Authentication Type set as Managed Identity.
  - Managed Identity set as System-assigned managed identity.
  - Audience https://management.core.windows.net
- Select New step and then select ParseJson.
- Set name as Extract Access Token.
- Set content as @body('Get_Access_Token').
- Save the logic app.

#### Configure the get video list connector, follow these steps ####

- Select New step and then select HTTP.
- Set name as List Videos.
- Set the URL as https://api.videoindexer.ai/@{parameters('account_location')}/Accounts/@{parameters('account_id')}/Videos?accessToken=@{body('Extract_Access_Token')?['accessToken']}
- Set method as Get.
- Save the logic app.

__Note:__ for accounts with high volume of we recommend adding pagination logic to this call, this can be done by adding two more parameters: pageSize and skip, and use createdAfter to retrieve only the latest videos.
for more details on this API [here](https://api-portal.videoindexer.ai/api-details#api=Operations&operation=List-Videos).

#### Create video enumeration flow ####

- Select New step and then select foreach.
- Set Select An Output From Previous Steps as @body('List_Videos')?['results'].
- Save the logic app.

#### Configure the get video index connector ####

- Select New step and then select HTTP.
- Set name as Get Video index.
- Set the URL with id from the enumerated item, the account id parameter and access token retrieved in the previous step:
https://api.videoindexer.ai/eastus/Accounts/@{parameters('account_id')}/Videos/@{items('For_each')['id']}/Index?accessToken=@{body(‘Extract_Access_Token’)?['accessToken']}
- Set method as Get.
- Save the logic app.

### Export video data to Azure Storage Blob ###

- Select New step and then select Create blob (V2).
- Create storage connection.
  - Enter name managedIdentityConnection.
  - Set Authentication Type to Logic Apps Managed Identity.
  - Click Create Now.
- Set name as Export to blob.
- Set the storage Account Name Or Blob Endpoint.
- Set the folder path to /videos/ (make sure this container exists).
- Set the blob name to @{items('For_each')['id']}.csv
- Set the blob content to @body('Get_Video_index').
- Set the content type to 'application/json'.
- Save the logic app.

### Optional: Export the video index to Azure Data Explorer ###

To export the video index to Azure Data Explorer, using Azure Blobs, follow these steps:

#### Configure the cluster ####

- Browes to [https://dataexplorer.azure.com/](https://dataexplorer.azure.com/)
- Run the KQL script in vi2adx.kql
- Set up system assigned managed identity:
  - Expend the Security + Networking on the left pane and select Identity.
  - Under System assigned change the status to "On" and click Save
  - Click on Azure role assignments.
  - Click on Add role assignment, set scope to "Storage", Select the storage subscription and resource and set the role to "Storage blob data contributor”.
  - Click Save.
- Run the following command using the managed identity object id.

``` kql

  .alter database db policy managed_identity ```
  [
    {
      "ObjectId": "aaaaaaaa-0000-1111-2222-bbbbbbbbbbbb",
      "AllowedUsages": "NativeIngestion"
    }
  ]```
```

#### Create Azure Data Explorer connector ####

- Select New step and then select Run async control command.
- Set the Cluster URL.
- Set the Database Name.
- Set the Control Command, setting the storage account name, and the managed identity for the Azure Data Explorer object id

``` kql
  .ingest async into table Indexer ('https://<storageName>.blob.core.windows.net/videos/@{items('For_each')['id']}.csv;managed_identity=<adcManagedIdentity>') with (format="json", ingestionMappingReference = "Indexer_mapping")
```

- Save the logic app.

#### Create dashboard ####

Finally, after exporting the data to Azure Data Explorer, we can create a dashboard to display it.

- Browes to [https://dataexplorer.azure.com/dashboards(https://dataexplorer.azure.com/dashboards)].
- Click Create New Dashboard.
- Name it Account Level Dashboard.
- Click on File, Replace dashboard with file.
- Select VI_AccountLevelDashboard.json
- Click on Data Sources, Click Add and enter the URL to your cluster, click Connect then Create.
- Now all is left is to edit each of the components and select the right data source, click apply changes and click save the dashboard.

### Test the logic app flow ###

- Select Run to manually trigger the logic app.
- Wait for the logic app to complete the run. You can check the status and the details of each action in the Run history pane.
- Congratulations, you have successfully created a logic app flow for video indexer.
