using System;
using EnrichmentPipeline.Functions.Domain.Constants;
using EnrichmentPipeline.Functions.Domain.Interfaces;
using Moq;
using Xunit;

namespace EnrichmentPipeline.Functions.Domain.Services.Tests
{
    /// <summary>
    /// Test Class for DataLakeStorage implementation of IFileStorageService.
    /// </summary>
    public class FileStorageServiceTests
    {
        /// <summary>
        /// Generate a Uri for blob.
        /// </summary>
        [Fact]
        public void BuildUriForBlob_GivenValidFileName_ReturnValidUri()
        {
            string endpoint = UnitTestExtensions.TestUri.ToString();
            string containerName = "testContainer";
            string fileName = "testFile";

            Uri uri = FileStorageService.BuildUriForBlob(endpoint, containerName, fileName);

            Assert.Equal("https://www.bing.com/testContainer/testFile.json", uri.ToString());
        }

        /// <summary>
        /// Generates a hash for a given Uri.
        /// </summary>
        [Fact]
        public void GetFileMD5Hash_GivenValidFileUri_ReturnValidHash()
        {
            var storageMock = new Mock<IFileStorageService>();
            storageMock.Setup(s => s.GetFileMD5Hash(UnitTestExtensions.TestUri))
                .Returns(UnitTestExtensions.TestHashValue);

            string hash = storageMock.Object.GetFileMD5Hash(UnitTestExtensions.TestUri);

            Assert.Equal(UnitTestExtensions.TestHashValue, hash);
        }

    }
}
