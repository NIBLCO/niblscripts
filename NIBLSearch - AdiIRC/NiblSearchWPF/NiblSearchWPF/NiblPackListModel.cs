using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Collections.ObjectModel;
using System.ComponentModel;
using NIBLSearchWPF;

namespace NiblSearchWPF
{
    public class NiblPackListModel : INotifyPropertyChanged
    {
        private ObservableCollection<SimplePack> SimplePackCollection;
        private ObservableCollection<string> BotNameCollection;

        public ObservableCollection<SimplePack> SimpleCollection
        {
            get { return SimplePackCollection; }
            set
            {
                SimplePackCollection = value;
                OnPropertyChanged("SimpleCollection");
            }
        }

        public ObservableCollection<string> BotCollection
        {
            get { return BotNameCollection; }
            set
            {
                BotNameCollection = value;
                OnPropertyChanged("BotCollection");
            }
        }

        public event PropertyChangedEventHandler PropertyChanged;

        public void OnPropertyChanged(string name)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
        }
    }
}
