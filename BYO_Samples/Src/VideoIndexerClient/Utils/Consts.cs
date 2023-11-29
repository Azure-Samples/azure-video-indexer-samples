
namespace VideoIndexerClient.Utils
{
    public static class Consts
    {
        public const string AzureResourceManager = "https://management.azure.com";
        public const string ApiVersion = "2022-08-01";

        public static readonly string SubscriptionId = Environment.GetEnvironmentVariable("SUBSCIPTION_ID") ?? "24237b72-8546-4da5-b204-8c3cb76dd930";
        public static readonly string ResourceGroup = Environment.GetEnvironmentVariable("VI_RESOURCE_GROUP") ?? "yl-try-rg";

        public static readonly string ApiEndpoint = Environment.GetEnvironmentVariable("API_ENDPOINT") ?? "https://api.videoindexer.ai/";
        public static readonly string InternalApiEndpoint = Environment.GetEnvironmentVariable("INTERNAL_API_ENDPOINT") ?? "https://api.videoindexer.ai/internals";
        public static readonly string Location = Environment.GetEnvironmentVariable("VI_LOCATION") ?? "eastus";
        public static readonly string ViAccountName = Environment.GetEnvironmentVariable("VI_ACCOUNT_NAME") ?? "yl-vi-eus";
        public static readonly string ViAccountId = Environment.GetEnvironmentVariable("VI_ACCOUNT_ID") ?? "b7d93ff7-c6f0-4208-a398-f54cd05d55a9";


        // COGNITIVE VISION 
        public static readonly string DetectObjectType = Environment.GetEnvironmentVariable("DETECT_OBJECT_CLASS") ?? "Car";
        public static readonly string CognitiveVisionApiVersion = "2023-02-01-preview";
        public static readonly string CognitiveVisionURI = Environment.GetEnvironmentVariable("CS_VISION_ENDPOINT") ?? "https://shaybyotest1.cognitiveservices.azure.com/vision/v4.0-preview.1/operations/imageanalysis:analyze";
        public static readonly string CognitiveVisionCustomModelName = Environment.GetEnvironmentVariable("CS_VISION_CUSTOM_MODEL_NAME") ?? "cartypesb1";
        public static readonly string CognitiveApiSubscriptionKey = Environment.GetEnvironmentVariable("CS_VISION_API_KEY") ?? "fd85f5de0a61453b9ca47ec9d375390b";

        // Artifact Types
        public const string ARTIFACT_TYPE_OCR = "Ocr";
        public const string ARTIFACT_TYPE_OD = "DetectedObjects";
        public const string DEFAULT_EMBEDDED_PATH = "/videos/0/insights/customInsights";

    }
}