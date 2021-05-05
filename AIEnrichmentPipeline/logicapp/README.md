# Logic Apps

There are 4 Logic Apps that constitute the solution The sub-folders beneath this folder each contain the Azure Resource manager template for each file. These are deployed to the Logic Apps by Terraform as the solution is deployed. See the [infra](./infra) section for details.

- **digitaltextfileworkflow** - The Digital Text workflow uses [Text Analytics API](https://docs.microsoft.com/en-us/azure/cognitive-services/Text-Analytics/) to obtain key phrases, PII information and entities from plain text files (complex text file such as Office documents are not supported)
- **imageworkflow** - The Image workflow uses the [Computer Vision API](https://azure.microsoft.com/en-us/services/cognitive-services/computer-vision/) to analyse for visual features, objects and brands and describe the image.
- **orchestrationworkflow** - The orchestration workflow responds to an event grid subscription event of a file having been uploaded to storage, identifies duplicates and orchestrates calls the the other logic apps based on the file category.
- **videoworkflow** - The Video workflow uses [Video Indexer](https://api-portal.videoindexer.ai/) to process and extract key information such as Face Detection, OCR, Content Moderation, identification of visual objects, transcription and translation of audio and many more features.

## Editing Logic Apps

To edit logic app, alter the deployed workflow using the Azure Portal, export the template from the portal and carefully replace the changed lines in the files in these folder.

Be sure not to overwrite values where parameters are expected to be injected by Terraform. These are usually formatted as follows:

`[parameters('digitaltextfileworkflowid')]`

