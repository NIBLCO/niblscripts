using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using AdiIRCAPIv2.Interfaces;
using NIBLSearchWPF;

namespace NiblSearchWPF
{
    /// <summary>
    /// Interaction logic for UserControl1.xaml
    /// </summary>
    public partial class NiblSearchWindow : Window
    {
        public NiblSearchService _searchService;
        public NiblPackListModel Model;
        public PackQueueClient _packQueueClient;
        public IPluginHost _host;
        public string initialSearch = "";
        public NiblSearchWindow()
        {
            InitializeComponent();
        }
        public NiblSearchWindow(IPluginHost host, NiblSearchService niblService, NiblPackListModel model, PackQueueClient packQueueClient, bool trustBots, bool retryDownload, string searchTerms)
        {
            _searchService = niblService;
            Model = model;
            _host = host;
            _packQueueClient = packQueueClient;
            initialSearch = searchTerms;

            InitializeComponent();
            dataGrid.ItemsSource = Model.SimpleCollection;
            botListComboBox.ItemsSource = Model.BotCollection;
            _searchService = new NiblSearchService(Model);
            if (trustBots)
                trustBotsCheckBox.IsChecked = true;
            if (retryDownload)
                retryDLCheckBox.IsChecked = true;
        }

        private async void button_Click(object sender, RoutedEventArgs e)
        {
            await PerformSearch(async () =>
            {
                if (botListComboBox.SelectedIndex == 0)
                {
                    await _searchService.SearchBotsDeepAsync(searchTextBox.Text, size: 25, ascendingSort: GetAscOrDescSort(), orderby: GetOrderBySort());
                }
                else
                {
                    await _searchService.SearchBotsDeepAsync(searchTextBox.Text, botId: (int?)_searchService.GetBotIdFromName((string)botListComboBox.SelectedItem), size: 25, ascendingSort: GetAscOrDescSort(), orderby: GetOrderBySort());
                }
            });
        }

        private async void Window_Loaded(object sender, RoutedEventArgs e)
        {
            botListComboBox.ItemsSource = null;
            var bots = await _searchService.GetBotsAsync();
            Model.BotCollection = bots;
            botListComboBox.ItemsSource = Model.BotCollection;
            botListComboBox.SelectedIndex = 0;
            searchTextBox.Focus();
            searchTextBox.Text = initialSearch;
            if (!string.IsNullOrEmpty(initialSearch))
            {
                await PerformSearch(async () =>
                {
                    if (botListComboBox.SelectedIndex == 0)
                    {
                        await _searchService.SearchBotsDeepAsync(searchTextBox.Text, size: 25, ascendingSort: GetAscOrDescSort(), orderby: GetOrderBySort());
                    }
                    else
                    {
                        await _searchService.SearchBotsDeepAsync(searchTextBox.Text, botId: (int?)_searchService.GetBotIdFromName((string)botListComboBox.SelectedItem), size: 25, ascendingSort: GetAscOrDescSort(), orderby: GetOrderBySort());
                    }
                });
            }
            initialSearch = "";
        }

        private void closeButton_Click(object sender, RoutedEventArgs e)
        {
            this.Close();
        }

        private async void getNextPageButton_Click(object sender, RoutedEventArgs e)
        {
            await PerformSearch(async () =>
            {
                await _searchService.GetNextPageAsync();
            });
        }

        private async void getPreviousPageButton_Click(object sender, RoutedEventArgs e)
        {
            await PerformSearch(async () =>
            {
                await _searchService.GetPreviousPageAsync();
            });
        }

        private void niblWebsiteButton_Click(object sender, RoutedEventArgs e)
        {
            System.Diagnostics.Process.Start("https://nibl.co.uk/");

        }

        private async void MenuItem_Click(object sender, RoutedEventArgs e)
        {
            SimplePack pack = (SimplePack)dataGrid.SelectedItem;
            int index = Model.BotCollection.IndexOf(pack.Name);
            botListComboBox.SelectedIndex = index;
            await PerformSearch(async () =>
            {
                if (botListComboBox.SelectedIndex == 0)
                {
                    await _searchService.SearchBotsDeepAsync(searchTextBox.Text, size: 25, ascendingSort: GetAscOrDescSort(), orderby: GetOrderBySort());
                }
                else
                {
                    await _searchService.SearchBotsDeepAsync(searchTextBox.Text, botId: (int?)_searchService.GetBotIdFromName(pack.Name), size: 25, ascendingSort: GetAscOrDescSort(), orderby: GetOrderBySort());
                }
            });
        }

