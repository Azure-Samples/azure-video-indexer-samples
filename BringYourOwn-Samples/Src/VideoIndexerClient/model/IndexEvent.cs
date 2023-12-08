#pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider declaring as nullable.
namespace VideoIndexerClient.model
{
    public class IndexingProperties
    {
        public string Language{ get; set; }
        public string Privacy{ get; set; }
        public string Filename{ get; set; }
        public string RetentionInDays{ get; set; }
        public string ExternalId{ get; set; }
    }

    public class IndexEventProperties
    {
        public string accountName{ get; set; }
        public string accountId{ get; set; }
        public string videoId{ get; set; }
        public IndexingProperties indexing{ get; set; }
    }

    public class IndexEventRecord
    {
        public string operationName{ get; set; }
        public string category{ get; set; }
        public string resultType{ get; set; }
        public IndexEventProperties properties{ get; set; }
    }

    public class IndexEvent
    {
        public IndexEventRecord[] records{ get; set; }
    }
    
}
