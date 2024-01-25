# C# Functions and Tools Development

## Outline

The code for Azure functions developed for the project can be located under the `functions` subfolder in the root of the `AI Enrichment Pipeline` repository. The projects exist as C# .NET projects mostly Azure Functions projects and associated Test projects but also some shared code projects and Tools.

There is a `EnrichmentPipeline.Functions.sln` which groups the projects and all of the code resides within the `EnrichmentPipeline.Functions` namespace.

> Note. The `.sln` solution file is a convenience to developers using full Visual Studio and is not used by the build system.

There now follows a description of each project:  

### Azure Functions

Please refer to the [System Architecture Diagram](./docs/overview.jpg) to understand where each function fits into the execution context.

> Use these links to navigate to a specific Function\useful section:
>
> [Workflow Trigger](#`EnrichmentPipeline.Functions.workflowtrigger`)
>
> [Image Resize](#`EnrichmentPipeline.Functions.imageresize`)
>
> [Development & Build Process](#development-&-build-process)
>
> [Debugging](#debugging)
>
> [Adding a New Project](#adding-a-new-project-to-the-solution)
>
> [Calling a non-HTTP function manually](#calling-a-non-http-function-manually)

#### Project Settings

Azure functions use the `Host.json` file for app settings on Azure and `local.settings.json` for local developer settings.

`local.settings.json` shouldn't be committed to source control and so should be added to the `.gitignore` file. As a result there exists for each project a `sample.local.settings.json` file with empty values. So you can,

- Copy the contents of `local.settings.sample.json` into `local.settings.json`

- Get values from your deployed Azure function's configuration > application settings

`APPINSIGHTS_INSTRUMENTATIONKEY` can be found in the Azure portal by selecting your Application Insights instance and select the Overview page. The value is labelled as `Instrumentation Key` and is in the form of a `GUID`.

> Example settings for each project will be shown below under the specific Project heading

#### `EnrichmentPipeline.Functions.DuplicatesDetection`

A [Durable Azure Function](https://docs.microsoft.com/en-us/azure/azure-functions/durable/) used to detect bitwise identical files. This is used to prevent the same files from being processed multiple times and is executed as part of the orchestration workflow logic app. This Function is `triggered` using a Http POST which will start an orchestration that can be monitored for progress and on successful completion will return a hash string and a Boolean indicating whether the system has already processed this file. This Function uses DataLake to store previous history.

#### `EnrichmentPipeline.Functions.WorkflowTrigger`

The `WorkflowTriggerFunction` is the first step in system processing after a file has been uploaded via the Admin Process. The function is trigger by event grid subscription bound to the `BlobCreated` Azure Storage event. This means it will fire as soon as a blob is added or updated.

- Creates `BlobInfo` for the file triggering the function

- Send a message representing the blob to the Service Bus to be picked up by the orchestration workflow

##### Code structure and Updating

###### Functions

- `WorkflowTriggerFunction`: Event grid triggered function which calls sub-services when triggered.

###### Services

- `ServiceBusClientService` a service that creates a `ServiceBusClient` from a connection string which can be injected inot other service or mocked for unit testing
- `ServiceBusService` a service which creates and send messages to service bus based on incoming `BlobInfo` data

The function also uses the following shared services:
- `BlobInfoFactoryService` - a shared service which is part of `EnrichmentPipeline.Domain.Services`. Creates `BlobInfo` from a given blob url and file name.
- `IFileStorageService` - a shared service which is part of  `EnrichmentPipeline.Domain.Services`. handles interacting with the storage for the system.

###### Models

- `OutputServiceBusConfiguration` model for strong typing of application settings for connecting to the output service bus.

###### Settings

Requires a `local.settings.json` file to be created in order to run locally. This is not provided and is ignored from git because it will contain secrets. 

The content of this should be modelled `local.settings.sample.json`.

#### `EnrichmentPipeline.Functions.ImageResize`

Some of the Cognitive Services in use which operate on input images have limits on the sizes of those input images. The images input into the enrichmentpipeline system are unbounded so the `ImageResize` function is designed to resize an image to be within a pre-defined image size. Currently this is achieved by `POSTing` an image file to the `ImageResize` function.

> If the input image width is greater than the pre-defined pixel width then it will be down-sized such that it's width will be equal to the pre-defined pixel width.
>
> If the input image width is less than the pre-defined pixel width then this will be a no-op.

To debug locally you can send an http POST with the image file binary in the request body to:

`http://localhost:<your port>/api/ImageResize?filename=beard.jpg`

Or you can do a local deploy and run the integration tests as described in [Development & Build Process](#development-&-build-process)

###### Settings

Not applicable.

#### Adding a New Function

Navigate to the `functions` subfolder and using the Azure Functions Core Tools from a terminal as follows:

```bash
func new

Use the up/down arrow keys to select a worker runtime:
dotnet
node
python
powershell
custom

```

A command line wizard will walk you through choosing a language, function trigger, etc. (See [Create a function](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=windows%2Ccsharp%2Cbash#create-func) for further details).

For a new Function App you will also need to provide the terraform to describe the infrastructure. Please refer to `infra/main.tf` to see how this is achieved for the existing functions.

Apply the style tooling. (See [Adding a new project to the solution](#adding-a-new-project-to-the-solution))

### Shared Projects

These projects represent code that is common for use across multiple Functions but also shared to other parts of the system. For this reason they are `.netstandard 2.0` projects and can be consumed by full .NET Framework the .NET Core Azure Functions projects.

#### `EnrichmentPipeline.Functions.Domain`

Shared model types, interfaces, constants and very low-level services.

#### `EnrichmentPipeline.Functions.Domain.Services`

Common services used across the system for tasks such as data access and file access.

### Test Projects

There is a corresponding test project containing unit and integration tests as applicable. The test projects follow the naming convention of the project being tested name with an additional `.Tests`. The tests can be run by issuing the command `dotnet test` from the `functions` subfolder.

In addition, there is a `EnrichmentPipeline.Functions.TestUtilities` project where shared constants, extension methods and utility classes for unit testing can be located.

## Development & Build Process

The build script will find subfolders of the `functions` directory where the folder name contains `EnrichmentPipeline.Functions` and if that folder contains a `host.json` file then it will get built and published (using `dotnet publish`). All tests discovered in the `functions` folder will get run as part of the build process. The build process uses a `mono repo` approach so components are not versioned, created or consumed independently.

Once developed locally, to deploy and test changes to any of the functions you can deploy to your own subscription using the make.ps1 script, once complete run the integration tests and then look in Application Insights for any unexpected errors or tracing irregularities to ensure that your changes work in the context of the whole system. When adding a new function consider adding a corresponding integration tests.  

## Monitoring

For the deployed Function Apps there is a variety of views onto the running function including App Insights and Log Analytics where you can run queries over logging and performance metrics. The Function App page also has tools to provide a view on streaming logs, metrics and running processes, etc.

## Debugging

The Azure Functions can be debugged remotely or locally. The suggestion would be to start by debugging locally using the [Azure Function Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=windows%2Ccsharp%2Cbash) which will replicate a similar runtime environment to that in Azure. If you need to debug a remote Function running on Azure you can use full Visual Studio under Cloud Explorer--> Under Functions--there is an `Attach Debugger` option.

### Running the function locally

1. Run the function using whatever the usual process is for your environment (F5 for Visual Studio)

## Formatting

[`.editorconfig`](https://github.com/dotnet/runtime/blob/master/.editorconfig) should provide consistent formatting. This is taken from the dotnet/runtime repo.

## Style rules

To enforce coding styles this project uses the [StyleCop Analyzer package](https://github.com/DotNetAnalyzers/StyleCopAnalyzers). In order to make changes to the rules, you will need to amend the [enrichmentpipeline.ruleset file](enrichmentpipeline.ruleset)

## Adding a new project to the solution

In order to enforce the style rules for new projects added to the solution, please do the following steps:

- Open an existing project file in edit mode.
- Add the following package reference:

```xml
 <PackageReference Include="StyleCop.Analyzers" Version="1.1.118">
    <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    <PrivateAssets>all</PrivateAssets>
</PackageReference>
```

- Add or update the `PropertyGroup` nodes as follows:

```xml
<PropertyGroup>
    <GenerateDocumentationFile>true</GenerateDocumentationFile>
</PropertyGroup>
<PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Release|AnyCPU'">
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <CodeAnalysisRuleSet>../enrichmentpipeline.ruleset</CodeAnalysisRuleSet>
</PropertyGroup>
<PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Debug|AnyCPU'">
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <CodeAnalysisRuleSet>../enrichmentpipeline.ruleset</CodeAnalysisRuleSet>
</PropertyGroup>
```

- Add the following attribute to the top level `PropertyGroup`:

```xml
    <NoWarn>1591</NoWarn>
```

## Calling a non-HTTP function manually

It's possible to manually trigger a non-HTTP function by using the /admin endpoint in the functions runtime. This works locally as well as when deployed. It's just a `POST` request against the `/admin/functions/{my-function-name}` endpoint. More in the [docs](https://docs.microsoft.com/en-us/azure/azure-functions/functions-manually-run-non-http).

To do this in PowerShell:

```PowerShell
$header = @{"Content-Type" = "application/json"} 
$body = "{'input': ''}"
$uri = "http://localhost:7071/admin/functions/{my-function-name}"
Invoke-WebRequest -Uri $uri -Headers $header -Body $body -Method "POST"
```

> **_Note_:** if calling a deployed function, add the `"x-functions-key" = "{func-master-key-here}"` to the headers object.
