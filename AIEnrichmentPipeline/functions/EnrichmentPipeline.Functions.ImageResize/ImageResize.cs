using System;
using System.IO;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Formats.Jpeg;
using SixLabors.ImageSharp.Processing;
using EnrichmentPipeline.Functions.Domain.Models;
using System.Diagnostics.CodeAnalysis;
using EnrichmentPipeline.Functions.Domain.Extensions;

namespace EnrichmentPipeline.Functions.ImageResize
{
    // This is a temporary pragramtic solution which is far from perfect but resolves an issue for the time being
    // future work detailed below could be done to improve it or it can be removed once the v3 API goes GA.
    public class ImageResize
    {
        private const string FunctionName = "ImageResize";
        private const string ReturnedContentType = "image/jpg";
        private const int ResizeToWidthPixels = 2000;

        /// <summary>
        /// The main entry point for the function.
        /// </summary>
        /// <param name="req">The HttpRequest.</param>
        /// <param name="log">The Logger.</param>
        /// <returns>A <see cref="Task"/> representing the asynchronous operation.</returns>
        [FunctionName(FunctionName)]
        [ExcludeFromCodeCoverage] //Mostly using the ImageSharp SDK so not worth testing.
        public IActionResult Run([HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req, ILogger log)
        {
            // Configure logging
            ScopedData data = new ScopedData();
            if (data.InitialiseFromRequestHeaders(req))
            {
                data.Apply();
            }
            try
            {
                log.LogInformation("{functionName}: Image resize starting", FunctionName);

                using Image image = Image.Load(req.Body);

                // Note we don't dispose this stream on purpose as it's used by the http server plumbing to serve the reponse.
                MemoryStream output = new MemoryStream();

                // Resize things down to a max width of x to ensure they're small enough for cog services
                if (image.Width > ResizeToWidthPixels)
                {
                    // If you pass 0 as any of the values for width and height dimensions then ImageSharp will automatically determine the correct opposite dimensions size to preserve the original aspect ratio.
                    // https://docs.sixlabors.com/articles/imagesharp/resize.html
                    image.Mutate(x => x.Resize(ResizeToWidthPixels, 0));
                }
                image.Save(output, new JpegEncoder());
                output.Position = 0;
                log.LogInformation("{functionName}: Image resize complete sending result", FunctionName);

                return new FileStreamResult(output, ReturnedContentType);
            }
            catch (Exception ex)
            {
                log.LogError(ex, "{functionName}: Failed to resize image", FunctionName);
                ObjectResult internalErrorResponse = new ObjectResult($"Failed while attempting to resize image: {ex.Message}")
                {
                    // Ensure a 500 response code as likely to be retryable error
                    StatusCode = 500
                };
                return internalErrorResponse;
            }
            finally
            {
                log.LogInformation("{functionName}: Completed", FunctionName);
            }
        }
    }
}
