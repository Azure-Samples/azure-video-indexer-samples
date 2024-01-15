#pragma warning disable CS8618 
namespace VideoIndexerClient.model
{
    ////////////////////////////
    /// Artifacts Data Model /// 
    ///////////////////////////

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
}
