# Digital Text File Workflow

## Known Limitations
The  workflow has some known limitations.

### 5120 chars limit
There is a known limitation with this workflow for files containing more than 5120 characters. These files will not be enriched, but the workflow will still succeed.

This is due to an underlying limitation in the Cognitive Services Text Analytics API will has an upper limit of 5120 characters per request. This is measured by StringInfo.LengthInTextElements, see [data and rate limits](https://docs.microsoft.com/en-us/azure/cognitive-services/text-analytics/concepts/data-limits?tabs=version-3).

The solution would be to add a "chunking" mechanism (a custom Azure Function?) to divide the blob contents into strings of a suitable length and then submit them to the Text Analytics API and concatinate the results. However, ths is not in scope at the time of writing.

We have investigated whether the Logic App Text Analytics Connector does this automatically - it does not.

### Raw text files only
The workflow only currently supports raw text files such as TXT, MD, HTML, RTF.

Rich text files such as Word, Excel, PowerPoint, PDF are not supported.

This is because we do not yet have a solution for document cracking, so we cannot open the file contents in order to send them as a string to Cognitive Services Text Analytics API.

The workflow will succeeed with these file types, but no enrichments will be generated.
