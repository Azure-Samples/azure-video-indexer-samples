using System;
using System.IO;

namespace EnrichmentPipeline.Functions.Domain.Interfaces
{
    /// <summary>
    /// This is a content storage retrieval service. Currently, how the content
    /// gets to the storage is an implementation detail of the concrete
    /// implementation class.
    /// </summary>
    public interface IFileStorageService
    {
        /// <summary>
        /// Get back a Stream object when passing a valid content uri.
        /// </summary>
        /// <param name="fileUri">The uri of the file.</param>
        /// <returns>Stream of the file.</returns>
        Stream GetFileContent(Uri fileUri);

        /// <summary>
        /// Generate a SAS Uri from a file content Uri.
        /// </summary>
        /// <param name="fileUri">The Uri to the file content.</param>
        /// <param name="duration">The duration of the requested access.</param>
        /// <returns>SAS Uri.</returns>
        Uri GenerateSASUri(Uri fileUri, TimeSpan duration);

        /// <summary>
        /// Checks if a blob exists.
        /// </summary>
        /// <param name="hash">The uri of the blob.</param>
        /// <returns>Boolean indicating the blob's existence.</returns>
        bool DoesBlobExist(string hash);

        /// <summary>
        /// Get the MD5 hash generated for the file by the Azure Blob Storage.
        /// </summary>
        /// <param name="fileUri">Uri fo eth file to get the hash for.</param>
        /// <returns>A string representation of the MD5 hash for the file.</returns>
        string GetFileMD5Hash(Uri fileUri);
    }
}
