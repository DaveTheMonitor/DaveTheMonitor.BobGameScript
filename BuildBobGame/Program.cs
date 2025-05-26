using BobGameBuilder;
using System.Drawing;
using System.Text;
using System.Text.Json;

namespace BuildBobGame
{
    internal class Program
    {
        private const string _path = @"Game";

        static void Main(string[] args)
        {
            GameBuilder<Sprite> builder = new GameBuilder<Sprite>();
            ScriptBuild[] builds = builder.Build(_path);

            foreach (ScriptBuild build in builds)
            {
                File.WriteAllText($"{build.Name}.lua", build.Code);
                File.Copy($"{build.Name}.lua", Path.Combine(_path, $"{build.Name}.txt"), true);
            }
        }
    }
}
