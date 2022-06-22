﻿// <auto-generated />
//
// To parse this JSON data, add NuGet 'Newtonsoft.Json' then do:
//
//    using NiblJson;
//
//    var niblBotList = NiblBotList.FromJson(jsonString);
using System;
using System.Collections.Generic;

using System.Globalization;
using Newtonsoft.Json;
using Newtonsoft.Json.Converters;

namespace NiblJson
{

    public partial class NiblBotList
    {
        [JsonProperty("status", NullValueHandling = NullValueHandling.Ignore)]
        public string Status { get; set; }

        [JsonProperty("message", NullValueHandling = NullValueHandling.Ignore)]
        public string Message { get; set; }

        [JsonProperty("content", NullValueHandling = NullValueHandling.Ignore)]
        public List<NiblBot> NiblBots { get; set; }
    }

    public partial class NiblBot
    {
        [JsonProperty("id", NullValueHandling = NullValueHandling.Ignore)]
        public long? Id { get; set; }

        [JsonProperty("name", NullValueHandling = NullValueHandling.Ignore)]
        public string Name { get; set; }

        [JsonProperty("owner")]
        public string Owner { get; set; }

        [JsonProperty("lastProcessed", NullValueHandling = NullValueHandling.Ignore)]
        public DateTimeOffset? LastProcessed { get; set; }

        [JsonProperty("batchEnable", NullValueHandling = NullValueHandling.Ignore)]
        public long? BatchEnable { get; set; }

        [JsonProperty("packSize", NullValueHandling = NullValueHandling.Ignore)]
        public long? PackSize { get; set; }
    }

    public partial class NiblBotList
    {
        public static NiblBotList FromJson(string json) => JsonConvert.DeserializeObject<NiblBotList>(json, NiblJson.Converter.Settings);
    }

    public static class Serialize
    {
        public static string ToJson(this NiblBotList self) => JsonConvert.SerializeObject(self, NiblJson.Converter.Settings);
    }

    internal static class Converter
    {
        public static readonly JsonSerializerSettings Settings = new JsonSerializerSettings
        {
            MetadataPropertyHandling = MetadataPropertyHandling.Ignore,
            DateParseHandling = DateParseHandling.None,
            Converters =
            {
                new IsoDateTimeConverter { DateTimeStyles = DateTimeStyles.AssumeUniversal }
            },
        };
    }
}