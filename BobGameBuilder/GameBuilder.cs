using System;
using System.IO;
using System.Drawing;
using System.Text;
using System.Text.Json;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http.Headers;
using System.Diagnostics;

namespace BobGameBuilder
{
    public sealed class GameBuilder<TSprite> where TSprite : ISprite
    {
        [DebuggerDisplay("{ScriptName}")]
        private struct FileToBuild
        {
            public string ScriptName;
            public string Code;
            public int Priority;
        }

        [DebuggerDisplay("{Block} : {Count}")]
        private struct RLERun
        {
            public string Block;
            public int Count;

            public RLERun(string block, int count)
            {
                Block = block;
                Count = count;
            }
        }

        public ScriptBuild[] Build(string path)
        {
            string[] files = Directory.GetFiles(path, "*.lua", SearchOption.AllDirectories);

            List<ScriptBuild> scripts = new List<ScriptBuild>();
            List<FileToBuild> filesToBuild = new List<FileToBuild>();
            foreach (string file in files)
            {
                string code = File.ReadAllText(file);
                int i = 0;
                bool build = false;
                int priority = 100;
                string? externalCode = null;
                string? scriptName = "game";
                while (i != -1)
                {
                    int index = code.IndexOf('\n', i);

                    ReadOnlySpan<char> span = code.AsSpan(i, (index == -1 ? code.Length : index) - i);
                    if (span.StartsWith("--#"))
                    {
                        span = span.Slice(3);
                        string[] preprocessor = span.ToString().Split(' ', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries);
                        string type = preprocessor[0];
                        switch (type)
                        {
                            case "build":
                            {
                                build = true;
                                break;
                            }
                            case "priority":
                            {
                                priority = int.Parse(preprocessor[1]);
                                break;
                            }
                            case "external":
                            {
                                build = true;
                                externalCode = GetExternalCode(path, preprocessor);
                                break;
                            }
                            case "script":
                            {
                                build = true;
                                scriptName = preprocessor[1];
                                break;
                            }
                        }
                    }

                    i = index == -1 ? -1 : index + 1;
                }

                if (build)
                {
                    filesToBuild.Add(new FileToBuild()
                    {
                        Code = externalCode ?? code,
                        Priority = priority,
                        ScriptName = scriptName
                    });
                }
            }

            filesToBuild.Sort((l, r) => l.Priority.CompareTo(r.Priority));
            Dictionary<string, StringBuilder> builders = new Dictionary<string, StringBuilder>();

            foreach (FileToBuild f in filesToBuild)
            {
                List<string> lines = new List<string>(f.Code.Split('\n').Select(line => line.Trim()).Where(line => !string.IsNullOrWhiteSpace(line) && !line.StartsWith("--")));
                if (!builders.TryGetValue(f.ScriptName, out StringBuilder? builder))
                {
                    builder = new StringBuilder();
                    builders.Add(f.ScriptName, builder);
                }

                foreach (string line in lines)
                {
                    builder.AppendLine(line);
                }
            }

            List<ScriptBuild> builds = new List<ScriptBuild>();
            foreach (KeyValuePair<string, StringBuilder> pair in builders)
            {
                builds.Add(new ScriptBuild(pair.Key, pair.Value.ToString()));
            }
            return builds.ToArray();
        }

        private static string GetExternalCode(string path, string[] preprocessors)
        {
            return preprocessors[1] switch
            {
                "sprites" => GetSprites(path, preprocessors),
                "fonts" => GetFonts(path, preprocessors),
                _ => throw new InvalidOperationException($"Invalid external type {preprocessors[1]}")
            };
        }

