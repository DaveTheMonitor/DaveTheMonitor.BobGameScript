using System;
using System.Collections.Generic;
using System.Text;

namespace BobGameBuilder
{
    public sealed class ScriptBuild
    {
        public string Name { get; private set; }
        public string Code { get; private set; }

        public ScriptBuild(string name, string code)
        {
            Name = name;
            Code = code;
        }
    }
}
