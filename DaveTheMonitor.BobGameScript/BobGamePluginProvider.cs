using StudioForge.TotalMiner.API;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DaveTheMonitor.BobGameScript
{
    internal sealed class BobGamePluginProvider : ITMPluginProvider
    {
        public ITMPlugin GetPlugin() => new BobGamePlugin();
        public ITMPluginArcade GetPluginArcade() => null;
        public ITMPluginBiome GetPluginBiome() => null;
        public ITMPluginBlocks GetPluginBlocks() => null;
        public ITMPluginConfig GetPluginConfig() => null;
        public ITMPluginGUI GetPluginGUI() => null;
        public ITMPluginNet GetPluginNet() => null;
    }
}
