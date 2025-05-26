using BobGameBuilder;
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BuildBobGame
{
    public sealed class Sprite : ISprite
    {
        public int Width => _image.Width;
        public int Height => _image.Height;
        private Image _image;
        private Bitmap _bitmap;
        private bool _disposedValue;

        public Sprite(Image image, Bitmap bitmap)
        {
            _image = image;
            _bitmap = bitmap;
        }

        public static ISprite Create(string path)
        {
            Image image = Image.FromFile(path);
            Bitmap bitmap = new Bitmap(image);

            return new Sprite(image, bitmap);
        }

        public Color GetPixel(int x, int y)
        {
            return _bitmap.GetPixel(x, y);
        }

        private void Dispose(bool disposing)
        {
            if (!_disposedValue)
            {
                if (disposing)
                {
                    _image.Dispose();
                    _bitmap.Dispose();
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
