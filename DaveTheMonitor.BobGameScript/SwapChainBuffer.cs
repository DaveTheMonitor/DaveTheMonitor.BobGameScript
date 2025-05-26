using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using StudioForge.BlockWorld;
using StudioForge.Engine.Core;
using StudioForge.Engine.GamerServices;
using StudioForge.TotalMiner;
using StudioForge.TotalMiner.API;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Text;
using System.Threading.Tasks;

namespace DaveTheMonitor.BobGameScript
{
    public sealed class SwapChainBuffer : IDisposable
    {
        public Point Size { get; private set; }
        public DynamicVertexBuffer Vertices { get; private set; }
        public bool ChangedSinceSwap { get; private set; }
        private static ITMMeshBuilder _meshBuilder;
        private static Type _meshBuilderType;
        private static MethodInfo _meshBuilderInitialize;
        private static FieldInfo _newFormatVertices;
        private static FieldInfo _customArrayArray;
        private static FieldInfo _customArrayCount;
        private Block[] _buffer;
        private Block[] _prevBuffer;
        private VertexMapBlock[] _vertices;
        private VertexMapBlock[] _changedVertices;
        private int _changedVerticesCount;
        private List<int> _changedPixels;
        private bool _disposedValue;
        private ITMGame _game;

        public SwapChainBuffer(GraphicsDevice device, Point size, ITMGame game)
        {
            Size = size;
            _buffer = new Block[size.X * size.Y];
            _prevBuffer = new Block[size.X * size.Y];
            Vertices = new DynamicVertexBuffer(device, typeof(VertexMapBlock), size.X * size.Y * 6, BufferUsage.WriteOnly);
            _vertices = new VertexMapBlock[size.X * size.Y * 6];
            _changedVertices = new VertexMapBlock[size.X * size.Y * 6];
            _changedPixels = new List<int>();
            _game = game;
            ChangedSinceSwap = false;
        }

        public void CopyTo(SwapChainBuffer other)
        {
            if (!ChangedSinceSwap)
            {
                return;
            }

            _buffer.CopyTo(other._buffer, 0);
        }

        public void OnSwap()
        {
            ChangedSinceSwap = false;
        }

        public void SetBlock(Point p, Block block)
        {
            int i = (p.Y * Size.X) + p.X;
            _buffer[i] = block;
            ChangedSinceSwap = true;
        }

        private void CreateMeshBuilder()
        {
            _meshBuilderType = _game.GetType().Assembly.GetType("StudioForge.TotalMiner.Graphics.VoxelMeshBuilder");
            _newFormatVertices = _meshBuilderType.GetField("newFormatVertices", BindingFlags.NonPublic | BindingFlags.Instance);
            _meshBuilderInitialize = _meshBuilderType.GetMethod("Initialize", BindingFlags.Public | BindingFlags.Instance, [_game.GetType()]);

            _meshBuilder = (ITMMeshBuilder)Activator.CreateInstance(_meshBuilderType);
            _meshBuilderInitialize.Invoke(_meshBuilder, [_game]);
            _meshBuilderType.GetMethod("InitializeForNewMap", BindingFlags.NonPublic | BindingFlags.Instance, [typeof(Map)]).Invoke(_meshBuilder, [_game.World.Map]);

            object customArr = _newFormatVertices.GetValue(_meshBuilder);
            _customArrayCount = customArr.GetType().GetField("Count", BindingFlags.Public | BindingFlags.Instance);
            _customArrayArray = customArr.GetType().GetField("Array", BindingFlags.Public | BindingFlags.Instance);
        }

