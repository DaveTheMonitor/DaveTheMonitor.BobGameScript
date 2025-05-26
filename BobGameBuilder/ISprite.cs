using System;
using System.Drawing;

namespace BobGameBuilder
{
    public interface ISprite : IDisposable
    {
        static abstract ISprite Create(string path);
        int Width { get; }
        int Height { get; }
        Color GetPixel(int x, int y);
    }
}
