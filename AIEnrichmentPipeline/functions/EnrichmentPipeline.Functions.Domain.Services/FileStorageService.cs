using System;
using System.IO;
using System.Net;
using Azure;
using Azure.Storage;
using Azure.Storage.Files.DataLake;
using Azure.Storage.Files.DataLake.Models;
using Azure.Storage.Sas;
using EnrichmentPipeline.Functions.Domain.Configuration;
using EnrichmentPipeline.Functions.Domain.Interfaces;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace EnrichmentPipeline.Functions.Domain.Services
{
    /// <summary>
    /// IFileStorageService implementation using the DataLakeStorage SDK.
    /// </summary>
    public class FileStorageService : IFileStorageService
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="FileStorageService"/> class.
        /// </summary>
        /// <param name="datalakeConfig">dataLakeConfig instance.</param>
        /// <param name="logger">logger instance.</param>
        public FileStorageService(IOptions<DataLakeConfiguration> datalakeConfig, ILogger<FileStorageService> logger)
        {
            DataLakeConfiguration = datalakeConfig.Value;
            string azureStorageAccountName = DataLakeConfiguration.Name;
            string azureStorageAccountKey = DataLakeConfiguration.Key;

            SharedKeyCredential = new StorageSharedKeyCredential(azureStorageAccountName, azureStorageAccountKey);
        }

        private DataLakeConfiguration DataLakeConfiguration { get; }
        private StorageSharedKeyCredential SharedKeyCredential { get; }

        /// <inheritdoc cref="IFileStorageService"/>
        public static Uri BuildUriForBlob(string endpoint, string enrichmentContainerName, string filename)
        {
            UriBuilder uri = new UriBuilder(endpoint);
            uri.Path = $"{enrichmentContainerName}/{filename}.json";

            return uri.Uri;
        }

        /// <inheritdoc cref="IFileStorageService"/>
        public Stream GetFileContent(Uri fileUri)
        {
            DataLakeFileClient fcli = new DataLakeFileClient(fileUri, SharedKeyCredential);
            return fcli.Read().Value.Content;
        }

        /// <inheritdoc cref="IFileStorageService"/>
        public Uri GenerateSASUri(Uri fileUri, TimeSpan duration)
        {
            AccountSasBuilder sas = new AccountSasBuilder
            {
                Protocol = SasProtocol.None,
                Services = AccountSasServices.Blobs,
                ResourceTypes = AccountSasResourceTypes.All,
                StartsOn = DateTimeOffset.UtcNow.AddHours(-1),
                ExpiresOn = DateTime.UtcNow.Add(duration),
                IPRange = new SasIPRange(IPAddress.None, IPAddress.None),
            };

            // Allow read access
            sas.SetPermissions(AccountSasPermissions.Read);

            // Build a SAS URI
            UriBuilder sasUri = new UriBuilder(fileUri)
            {
                Query = sas.ToSasQueryParameters(SharedKeyCredential).ToString(),
            };

            return sasUri.Uri;
        }

        /// <inheritdoc cref="IFileStorageService"/>
        public bool DoesBlobExist(string hash)
        {
            Uri uri = BuildUriForBlob(DataLakeConfiguration.Uri, DataLakeConfiguration.EnrichmentDataContainerName, hash);
            DataLakePathClient pathClient = new DataLakePathClient(uri, SharedKeyCredential);

            return pathClient.Exists();
        }

        /// <inheritdoc cref="IFileStorageService"/>
        public string GetFileMD5Hash(Uri fileUri)
        {
            DataLakeFileClient fcli = new DataLakeFileClient(fileUri, SharedKeyCredential);
            Response<PathProperties> props = fcli.GetProperties();
            byte[] hashBytes = props.Value.ContentHash;
            string hexHash = BitConverter.ToString(hashBytes);
            return hexHash;
        }
    }
}
