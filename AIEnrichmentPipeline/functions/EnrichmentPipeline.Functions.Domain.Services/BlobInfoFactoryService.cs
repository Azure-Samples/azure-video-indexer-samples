using System;
using System.Collections.Generic;
using System.IO;
using Microsoft.Extensions.Logging;
using EnrichmentPipeline.Functions.Domain.Exceptions;
using EnrichmentPipeline.Functions.Domain.Interfaces;
using EnrichmentPipeline.Functions.Domain.Models;
using EnrichmentPipeline.Functions.Domain.Constants;

namespace EnrichmentPipeline.Functions.Domain.Services
{
    /// <summary>
    /// Implementation of IBlobInfoFactoryService.
    /// </summary>
    public class BlobInfoFactoryService : IBlobInfoFactoryService
    {
        private static TimeSpan sasDuration = TimeSpan.FromHours(48);

        private readonly IFileStorageService _fileStorageService;
        private readonly ILogger _logger;
        private readonly ISystemInfoService _systemInfoService;

        /// <summary>
        /// Initializes a new instance of the <see cref="BlobInfoFactoryService"/> class.
        /// </summary>
        /// <param name="fileStorageService">Service to access storage.</param>
        /// <param name="logger">Logger object.</param>
        /// <param name="systemInfoService">Service to access system information such as system version.</param>
        public BlobInfoFactoryService(IFileStorageService fileStorageService, ILogger<BlobInfoFactoryService> logger, ISystemInfoService systemInfoService)
        {
            _fileStorageService = fileStorageService;
            _logger = logger;
            _systemInfoService = systemInfoService;
        }

        /// <inheritdoc cref="IBlobInfoFactoryService"/>
        public BlobInfo CreateBlobInfo(Uri uri, string name, Guid correlationId)
        {
            TimeSpan duration = sasDuration;
            Uri sasUri;
            _logger.LogInformation("Started: CreateBlobInfo {uri}, {name}", uri, name);

            try
            {
                sasUri = _fileStorageService.GenerateSASUri(uri, duration);
            }
            catch (InvalidOperationException ioe)
            {
                _logger.LogCritical(ioe, "Failed to generate SAS Uri from {uri}", uri);
                throw;
            }

            if (sasUri == null)
            {
                _logger.LogCritical("Failed to generate SAS Uri from {uri}", uri);
                throw new SASUriCreationFailedException($"Failed to generate SAS Uri from {uri}");
            }

            _logger.LogInformation("Generated SAS Uri");

            // Work out file category
            string fileExtension = Path.GetExtension(name)?.Replace(".", string.Empty).ToLower();
            string fileType;
            switch (fileExtension)
            {
                case "txt":
                case "md":
                case "html":
                case "rtf":
                    fileType = "digitaltext";
                    break;
                case "jpg":
                case "jpeg":
                case "gif":
                case "bmp":
                case "png":
                    fileType = "image";
                    break;
                case "mp4":
                case "avi":
                case "wmv":
                case "mpg":
                case "mov":
                    fileType = "video";
                    break;
                case "mp3":
                case "wma":
                case "wav":
                case "ogg":
                    fileType = "audio";
                    break;
                default:
                    fileType = "unknown";
                    break;
            }

            // Generate hash
            string hash = _fileStorageService.GetFileMD5Hash(uri);

            try
            {
                // Create body for Logic App request
                return new BlobInfo()
                {
                    CorrelationId = correlationId,
                    CanonicalUri = uri,
                    SasUri = sasUri,
                    SasExpiry = DateTime.UtcNow + duration,
                    FileName = name,
                    FileCategory = fileType,
                    SystemVersion = $"{_systemInfoService.SystemVersion}+{_systemInfoService.ComponentVersion}",
                    MetaData = new Dictionary<string, string>(),
                    Hash = hash,
                };
            }
            finally
            {
                _logger.LogInformation(GeneralConstants.FunctionCompletedMessage, "CreateBlobInfo", uri);
            }
        }

        /// <inheritdoc cref="IBlobInfoFactoryService"/>
        public Guid CreateCorrelationId()
        {
            return Guid.NewGuid();
        }
    }
}