        private async Task PerformSearch(Func<Task> theSearch)
        {
            try
            {
                button.IsEnabled = false;
                getNextPageButton.IsEnabled = false;
                getPreviousPageButton.IsEnabled = false;

                await theSearch();

                dataGrid.ItemsSource = null;
                dataGrid.ItemsSource = Model.SimpleCollection;
                if (!string.IsNullOrEmpty(_searchService.NextPage))
                    getNextPageButton.IsEnabled = true;
                if (!string.IsNullOrEmpty(_searchService.PreviousPage))
                    getPreviousPageButton.IsEnabled = true;

                //gotoPageButton.Content = $"Page: {_searchService.ActivePage} / {_searchService.TotalPages}";
                textBoxCurrentPage.Text = _searchService.ActivePage.ToString();
                textBoxTotalPages.Text = _searchService.TotalPages.ToString();

                dataGrid.ScrollIntoView(dataGrid.Items[0]);
                dataGrid.UpdateLayout();


            }
            catch (Exception except)
            {
                MessageBox.Show("Error", $"No search results...\r\nMessage: {except.Message}");
            }
            finally
            {
                button.IsEnabled = true;
            }
        }

        private bool GetAscOrDescSort()
        {
            if (orderByDirectionComboBox.SelectedIndex == 0)
                return true;
            return false;
        }

        private NiblOrderBy GetOrderBySort()
        {
            NiblOrderBy orderby;
            switch (orderByTypeComboBox.SelectedIndex)
            {
                // id name size number
                case 0:
                    orderby = NiblOrderBy.BotId; break;
                case 1:
                    orderby = NiblOrderBy.FileName; break;
                case 2:
                    orderby = NiblOrderBy.FileSize; break;
                case 3:
                    orderby = NiblOrderBy.PackName; break;
                default:
                    orderby = NiblOrderBy.FileName; break;
            }
            return orderby;
        }

        private async void gotoButton_Click(object sender, RoutedEventArgs e)
        {
            if (int.TryParse(textBoxCurrentPage.Text, out int suggestedPage))
            {
                if (suggestedPage <= _searchService.TotalPages)
                {
                    await PerformSearch(async () =>
                    {
                        await _searchService.GoToPageAsync(suggestedPage, GetAscOrDescSort(), GetOrderBySort());
                    });
                }
                else
                {
                    MessageBox.Show("You entered an invalid page number.", "Error: Invalid number.");
                }
            }
            else
            {
                MessageBox.Show("You entered an invalid page number.", "Error: Invalid number.");
            }
        }

        private void getFileButton_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                getFileButton.IsEnabled = false;
                // Confirm that we are on the NIBL Server.
                if (!IsOnNetworkAndChannel("Rizon", "#nibl"))
                {
                    MessageBox.Show("Connect to the Rizon IRC network and join #nibl.\r\nYou can click the Join NIBL button to do this for you.");
                    return;
                }

                var chan = GetChannelFromNetworkAndChannel("Rizon", "#nibl");

                int timer = 1;
                var selected = dataGrid.SelectedItems.Cast<SimplePack>();
                var groups = selected.GroupBy(x => x.Id);
                foreach (var group in groups)
                {
                    if (IsBotBatchEnabled(group.Key))
                    {
                        StringBuilder sb = new StringBuilder();
                        string botName = "";
                        foreach (var pack in group)
                        {
                            try
                            {
                                _packQueueClient.AddToQueue(pack);
                            }
                            catch
                            {
                                throw new Exception("WTF IS THIS!");
                            }
                            sb.Append($"{pack.PackNumber},");
                            botName = pack.Name;
                        }
                        sb.Remove(sb.Length - 1, 1);
                        var botAddress = chan.Evaluate($"$address({botName},8)", "");
                        _packQueueClient.AddTrust(botName);
                        chan.ExecuteCommand($"/.timer 1 {timer} /msg {botName} xdcc batch {sb}");
                        timer += 8;
                    }
                    else
                    {
                        foreach (var pack in group)
                        {
                            try
                            {
                                _packQueueClient.AddToQueue(pack);
                            }
                            catch
                            {
                                throw new Exception("WTF IS THIS!");
                            }
                            _packQueueClient.AddTrust(pack.Name);
                            chan.ExecuteCommand($"/.timer 1 {timer} /msg {pack.Name} xdcc send {pack.PackNumber}");
                            timer += 8;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"{ex.Message}");
            }
            finally
            {
                getFileButton.IsEnabled = true;
            }

        }

