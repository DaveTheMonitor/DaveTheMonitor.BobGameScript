using System;
using System.Collections.Generic;
using System.Text;

namespace BobGameBuilder
{
    internal sealed class FontInfo
    {
        public class Glyph
        {
            public int[] Bounds { get; set; }
            public int BearingY { get; set; }
            public int Advance { get; set; }

            public Glyph()
            {
                Bounds = new int[4];
            }
        }

        public string Sprite { get; set; }
        public string Mask { get; set; }
        public Dictionary<string, Glyph> Glyphs { get; set; }

        public FontInfo(string sprite, string mask)
        {
            Sprite = sprite;
            Mask = mask;
            Glyphs = new Dictionary<string, Glyph>();
        }
    }
}
