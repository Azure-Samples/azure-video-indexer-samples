using Newtonsoft.Json;
using Newtonsoft.Json.Converters;

namespace VideoIndexerClient.model
{
    public class FrameUriData
    {
        public FrameUriData(string name, int frameIndex, TimeSpan startTime, TimeSpan endTime, string filePath)
        {
            Name = name;
            FrameIndex = frameIndex;
            StartTime = startTime;
            EndTime = endTime;
            FilePath = filePath;
        }

        public string Name { get; set; }
        public int FrameIndex { get; set; }
        public TimeSpan StartTime { get; set; }
        public TimeSpan EndTime { get; set; }
        public string FilePath { get; set; }
    }

    public class FramesUrisResult
    {
        public FrameUriData[] Results { get; set; } = Array.Empty<FrameUriData>();
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


    public class Contracts
    {
        public class FlorenceResults
        {
            public string Kind { get; set; }
            public Metadata Metadata { get; set; }
            public CustomModelResult? CustomModelResult { get; set; }
        }

        public class Metadata
        {
            public int Height { get; set; }
            public int Width { get; set; }
        }

        public class CustomModelResult
        {
            public List<object> Classifications { get; set; }
            public List<Object> Objects { get; set; }
            public Metadata ImageMetadata { get; set; }
        }

        public class Object
        {
            public string Id { get; set; }
            public BoundingBox BoundingBox { get; set; }
            public List<Classification> Classifications { get; set; }
        }

        public class BoundingBox
        {
            public int X { get; set; }
            public int Y { get; set; }
            public int W { get; set; }
            public int H { get; set; }
        }

        public class Classification
        {
            public double Confidence { get; set; }
            public string Label { get; set; }
        }

    }

    
    public class CustomInsights
    {
        [JsonRequired]
        public string Name { get; set; }

        [JsonProperty(NullValueHandling = NullValueHandling.Ignore)]
        public string DisplayName { get; set; }

        [JsonConverter(typeof(StringEnumConverter))]
        public DisplayType DisplayType { get; set; } = DisplayType.Capsule;

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
    public class Artifact
    {
        public string AlgoVersion { get; set; }
        public string SchemaVersion { get; set; }
        public ArtifactResult[] Results { get; set; }
    }
    public class ArtifactResult
    {
        public int Id { get; set; }
        public string ClassName { get; set; }
        public string Type { get; set; }
        public string WikiDataID { get; set; }
        public Instance[] Instances { get; set; }
    }

    public class Instance
    {
        public double X { get; set; }
        public double Y { get; set; }
        public double Width { get; set; }
        public double Height { get; set; }
        public int Frame { get; set; }
        public TimeSpan Start { get; set; }
        public TimeSpan End { get; set; }
        public TimeSpan AdjustedStart { get; set; }
        public TimeSpan AdjustedEnd { get; set; }
        public double Confidence { get; set; }
        public bool IsBest { get; set; }
    }

    public enum DisplayType
    {
        Capsule, //For Flags
        CapsuleAndTags
    }

}
