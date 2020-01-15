using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace VideoDescription.Models
{
    public class BlobInfo
    {
        public string ImageUri { get; set; }
        public string ThumbnailUri { get; set; }
        public string Description { get; set; }
        public string DescriptionTranslated { get; set; }
        public string Confidence { get; set; }
        public TimeSpan? AdjustedStart { get; set; }
        
    }
}