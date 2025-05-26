using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using StudioForge.BlockWorld;
using StudioForge.Engine.Core;
using StudioForge.TotalMiner.API;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace DaveTheMonitor.BobGameScript
{
    public sealed class SwapChain : IDisposable
    {
        public SwapChainBuffer FrontBuffer { get; private set; }
        public SwapChainBuffer BackBuffer { get; private set; }
        private IndexBuffer _indexBuffer;
        private GlobalPoint3D _pos;
        private Point _size;
        private GraphicsDevice _device;
        private ITMGame _game;
        private bool _disposedValue;

        public SwapChain(GraphicsDevice device, GlobalPoint3D pos, Point size, ITMGame game)
        {
            FrontBuffer = new SwapChainBuffer(device, size, game);
            BackBuffer = new SwapChainBuffer(device, size, game);
            _indexBuffer = new IndexBuffer(device, IndexElementSize.ThirtyTwoBits, size.X * size.Y * 6, BufferUsage.WriteOnly);
            int[] indices = new int[size.X * size.Y * 6];
            for (int i = 0; i < indices.Length; i++)
            {
                indices[i] = i;
            }
            _indexBuffer.SetData(indices);

            _pos = pos;
            _size = size;
            _device = device;

            _game = game;
        }

        public void Draw(ITMPlayer player, ITMPlayer virtualPlayer)
        {
            _device.BlendState = BlendState.Opaque;
            _device.DepthStencilState = DepthStencilState.Default;
            _device.RasterizerState = RasterizerState.CullCounterClockwise;
            _device.SamplerStates[0] = SamplerState.PointClamp;
            Type mapShaderType = player.GetType().Assembly.GetType("StudioForge.TotalMiner.Graphics.GraphicStatics").GetNestedType("MapShader", BindingFlags.Public);
            Effect mapShader = (Effect)mapShaderType.GetField("Effect", BindingFlags.Public | BindingFlags.Static).GetValue(null);
            mapShader.Parameters["World"].SetValue(Matrix.CreateTranslation(-virtualPlayer.Position + _pos.ToVector3()));

            lock (FrontBuffer)
            {
                foreach (EffectPass pass in mapShader.CurrentTechnique.Passes)
                {
                    _device.SetVertexBuffer(FrontBuffer.Vertices);
                    _device.Indices = _indexBuffer;
                    pass.Apply();
                    _device.DrawIndexedPrimitives(PrimitiveType.TriangleList, 0, 0, _size.X * _size.Y * 6);
                }
            }

            //_view.SetValue(virtualPlayer.ViewMatrix);
            //_projection.SetValue(player.ProjectionMatrix);
            //_world.SetValue(Matrix.CreateTranslation(-virtualPlayer.Position + _pos.ToVector3()));
            //_world.SetValue(Matrix.Identity);
            // We use the LOD texture as the screen is far away enough to cause a
            // noticeable moire effect without it
            //_tex.SetValue(_game.TexturePack.BlockTextureLOD);
            //lock (FrontBuffer)
            //{
            //    foreach (EffectPass pass in _shader.CurrentTechnique.Passes)
            //    {
            //        _device.SetVertexBuffer(FrontBuffer.Vertices);
            //        _device.Indices = _indexBuffer;
            //        pass.Apply();
            //        _device.DrawIndexedPrimitives(PrimitiveType.TriangleList, 0, 0, _size.X * _size.Y * 6);
            //    }
            //}
        }

        public void Swap()
        {
            lock (FrontBuffer)
            {
                SwapChainBuffer front = FrontBuffer;
                SwapChainBuffer back = BackBuffer;
                if (!back.ChangedSinceSwap)
                {
                    return;
                }

                FrontBuffer = back;
                BackBuffer = front;

                // We copy the front buffer to the back buffer because
                // BobGame only sets pixels that have changed, so not
                // copying will cause some graphical bugs
                FrontBuffer.CopyTo(BackBuffer);
                FrontBuffer.OnSwap();
                BackBuffer.OnSwap();
            }
        }

        private void Dispose(bool disposing)
        {
            if (!_disposedValue)
            {
                if (disposing)
                {
                    FrontBuffer.Dispose();
                    BackBuffer.Dispose();
                    _indexBuffer.Dispose();
                }

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
