using Newtonsoft.Json;
using Newtonsoft.Json.Converters;
#pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider declaring as nullable.

namespace VideoIndexerClient.model
{
    public class StartEndPair
    {
        public TimeSpan StartTime { get; set; }
        public TimeSpan EndTime { get; set; }
    }

    public class FrameData
    {
        public FrameData(string name, int frameIndex, string filePath, List<StartEndPair> startEndPairs )
        {
            Name = name;
            FrameIndex = frameIndex;
            FilePath = filePath;
            StartEndPairs = startEndPairs;
        }

        public string Name { get; set; }
        public int FrameIndex { get; set; }
        public List<StartEndPair> StartEndPairs { get; set; }
        public string FilePath { get; set; }
    }


    public class FramesUrisResult
    {
        public FrameData[] Results { get; set; } = Array.Empty<FrameData>();
        public PagingInfo NextPage { get; set; }
    }

    public class PagingInfo
    {
        public int PageSize { get; set; }
        public int Skip { get; set; }
        public bool Done { get; set; }

        public PagingInfo()
        {
            PageSize = 25;
        }

        public PagingInfo(int pageSize, int lastSkip, int totalResultsCount)
        {
            Done = lastSkip + pageSize >= totalResultsCount;
            PageSize = pageSize;

            if (Done)
            {
                Skip = lastSkip;
            }
            else
            {
                Skip = lastSkip + pageSize;
            }
        }
    }

    public class CustomInsights
    {
        [JsonRequired]
        public string Name { get; set; }

        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public string DisplayName { get; set; }

        [JsonConverter(typeof(StringEnumConverter))]
        public DisplayType DisplayType { get; set; } = DisplayType.CapsuleAndTags;

        [JsonRequired]
        public CustomInsightResult[] Results { get; set; }
    }

    public class CustomInsightResult
    {
        [JsonRequired]
        public string Type { get; set; }

        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public string SubType { get; set; }

        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public string Metadata { get; set; }

        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public string WikiDataId { get; set; }

        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public int Id { get; set; }
        public Instance[] Instances { get; set; } = Array.Empty<Instance>();
    }

    ///////////////////////
    /// Artifacts
    ///////////////////////
    

    public class Instance
    {
        public TimeSpan Start { get; set; }
        public TimeSpan End { get; set; }
        public TimeSpan AdjustedStart { get; set; }
        public TimeSpan AdjustedEnd { get; set; }
        public double Confidence { get; set; }
    }

    public enum DisplayType
    {
        Capsule, //For Flags
        CapsuleAndTags
    }

}
