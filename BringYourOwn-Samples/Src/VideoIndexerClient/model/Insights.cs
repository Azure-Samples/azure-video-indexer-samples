#pragma warning disable CS8618 

namespace VideoIndexerClient.model
{
    ////////////////////////////
    /// Insights Data Model /// 
    ///////////////////////////
    
    public class Insights
    {
        public string AccountId { get; set; }
        public string Id { get; set; }
        public string Name { get; set; }
        public string State { get; set; }
        public List<VideoInsights> Videos { get; set; }
        public bool HasCustomInsights => Videos.Any(videoInsight => videoInsight?.Insights?.CustomInsights?.Count > 0);
    }

    public class VideoInsights
    {
        public VideoIndexInsights Insights { get; set; }
    }

    public class VideoIndexInsights
    {
        public List<DetectedObjectInsights> DetectedObjects { get; set; } 
        public List<CustomInsights> CustomInsights { get; set; }
    }

    public class DetectedObjectInsights
    {
        public int Id { get; set; }
        public string Type { get; set; }
        public string ThumbnailId { get; set; }
        public List<Instance> Instances { get; set; }

        public List<StartEndPair> TimePairs =>  Instances.Select(instance => new StartEndPair { StartTime = instance.Start, EndTime = instance.End }).ToList();

    }
}
