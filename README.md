---
page_type: sample
languages:
  - csharp
  - javascript
  - html
  - dotnet
products:
  - azure
  - azure-media-services
  - azure-video-indexer
description: "Video Indexer Official Samples"
urlFragment: "https://www.videoindexer.ai/"
---

# Official Video Indexer Samples

<!-- 
Guidelines on README format: https://review.docs.microsoft.com/help/onboard/admin/samples/concepts/readme-template?branch=master

Guidance on onboarding samples to docs.microsoft.com/samples: https://review.docs.microsoft.com/help/onboard/admin/samples/process/onboarding?branch=master

Taxonomies for products and languages: https://review.docs.microsoft.com/new-hope/information-architecture/metadata/taxonomies?branch=master
-->

Welcome to the official Video Indexer (VI) Samples repo. Video indexer builds upon media AI technologies to make it easier to extract insights from videos. Here you can find some great code snippets that you can use to work with Video Indexer API and integrate Video Indexer widgets into your website.

## IMPORTANT: REPO NAME CHANGE
Due to the retirement of Azure Media Services, this repository's name is going to change to "azure-video-indexer-samples" as early as January 24th and no later than January 26th, 2024. Plan accordingly.

## Contents

Here you can find code samples and project examples of how to use Video Indexer, integrated it with your product, and expand our out-of-the-box offering by integrating with other products.

| File/folder                  | Description                                                  | Owner           |
| ---------------------------- | ------------------------------------------------------------ | --------------- |
| `Deploy-Samples`     | Quick-Start tutorial to create Azure Video Indexer and all its resource dependencies with ARM, or bicep | Video Indexer        |
| `API Samples`        | Sample code of uploading and indexing video using API        | Video Indexer   |
| `VideoIndexerEnabledByArc`        | Video Indexer Enabled By Arc Sample And deploy tutorials        | Video Indexer   |
| `Embedding widgets`          | How to add Video Indexer widgets to your app                 | Video Indexer   |
| `BringYourOwn-Samples` | Bring-Your-Own Model with Video Indexer API and Complete Custom Model Flow | Video Indexer |
| `VideoQnA-Demo` | Video Indexer Archive Q&A using LLM, Vector DB, Azure OpenAI, Azure AI Search, and ChromaDB | Video Indexer |
| `LogicApp-Samples` | Bring Your Own AI using Logic Apps to classify objects using GPT4o | Video Indexer |
| `ExportVideoDataToADX` | Exporting video index data to Azure Data Explorer using Logic Apps | Video Indexer |
| `media`                      | media used for md files                                      |                 |
| `.gitignore`                 | Define what to ignore at commit time                         |                 |
| `CHANGELOG.md`               | List of changes to the sample                                |                 |
| `CONTRIBUTING.md`            | Guidelines for contributing to the sample                    |                 |
| `README.md`                  | This README file                                             |                 |
| `LICENSE`                    | The license for the sample                                   |                 |

We highly recommend you will follow our [blog posts](https://azure.microsoft.com/en-us/blog/tag/video-indexer/) to get deeper insights and the most updated news.

## Prerequisites
You should have an active user to Video Indexer.

Start by Signing-up to [Video Indexer API](https://api-portal.videoindexer.ai/) and get your API key.

We also recommend to start with our [short and basic introduction to Video Indexer]([https://github.com/itayar/test/blob/master/labTest.md](https://github.com/Azure-Samples/media-services-video-indexer/blob/master/IntroToVideoIndexer.md)), if you are not familiar with VI.
<!--
Outline the required components and tools that a user might need to have on their machine in order to run the sample. This can be anything from frameworks, SDKs, OS versions or IDE releases. 
-->

## Contributing
Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Authors
For each folder you will find a README file which will specify the relevant author for the sample code you are looking at.

See also the list of [contributors](https://github.com/itayar/VI-samples-local/graphs/contributors) who participated in this project.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
