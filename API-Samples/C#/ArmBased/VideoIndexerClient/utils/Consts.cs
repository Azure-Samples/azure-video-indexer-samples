using System;

namespace VideoIndexingARMAccounts.VideoIndexerClient.utils
{
    public static class Consts
    {
        public const string ApiVersion = "2022-08-01";
        public const string AzureResourceManager = "https://management.azure.com";
        public static readonly string SubscriptionId = Environment.GetEnvironmentVariable("SUBSCIPTION_ID") ?? "24237b72-8546-4da5-b204-8c3cb76dd930";
        public static readonly string ResourceGroup = Environment.GetEnvironmentVariable("VI_RESOURCE_GROUP") ?? "yl-try-rg";
        public static readonly string ViAccountName = Environment.GetEnvironmentVariable("VI_ACCOUNT_NAME") ?? "yl-vi-eus";
        public static readonly string ViAccountId = Environment.GetEnvironmentVariable("VI_ACCOUNT_ID") ?? "b7d93ff7-c6f0-4208-a398-f54cd05d55a9";
        public static readonly string ApiEndpoint = Environment.GetEnvironmentVariable("API_ENDPOINT") ?? "https://api.videoindexer.ai";
        public static readonly string Location = Environment.GetEnvironmentVariable("VI_LOCATION") ?? "eastus";

    }
}
