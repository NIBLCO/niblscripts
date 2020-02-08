using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using NiblJson;
using NiblJsonPackList;
using NiblSearchWPF;

namespace NIBLSearchWPF
{
    public class NiblSearchService
    {
        private NiblSearchClient niblSearchClient;

        public Dictionary<long, string> botList;
        public Dictionary<long, NiblBot> niblBotList;
        public List<string> botsViewable;

        public NiblPackListModel Model;


        public string NextPage = "";
        public string PreviousPage = "";
        public string CurrentPage = "";
        public int ActivePage = 1;

        public int TotalResults = 0;
        public int TotalPages = 0;
        public int ResultsPerPage = 0;

        public int? BotId = null;

        public string SearchTerms = "";

        public NiblSearchService(NiblPackListModel model)
        {
            niblSearchClient = new NiblSearchClient();
            botList = new Dictionary<long, string>();
            botsViewable = new List<string>();
            niblBotList = new Dictionary<long, NiblBot>();
            Model = model;
        }

        public async Task<ObservableCollection<string>> GetBotsAsync()
        {
            var bots = await niblSearchClient.GetBotListAsync();

            botList.Clear();
            botsViewable.Clear();
            niblBotList.Clear();

            bots.ForEach(x =>
            {
                botList.Add((long)x.Id, x.Name);
                botsViewable.Add(x.Name);
                niblBotList.Add((long)x.Id, x);
            });

            botsViewable.Insert(0, "All");

            return new ObservableCollection<string>(botsViewable);
        }

        public async Task SearchBotsDeepAsync(string search, string page = null, int? botId = null, int size = 10, int epNumber = -1, string specificPage = null, bool ascendingSort = true, NiblOrderBy orderby = NiblOrderBy.FileName)
        {
            NextPage = "";
            PreviousPage = "";
            CurrentPage = "";
            SearchTerms = "";
            TotalResults = 0;
            TotalPages = 0;


            NiblPackList list;
            //await GetBotsAsync();
            try
            {
                if (botList.Count() == 0)
                {
                    await GetBotsAsync();
                }
                list = await niblSearchClient.SearchPackListFullAsync(search, page, botId, size, epNumber, specificPage, ascendingSort, orderby).ConfigureAwait(false);

            }
            catch (Exception exception)
            {
                throw new Exception($"{exception.Message}");
            }
            SearchTerms = search;
            NextPage = list.Next;
            PreviousPage = list.Previous;
            CurrentPage = list.Current;

            TotalResults = (int)list.Total;
            TotalPages = ((int)list.Total / size);
            if ((list.Total % size) > 0)
                TotalPages++;

            string value = HttpUtility.ParseQueryString(list.Current).Get("page");
            ActivePage = Convert.ToInt32(value) + 1;
            ResultsPerPage = ((int)list.Max);
            BotId = botId;

            var withName = list.PackList.Select(x => new SimplePack((long)x.BotId, botList[(long)x.BotId], x.Name, x.Size, (long)x.Number));
            Model.SimpleCollection = new ObservableCollection<SimplePack>(withName);


            return;
        }

        public async Task GetNextPageAsync(bool ascendingSort = true, NiblOrderBy orderby = NiblOrderBy.FileName)
        {
            if (string.IsNullOrEmpty(NextPage))
                throw new Exception("The next page is not available.");

            await SearchBotsDeepAsync(SearchTerms, page: NextPage, size: ResultsPerPage, botId: BotId, ascendingSort: ascendingSort, orderby: orderby);
        }

        public async Task GetPreviousPageAsync(bool ascendingSort = true, NiblOrderBy orderby = NiblOrderBy.FileName)
        {
            if (string.IsNullOrEmpty(PreviousPage))
                throw new Exception("The previous page is not available.");

            await SearchBotsDeepAsync(SearchTerms, page: PreviousPage, size: ResultsPerPage, botId: BotId, ascendingSort: ascendingSort, orderby: orderby);
        }

        public async Task GoToPageAsync(int page, bool ascendingSort = true, NiblOrderBy orderby = NiblOrderBy.FileName)
        {
            --page;
            if (page <= TotalPages && page >= 0)
            {
                string newpage = CurrentPage;
                var parse = HttpUtility.ParseQueryString(newpage);
                parse.Set("page", page.ToString());
                newpage = parse.ToString();

                await SearchBotsDeepAsync(SearchTerms, page: newpage, size: ResultsPerPage, botId: BotId, ascendingSort: ascendingSort, orderby: orderby);
            }
        }

        public long GetBotIdFromName(string name)
        {
            if (!botList.ContainsValue(name))
                throw new Exception($"No ID can be found for bot: {name}");
            return botList.First(x => x.Value == name).Key;
        }
    }
}
