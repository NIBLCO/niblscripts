using AdiIRCAPIv2.Interfaces;
using NIBLSearchWPF;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace NiblSearchWPF
{
    public class PackQueueClient
    {
        public List<SimplePack> DownloadQueueList;
        public IPluginHost _host;

        public PackQueueClient(IPluginHost host)
        {
            _host = host;
            DownloadQueueList = new List<SimplePack>();
        }

        public Task AddToQueue(SimplePack pack)
        {
            DownloadQueueList.Add(pack);
            return Task.CompletedTask;
        }

        public Task RemoveFromQueue(string botName, string file)
        {
            DownloadQueueList.RemoveAll(p => p.Name.ToLower() == botName.ToLower() && file.ToLower() == p.File.ToLower());
            return Task.CompletedTask;
        }

        public Task RemoveFromQueueByPack(string botName, string packString)
        {
            if (long.TryParse(packString, out long pack))
            {
                DownloadQueueList.RemoveAll(p => p.Name.ToLower() == botName.ToLower() && p.PackNumber == pack);
            }
            return Task.CompletedTask;
        }

        public Task<bool> IsInQueue(string botName, string file)
        {
            bool match = DownloadQueueList.Any(p => p.Name.ToLower() == botName.ToLower() && p.File.ToLower() == file.ToLower());
            return Task.FromResult(match);
        }

        public Task RetryDownload(string botName, string file)
        {
            var match = DownloadQueueList.FirstOrDefault(p => p.Name.ToLower() == botName.ToLower() && p.File.ToLower() == file.ToLower());
            if (match == null)
            {
                ExecuteCommandOnNiblChannel("echo -s  52[NIBL DLQ]: That bot/file is no longer in the download queue list.");
                return Task.CompletedTask;
            }
            
            ExecuteCommandOnNiblChannel($"echo -st  52[NIBL DLQ]: Failed to get file from {match.Name}, and requesting the file(pack {match.PackNumber}) again in 15 seconds.");
            ExecuteCommandOnNiblChannel($"echo -st  52[NIBL DLQ]: To cancel this, Type: /cancelget {match.Name} {match.PackNumber}");

            ExecuteCommandOnNiblChannel($".timer.{match.Name}.{match.PackNumber} 1 15 /msg {match.Name} xdcc send {match.PackNumber}");
            return Task.CompletedTask;
        }

        private Task ExecuteCommand(string command)
        {
            // Try to find the server where NIBL is connected.
            var servers = _host.GetServers.Cast<IServer>();
            var channel = servers.FirstOrDefault(server => server.IsConnected && server.Network.ToLower() == "rizon" && server.GetChannels.Cast<IChannel>().Any(chan => chan.Name.ToLower() == "#nibl"));
            if (channel != null)
            {
                channel.ExecuteCommand(command);
            }
            else
            {
                servers.First().ExecuteCommand(command);
            }
            return Task.CompletedTask;
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

        public Task AddTrust(string botName)
        {
            var servers = _host.GetServers.Cast<IServer>();
            var channel = servers.FirstOrDefault(server => server.IsConnected && server.Network.ToLower() == "rizon" && server.GetChannels.Cast<IChannel>().Any(chan => chan.Name.ToLower() == "#nibl"));
            if (channel == null)
                return Task.CompletedTask;
            var trustEnabled = channel.Evaluate("%nibl.trustbots", "");
            if (trustEnabled == "true")
            {
                var botAddress = channel.Evaluate($"$address({botName},8)", "");
                channel.ExecuteCommand($"dcctrust {botAddress}");
            }
            return Task.CompletedTask;
        }

    }
}
