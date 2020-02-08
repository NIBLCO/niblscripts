using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace NIBLSearchWPF
{
    public class Bots
    {
        public Dictionary<ulong, string> BotDictionary;

        public List<ViewablePack> Packs;

        public Bots()
        {
            BotDictionary = new Dictionary<ulong, string>();
            Packs = new List<ViewablePack>();
        }
    }
}
