using System;
using EnrichmentPipeline.Functions.Domain.Constants;
using EnrichmentPipeline.Functions.Domain.Interfaces;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace EnrichmentPipeline.Functions.Domain.Services.Tests
{
    /// <summary>
    /// Tests for BlobInfoFactoryService.
    /// </summary>
    public class BlobInfoFactoryServiceTests
    {
        /// <summary>
        /// Test for creation of BlobInfo object.
        /// </summary>
        [Fact]
        public void CreateBlobInfo_WhenCalledWithValidParamaters_ReturnsACorrectlyConstructedBlobInfo()
        {
            var mockFileStorageService = new Mock<IFileStorageService>();
            mockFileStorageService.Setup(s => s.GenerateSASUri(It.IsAny<Uri>(), It.IsAny<TimeSpan>()))
                .Returns(UnitTestExtensions.TestUri);
            mockFileStorageService.Setup(s => s.GetFileMD5Hash(UnitTestExtensions.TestUri))
                .Returns(UnitTestExtensions.TestHashValue);

            var mockLogger = new Mock<ILogger<BlobInfoFactoryService>>();

            var mockSystemInfoService = new Mock<ISystemInfoService>();

            var bifs = new BlobInfoFactoryService(mockFileStorageService.Object, mockLogger.Object, mockSystemInfoService.Object);

            Models.BlobInfo blobInfo = bifs.CreateBlobInfo(UnitTestExtensions.TestUri,
                UnitTestExtensions.TestFilename,
                UnitTestExtensions.TestCorrelationId);

            Assert.NotNull(blobInfo.CanonicalUri);
            Assert.Equal(UnitTestExtensions.TestCorrelationId, blobInfo.CorrelationId);
            Assert.Equal(UnitTestExtensions.TestFilename, blobInfo.FileName);
            Assert.Equal("image", blobInfo.FileCategory);
            Assert.NotNull(blobInfo.SasUri);
            Assert.True(blobInfo.SasExpiry > DateTime.UtcNow);
            Assert.Equal(UnitTestExtensions.TestHashValue, blobInfo.Hash);
        }

        /// <summary>
        /// CreateBlobInfo_WhenCalledWithFileName_ReturnsCorrectsFileCategory.
        /// </summary>
        [Theory]
        [InlineData("bibble/testFile.wav" , "audio")]
        [InlineData("bibble/testFile.mp4", "video")]
        [InlineData("bibble/testFile.txt", "digitaltext")]
        [InlineData("bibble/testFile.pdf", "unknown")]
        [InlineData("bibble/testFile.png", "image")]
        public void CreateBlobInfo_WhenCalledWithAudioFile_ReturnsCorrectsFileCategory(string fileName , string fileCategory)
        {
            var mockFileStorageService = new Mock<IFileStorageService>();
            mockFileStorageService.Setup(s => s.GenerateSASUri(It.IsAny<Uri>(), It.IsAny<TimeSpan>()))
                .Returns(UnitTestExtensions.TestUri);

            var mockLogger = new Mock<ILogger<BlobInfoFactoryService>>();

            var mockSystemInfoService = new Mock<ISystemInfoService>();

            var bifs = new BlobInfoFactoryService(mockFileStorageService.Object, mockLogger.Object, mockSystemInfoService.Object);

            Models.BlobInfo blobInfo = bifs.CreateBlobInfo(UnitTestExtensions.TestUri,
                fileName,
                UnitTestExtensions.TestCorrelationId);

            Assert.Equal(fileCategory, blobInfo.FileCategory);
        }

    }
}
