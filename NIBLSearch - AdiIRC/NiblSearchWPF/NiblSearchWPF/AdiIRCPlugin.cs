namespace NiblSearchWPF
{
    using AdiIRCAPIv2.Interfaces;
    using AdiIRCAPIv2;
    using AdiIRCAPIv2.Delegates;
    using AdiIRCAPIv2.Enumerators;
    using AdiIRCAPIv2.Arguments.WindowInteraction;
    using AdiIRCAPIv2.Arguments.Aliasing;
    using System;
    using System.Threading.Tasks;
    using System.Linq;
    using System.Collections.Generic;
    using System.Windows;
    using NIBLSearchWPF;

    public class NIBLSearch : IPlugin
    {
        public string Description { get { return "Search GUI for the NIBL Community."; } }

        public string Author { get { return "Rand"; } }

        public string Name { get { return "NIBL Search"; } }

        public string Version { get { return "0.9"; } }

        public string Email { get { return ""; } }

        public string PluginName => Name;

        public string PluginDescription => Description;

        public string PluginAuthor => Author;

        public string PluginVersion => Version;

        public string PluginEmail => Email;

        public IPluginHost _host;

        public Window _testWindow;
        public bool IsNIBLWindowOpen = false;
        public PackQueueClient _packQueueClient;
        public NiblSearchService _searchService;
        public NiblPackListModel Model;

        public void Initialize(IPluginHost host)
        {
            _host = host;
            Model = new NiblPackListModel();
            _searchService = new NiblSearchService(Model);
            _packQueueClient = new PackQueueClient(host);
            host.HookCommand("nibl", NIBLOpenSearch);
            host.HookCommand("niblhelp", NIBLHelpCommand);
            host.HookIdentifier("niblretrydownload", NIBLRetryDownload);
            host.HookIdentifier("niblisqueued", NIBLIsQueued);
            host.HookIdentifier("niblgetsuccess", NIBLGetSuccess);
            host.HookCommand("cancelget", NIBLCancelGet);
        }

        private void NIBLHelpCommand(RegisteredCommandArgs argument)
        {
            _host.ActiveIWindow.ExecuteCommand($"echo -st  52[NIBL Search]:  Version: {Version}");
            _host.ActiveIWindow.ExecuteCommand($"echo -st  52[NIBL Search]:  Commands:");
            _host.ActiveIWindow.ExecuteCommand($"echo -st  52[NIBL Search]:  /nibl [search terms]      - Opens the NIBL Search window.");
            _host.ActiveIWindow.ExecuteCommand($"echo -st  52[NIBL Search]:  /cancelget <botname> <pack>       - Will remove the file from the auto-retry list.");
        }

        private async void NIBLCancelGet(RegisteredCommandArgs argument)
        {
            var arguments = argument.Command.Split(new string[] { " " }, StringSplitOptions.RemoveEmptyEntries);
            await _packQueueClient.RemoveFromQueueByPack(arguments[1], arguments[2]);
            await _packQueueClient.ExecuteCommandOnNiblChannel($"/timer.{arguments[1]}.{arguments[2]} off");
            await _packQueueClient.ExecuteCommandOnNiblChannel($"echo -st  52[NIBL DLQ]: Cancelled pack {arguments[2]} from bot {arguments[1]}");
        }

        private async void NIBLGetSuccess(RegisteredIdentifierArgs argument)
        {
            string name = argument.InputParameters[0];
            string file = argument.InputParameters[1];
            await _packQueueClient.RemoveFromQueue(name, file);
            await _packQueueClient.ExecuteCommandOnNiblChannel($"echo -st  52[NIBL DLQ]: Successfully downloaded \"{file}\" from {name}. Removing from internal queue.");
            argument.ReturnString = "Removed";
        }

        private async void NIBLIsQueued(RegisteredIdentifierArgs argument)
        {
            bool _ = await _packQueueClient.IsInQueue(argument.InputParameters[0], argument.InputParameters[1]);
            argument.ReturnString = (_) ? "1" : "0";
        }

        private async void NIBLRetryDownload(RegisteredIdentifierArgs argument)
        {
            // "%nibl.retryDL"
            var retryvalue = GetFirstServer().Evaluate("%nibl.retryDL", "");
            if (retryvalue == "true")
            {
                string name = argument.InputParameters[0];
                string file = argument.InputParameters[1];
                await _packQueueClient.RetryDownload(name, file);
            }
        }

        private void NIBLOpenSearch(RegisteredCommandArgs argument)
        {
            string comm = "";
            if (argument.Command.Length > 6)
            {
                comm = argument.Command.Remove(0, 6);
            }
            bool trustbots = false;
            bool retryDL = false;
            try
            {
                var keys = _host.GetVariables.Keys.Cast<string>();
                if (keys.Contains("%nibl.trustbots"))
                {
                    string value = _host.GetVariables["%nibl.trustbots"].ToString();
                    if (value == "true")
                    {
                        trustbots = true;
                    }
                }
                if (keys.Contains("%nibl.retryDL"))
                {
                    string value = _host.GetVariables["%nibl.retryDL"].ToString();
                    if (value == "true")
                    {
                        retryDL = true;
                    }
                }
            }
            catch (Exception ex)
            {
                GetFirstServer().ExecuteCommand($"echo -at Error: {ex.Message}");
            }
            if (IsNIBLWindowOpen)
            {
                _testWindow.Activate();
            }
            else
            {
                Model.SimpleCollection = null;
                _testWindow = new NiblSearchWindow(_host, _searchService, Model, _packQueueClient, trustbots, retryDL, comm);
                System.Windows.Forms.Integration.ElementHost.EnableModelessKeyboardInterop(_testWindow);
                _testWindow.Closed += _testWindow_Closed;
                IsNIBLWindowOpen = true;
                _testWindow.Show();
            }
        }

        private void _testWindow_Closed(object sender, EventArgs e)
        {
            IsNIBLWindowOpen = false;
        }

        public void Dispose()
        {
            //_searchForm.Dispose();
            // Called when the plugin is unloaded/closed, do clean up here
        }

        private List<IServer> GetServersList()
        {
            var servers = _host.GetServers.Cast<IServer>().ToList();
            return servers;
        }

        public Task<bool> ExecuteCommandOnNiblChannel(string command)
        {
            // Try to find the server where NIBL is connected.
            var servers = _host.GetServers.Cast<IServer>();
            var channel = servers.FirstOrDefault(server => server.IsConnected && server.Network.ToLower() == "rizon" && server.GetChannels.Cast<IChannel>().Any(chan => chan.Name.ToLower() == "#nibl"));
            if (channel != null)
            {
                channel.ExecuteCommand(command);
                return Task.FromResult(true);
            }
            return Task.FromResult(false);
        }

        public Task<string> EvaluateOnNiblServer(string command)
        {
            var servers = _host.GetServers.Cast<IServer>();
            var server = servers.FirstOrDefault(serv => serv.IsConnected && serv.Network.ToLower() == "rizon" && serv.GetChannels.Cast<IChannel>().Any(chan => chan.Name.ToLower() == "#nibl"));
            if (server == null)
            {
                return Task.FromResult("");
            }
            var result = server.Evaluate(command, "");
            return Task.FromResult(result);
        }

        private IServer GetFirstServer()
        {
            return GetServersList().First();
        }
    }
}
