using System;
using System.Collections.Generic;
using EnrichmentPipeline.Functions.Domain.Constants;
using Newtonsoft.Json;

namespace EnrichmentPipeline.Functions.Domain.Models
{
    /// <summary>
    /// Data that is scoped to one run of the function in the context of monitoring data.
    /// </summary>
    public class ScopedData
    {
        private Dictionary<string, string> _dictionary = new Dictionary<string, string>();

        /// <summary>
        /// Add a key/value pair to be associated with all telemetry data items.
        /// </summary>
        /// <returns>Return this to support fluent call.</returns>
        public ScopedData AddCustomData(string key, string value)
        {
            _dictionary.Add(key, value);
            return this;
        }

        /// <summary>
        /// Initialise the ScopedData instance from incoming BlobInfo object.
        /// </summary>
        /// <param name="blobInfo">the BlobInfo instance to update from.</param>
        /// <returns>If internal values are already set another way then return false, otherwise return true.</returns>
        public bool InitialiseFromBlobInfo(BlobInfo blobInfo)
        {
            if (blobInfo == null)
                throw new ArgumentException(nameof(blobInfo));

            bool refreshScopedData = false;

            if (!_dictionary.ContainsKey(GeneralConstants.CorrelationIdKey))
            {
                _dictionary[GeneralConstants.CorrelationIdKey] = blobInfo.CorrelationId.ToString();
                refreshScopedData = true;
            }

            return refreshScopedData;
        }

        /// <summary>
        /// Have the currently set custom data start taking effect.
        /// </summary>
        public void Apply()
        {
            TelemetryInitializers.TelemetryInitializer.ScopedTelemetryProperties.Value =
                JsonConvert.SerializeObject(_dictionary);
        }
    }
}