        private List<IServer> GetServersList()
        {
            var servers = _host.GetServers.Cast<IServer>().ToList();
            return servers;

            /*
            List<IServer> servers = new List<IServer>();
            foreach (var server in _host.GetServers)
            {
                var serv = server as IServer;
                servers.Add(serv);
            }
            return servers;*/
        }

        private List<IChannel> GetChannelList(IServer server)
        {
            var channels = server.GetChannels.Cast<IChannel>().ToList();
            return channels;
        }

        private IServer GetFirstServer()
        {
            return GetServersList().First();
        }

        private bool IsOnNetworkAndChannel(string network, string channel)
        {
            network = network.ToLower(); channel = channel.ToLower();
            var servers = GetServersList().Where(server => server.Network.ToLower() == network && server.IsConnected);
            if (servers == null || servers.Count() == 0)
                return false;

            var channels = servers.Where(server => GetChannelList(server).Any(chan => chan.Name.ToLower() == channel));
            if (channels == null || channels.Count() == 0)
                return false;
            return true;
        }

        private IChannel GetChannelFromNetworkAndChannel(string network, string channel)
        {
            if (!IsOnNetworkAndChannel(network, channel))
                throw new Exception($"Error:  Not connected to the network \"{network}\" and on channel \"{channel}\".");

            network = network.ToLower(); channel = channel.ToLower();
            var servers = GetServersList().Where(serv => serv.Network.ToLower() == network && serv.IsConnected);
            var server = servers.FirstOrDefault(serv => GetChannelList(serv).Any(chann => chann.Name.ToLower() == channel));
            var chan = GetChannelList(server).First(c => c.Name.ToLower() == channel);

            return chan;
        }

        private bool IsOnNetwork(string network)
        {
            var servers = GetServersList();
            if (!servers.Any(server => server.Network == network && server.IsConnected))
                return false;
            return true;
        }

        private async void joinNIBLButton_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                joinNIBLButton.IsEnabled = false;
                if (!IsOnNetwork("Rizon"))
                {
                    GetFirstServer().ExecuteCommand("/server -m irc.rizon.net -j #nibl");
                }
                else
                {
                    var server = GetServersList().First(serv => serv.Network.ToLower() == "Rizon" && serv.IsConnected);
                    server.ExecuteCommand("/join #nibl");
                }
                await Task.Delay(15000);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"{ex.Message}");
            }
            finally
            {
                joinNIBLButton.IsEnabled = true;
            }
        }

        private bool IsBotBatchEnabled(long id)
        {
            var test = _searchService.niblBotList[id].BatchEnable;
            if (test == null || test == 0) return false;
            else return true;
        }

        private async void reloadBotsButton_Click(object sender, RoutedEventArgs e)
        {
            reloadBotsButton.IsEnabled = false;
            botListComboBox.ItemsSource = null;
            var bots = await _searchService.GetBotsAsync();
            Model.BotCollection = bots;
            botListComboBox.ItemsSource = Model.BotCollection;
            botListComboBox.SelectedIndex = 0;
            reloadBotsButton.IsEnabled = true;
        }

        private void trustBotsCheckBox_Checked(object sender, RoutedEventArgs e)
        {
            GetFirstServer().ExecuteCommand("set %nibl.trustbots true");
        }

        private void retryDLCheckBox_Checked(object sender, RoutedEventArgs e)
        {

            GetFirstServer().ExecuteCommand("set %nibl.retryDL true");
        }

        private void trustBotsCheckBox_Unchecked(object sender, RoutedEventArgs e)
        {
            GetFirstServer().ExecuteCommand("set %nibl.trustbots false");
        }

        private void retryDLCheckBox_Unchecked(object sender, RoutedEventArgs e)
        {
            GetFirstServer().ExecuteCommand("set %nibl.retryDL false");
        }
    }
}
