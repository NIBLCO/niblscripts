using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using NiblJson;
using NiblJsonPackList;

namespace NIBLSearchWPF
{
    public class NiblSearchClient
    {

        private List<NiblBot> botList;
        private Dictionary<long, string> botDict;



        // Fetch Botlist.
        //
        public async Task<List<NiblBot>> GetBotListAsync()
        {
            // URL: https://api.nibl.co.uk:8080/nibl/bots
            using (var client = new HttpClient())
            {
                var data = await client.GetStringAsync("https://api.nibl.co.uk/nibl/bots").ConfigureAwait(false);
                var nibl = NiblBotList.FromJson(data);
                if (nibl.Status != "OK") throw new Exception("Bot list not available");
                return nibl.NiblBots;
            }
        }

        // Get Latest
        public async Task<List<NiblPack>> GetLatestPacksAsync()
        {
            using (var client = new HttpClient())
            {
                var data = await client.GetStringAsync("https://api.nibl.co.uk/nibl/latest?size=10").ConfigureAwait(false);
                var nibl = NiblPackList.FromJson(data);
                if (nibl.Status != "OK") throw new Exception("Bot list not available");
                return nibl.PackList;
            }
        }

        public async Task<List<NiblPack>> SearchPackListsAsync(string search, string page = null, int? botId = null, int size = 10, int epNumber = -1)
        {
            var packlist = await SearchPackListFullAsync(search, page, botId, size, epNumber);
            return packlist.PackList;
        }

        public async Task<NiblPackList> SearchPackListFullAsync(string search, string page = null, int? botId = null, int size = 10, int epNumber = -1, string specificPage = null, bool ascendingSort = true, NiblOrderBy order = NiblOrderBy.FileName)
        {
            using (var client = new HttpClient())
            {
                var botadd = (botId == null) ? string.Empty : $"{((int)botId).ToString()}/";
                string sortOrder = (ascendingSort) ? "ASC" : "DESC";
                string orderby;
                switch (order)
                {
                    case NiblOrderBy.BotId:
                        orderby = "botId"; break;
                    case NiblOrderBy.FileName:
                        orderby = "name"; break;
                    case NiblOrderBy.FileSize:
                        orderby = "sizekbits"; break;
                    case NiblOrderBy.PackName:
                        orderby = "number"; break;
                    default:
                        orderby = "name"; break;
                }
                var baseurl = $"https://api.nibl.co.uk/nibl/search/{botadd}page?query={search}&episodeNumber={epNumber}&page=0&size={size}&sort={orderby}&direction={sortOrder}";
                if (page != null)
                    baseurl = $"https://api.nibl.co.uk/nibl/search/{botadd}page?{page}";
                if (specificPage != null)
                    baseurl = $"https://api.nibl.co.uk/nibl/search/{botadd}page?query={search}&episodeNumber={epNumber}&page=0&size={size}&sort={orderby}&direction={sortOrder}";

                var data = await client.GetStringAsync(baseurl).ConfigureAwait(false);
                var nibl = NiblPackList.FromJson(data);
                if (nibl.Status != "OK") throw new Exception("Bot search not available");
                return nibl;
            }
        }
    }
}