        public void BuildVertices()
        {
            if (!ChangedSinceSwap)
            {
                return;
            }

            // We use the existing vanilla mesh builder to create our screen mesh
            // This keeps it mostly consistent with the vanilla rendering, just
            // without the screen tearing.
            if (_meshBuilder == null)
            {
                CreateMeshBuilder();
            }
            _meshBuilderInitialize.Invoke(_meshBuilder, [_game]);

            object customArr = _newFormatVertices.GetValue(_meshBuilder);
            _customArrayCount.SetValue(customArr, 0);

            int sx = Size.X;
            _changedVerticesCount = 0;
            _changedPixels.Clear();
            for (int i = 0; i < _buffer.Length; i++)
            {
                Block block = _buffer[i];
                if (_prevBuffer[i] == block)
                {
                    continue;
                }

                _prevBuffer[i] = block;

                int x = i % sx;
                int y = i / sx;

                GlobalPoint3D p = new GlobalPoint3D(x, y, 0);
                Vector4 bl = new Vector4(x, y, 0, (int)BlockFace.Backward);
                Vector4 tl = new Vector4(x, y + 1, 0, (int)BlockFace.Backward);
                Vector4 br = new Vector4(x + 1, y, 0, (int)BlockFace.Backward);
                Vector4 tr = new Vector4(x + 1, y + 1, 0, (int)BlockFace.Backward);

                Vector2 tc1 = _meshBuilder.TexCoords1[(int)block];
                Vector2 tc2 = _meshBuilder.TexCoords2[(int)block];
                Vector2 tc3 = _meshBuilder.TexCoords3[(int)block];
                Vector2 tc4 = _meshBuilder.TexCoords4[(int)block];

                _meshBuilder.AddVertex(bl.X, bl.Y, bl.Z, (int)BlockFace.Backward, new(tc3.X, tc3.Y), (byte)block, 0, ref p);
                _meshBuilder.AddVertex(tl.X, tl.Y, tl.Z, (int)BlockFace.Backward, new(tc1.X, tc1.Y), (byte)block, 0, ref p);
                _meshBuilder.AddVertex(br.X, br.Y, br.Z, (int)BlockFace.Backward, new(tc4.X, tc4.Y), (byte)block, 0, ref p);
                _meshBuilder.AddVertex(br.X, br.Y, br.Z, (int)BlockFace.Backward, new(tc4.X, tc4.Y), (byte)block, 0, ref p);
                _meshBuilder.AddVertex(tl.X, tl.Y, tl.Z, (int)BlockFace.Backward, new(tc1.X, tc1.Y), (byte)block, 0, ref p);
                _meshBuilder.AddVertex(tr.X, tr.Y, tr.Z, (int)BlockFace.Backward, new(tc2.X, tc2.Y), (byte)block, 0, ref p);
                _changedVerticesCount += 6;
                _changedPixels.Add(i);
            }

            if (!_disposedValue)
            {
                Array arr = (Array)_customArrayArray.GetValue(customArr);
                ref byte arrRef = ref MemoryMarshal.GetArrayDataReference(arr);
                ref byte verticesRef = ref MemoryMarshal.GetArrayDataReference((Array)_changedVertices);
                Unsafe.CopyBlock(ref verticesRef, ref arrRef, (uint)(_changedVerticesCount * Unsafe.SizeOf<VertexMapBlock>()));

                // The mesh builder only builds pixels that have changed since the last frame, so
                // we store those in a separate array and copy them to the vertex buffer.
                // This is much faster than building the entire screen every frame.
                for (int i = 0; i < _changedPixels.Count; i++)
                {
                    int ti = _changedPixels[i] * 6;
                    int i6 = i * 6;
                    _vertices[ti] = _changedVertices[i6];
                    _vertices[ti + 1] = _changedVertices[i6 + 1];
                    _vertices[ti + 2] = _changedVertices[i6 + 2];
                    _vertices[ti + 3] = _changedVertices[i6 + 3];
                    _vertices[ti + 4] = _changedVertices[i6 + 4];
                    _vertices[ti + 5] = _changedVertices[i6 + 5];
                }

                if (!Vertices.IsDisposed)
                {
                    Vertices.SetData(_vertices);
                }
            }
        }

        private void Dispose(bool disposing)
        {
            if (!_disposedValue)
            {
                if (disposing)
                {
                    Vertices.Dispose();
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
