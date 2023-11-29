﻿using System.Text.Json.Serialization;

namespace VideoIndexerClient.model;

public class Video
{
    [JsonPropertyName("id")]
    public string Id { get; set; }

    [JsonPropertyName("state")]
    public string State { get; set; }
}