using Accessibility;
using BobGameBuilder;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using StudioForge.Engine;
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DaveTheMonitor.BobGameScript
{
    public sealed class Sprite : ISprite
    {
        public int Width => _texture.Width;
        public int Height => _texture.Height;
        private Texture2D _texture;
        private Microsoft.Xna.Framework.Color[] _data;
        private bool _disposedValue;

        public Sprite(Texture2D texture)
        {
            _texture = texture;
            _data = new Microsoft.Xna.Framework.Color[texture.Width * texture.Height];
            texture.GetData(_data);
        }

        public static ISprite Create(string path)
        {
            Texture2D texture = Texture2D.FromFile(CoreGlobals.GraphicsDevice, path);
            return new Sprite(texture);
        }

        public System.Drawing.Color GetPixel(int x, int y)
        {
            int i = (y * _texture.Width) + x;
            Microsoft.Xna.Framework.Color c = _data[i];
            return System.Drawing.Color.FromArgb(c.A, c.R, c.G, c.B);
        }

        private void Dispose(bool disposing)
        {
            if (!_disposedValue)
            {
                if (disposing)
                {
                    _texture.Dispose();
                }

                // TODO: free unmanaged resources (unmanaged objects) and override finalizer
                // TODO: set large fields to null
                _disposedValue = true;
            }
        }

        public void Dispose()
        {
            // Do not change this code. Put cleanup code in 'Dispose(bool disposing)' method
            Dispose(disposing: true);
            GC.SuppressFinalize(this);
        }
    }
}