        private static string GetSprites(string path, string[] preprocessors)
        {
            string spritesPath = Path.Combine(path, "sprites");
            string[] files = Directory.GetFiles(spritesPath, "*.png", SearchOption.AllDirectories);
            JsonSerializerOptions jsonOptions = new JsonSerializerOptions()
            {
                AllowTrailingCommas = true,
                ReadCommentHandling = JsonCommentHandling.Skip
            };

            StringBuilder builder = new StringBuilder();

            foreach (string file in files)
            {
                using ISprite sprite = TSprite.Create(file);
                string jsonPath = Path.ChangeExtension(file, ".json");
                if (!File.Exists(jsonPath))
                {
                    continue;
                }

                SpriteInfo info = (SpriteInfo)(JsonSerializer.Deserialize(File.ReadAllText(jsonPath), typeof(SpriteInfo), jsonOptions) ?? throw new Exception("invalid json"));

                HashSet<string> uniqueBlocks = new HashSet<string>();
                List<RLERun> rle = new List<RLERun>();
                int count = 1;
                string? prevBlock = null;
                for (int i = 0; i < sprite.Width * sprite.Height; i++)
                {
                    int x = i % sprite.Width;
                    int y = i / sprite.Width;
                    Color color = sprite.GetPixel(x, y);
                    string block;
                    if (color.A == 0)
                    {
                        block = "none";
                    }
                    else
                    {
                        string colorString = $"{color.R},{color.G},{color.B}";
                        if (!info.Palette.TryGetValue(colorString, out string? value))
                        {
                            if ((x % 8 < 4 && y % 8 < 4) || (x % 8 >= 4 && y % 8 >= 4))
                            {
                                value = "colorpurple";
                            }
                            else
                            {
                                value = "colorblack";
                            }
                        }
                        block = value.ToLowerInvariant();
                    }

                    if (prevBlock == null)
                    {
                        prevBlock = block!;
                        continue;
                    }

                    if (prevBlock != block)
                    {
                        rle.Add(new RLERun(prevBlock, count));
                        uniqueBlocks.Add(prevBlock);
                        count = 0;
                    }
                    count++;

                    prevBlock = block!;
                }

                rle.Add(new RLERun(prevBlock!, count));
                uniqueBlocks.Add(prevBlock!);

                string name = Path.ChangeExtension(Path.GetRelativePath(spritesPath, file), null);
                builder.AppendLine("do");
                Dictionary<string, string> lookup = new Dictionary<string, string>();
                int next = 1;
                foreach (string block in uniqueBlocks)
                {
                    string v = "b" + Convert.ToString(next, 16);
                    lookup.Add(block, v);
                    next++;
                    builder.Append($"local ");
                    builder.Append(v);
                    builder.Append(" = block.");
                    builder.Append(block);
                    builder.AppendLine();
                }
                builder.Append(preprocessors[2]);
                builder.Append(":add_data(\"");
                builder.Append(name);
                builder.Append('"');
                builder.Append(",SpriteData.new(");
                builder.Append(sprite.Width);
                builder.Append(',');
                builder.Append(sprite.Height);
                builder.Append(",{");
                for (int i = 0; i < rle.Count; i++)
                {
                    builder.Append(rle[i].Count);
                    builder.Append(',');
                    builder.Append(lookup[rle[i].Block]);
                    if (i < rle.Count - 1)
                    {
                        builder.Append(',');
                    }
                }
                builder.Append("}))");
                builder.AppendLine();
                builder.AppendLine("end");
            }

            return builder.ToString();
        }

        private static string GetFonts(string path, string[] preprocessors)
        {
            string fontsPath = Path.Combine(path, "fonts");
            string[] files = Directory.GetFiles(fontsPath, "*.json", SearchOption.AllDirectories);
            JsonSerializerOptions jsonOptions = new JsonSerializerOptions()
            {
                AllowTrailingCommas = true,
                ReadCommentHandling = JsonCommentHandling.Skip
            };

            StringBuilder builder = new StringBuilder();

            foreach (string file in files)
            {
                FontInfo info = (FontInfo)(JsonSerializer.Deserialize(File.ReadAllText(file), typeof(FontInfo), jsonOptions) ?? throw new Exception("invalid json"));

                string name = Path.ChangeExtension(Path.GetRelativePath(fontsPath, file), null);
                builder.AppendLine("do");
                builder.Append("local t = {};");
                foreach (KeyValuePair<string, FontInfo.Glyph> pair in info.Glyphs)
                {
                    int i;
                    FontInfo.Glyph glyph = pair.Value;
                    if (pair.Key == "unknown" && pair.Key.Length > 1)
                    {
                        i = 0;
                    }
                    else if (pair.Key.Length == 1)
                    {
                        i = Encoding.ASCII.GetBytes(pair.Key)[0];
                    }
                    else
                    {
                        throw new Exception($"invalid glyph {pair.Key}");
                    }
                    builder.Append("t[");
                    builder.Append(i);
                    builder.Append("]=Glyph.new(");
                    builder.Append(glyph.Bounds[0]);
                    builder.Append(',');
                    builder.Append(glyph.Bounds[1]);
                    builder.Append(',');
                    builder.Append(glyph.Bounds[2]);
                    builder.Append(',');
                    builder.Append(glyph.Bounds[3]);
                    builder.Append(',');
                    builder.Append(glyph.BearingY);
                    builder.Append(',');
                    builder.Append(glyph.Advance);
                    builder.Append(");");
                }
                builder.AppendLine();
                builder.Append(preprocessors[2]);
                builder.Append(":add_data(\"");
                builder.Append(name);
                builder.Append('"');
                builder.Append(",FontData.new(\"");
                builder.Append(info.Sprite);
                builder.Append("\",block.");
                builder.Append(info.Mask.ToLower());
                builder.Append(',');
                builder.Append(0);
                builder.Append(",t))");
                builder.AppendLine();
                builder.AppendLine("end");
            }

            return builder.ToString();
        }
    }
}
