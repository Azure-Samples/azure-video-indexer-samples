#pragma warning disable CS8601  

namespace VideoIndexerClient.Utils
{
    public static class Consts
    {
        public const string AzureResourceManager = "https://management.azure.com";
        public const string ApiVersion = "2022-08-01";

        public static readonly string SubscriptionId = Environment.GetEnvironmentVariable("SUBSCIPTION_ID") ;
        public static readonly string ResourceGroup = Environment.GetEnvironmentVariable("VI_RESOURCE_GROUP") ;

        public static readonly string ApiEndpoint = Environment.GetEnvironmentVariable("API_ENDPOINT") ?? "https://api.videoindexer.ai";
        public static readonly string Location = Environment.GetEnvironmentVariable("VI_LOCATION") ;
        public static readonly string ViAccountName = Environment.GetEnvironmentVariable("VI_ACCOUNT_NAME") ;
        public static readonly string ViAccountId = Environment.GetEnvironmentVariable("VI_ACCOUNT_ID") ;

        // COGNITIVE VISION 
        public static readonly string DetectObjectType = Environment.GetEnvironmentVariable("DETECT_OBJECT_CLASS") ?? "Car";
        public static readonly string CognitiveVisionUri = Environment.GetEnvironmentVariable("CS_VISION_ENDPOINT") ;
        public static readonly string CognitiveVisionCustomModelName = Environment.GetEnvironmentVariable("CS_VISION_CUSTOM_MODEL_NAME") ;
        public static readonly string CognitiveApiSubscriptionKey = Environment.GetEnvironmentVariable("CS_VISION_API_KEY") ;

        // Artifact Types
        public const string ARTIFACT_TYPE_OCR = "Ocr";
        public const string ARTIFACT_TYPE_OD = "DetectedObjects";
        public const string DEFAULT_EMBEDDED_PATH = "/videos/0/insights/customInsights";
    }
}