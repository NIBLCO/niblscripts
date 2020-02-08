using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace NIBLSearchWPF
{
    public class ViewablePack
    {
        [JsonProperty("botName")]
        public string BotName { get; set; }

        [JsonProperty("name")]
        public string Name { get; set; }

        [JsonProperty("number")]
        public long Number { get; set; }

        [JsonProperty("size")]
        public string Size { get; set; }
    }
}
