using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace NIBLSearchWPF
{
    public class SimplePack
    {
        public SimplePack(long id, string name, string file, string size, long pack)
        {
            Id = id;
            Name = name;
            File = file;
            PackNumber = pack;
            Size = size;

        }
        [Browsable(false)]
        public long Id { get; set; }
        [DisplayName("Bot Name")]
        public string Name { get; set; }
        [DisplayName("File Name")]
        public string File { get; set; }
        [DisplayName("Pack Number")]
        public long PackNumber { get; set; }
        [DisplayName("File Size")]
        public string Size { get; set; }
    }
}
