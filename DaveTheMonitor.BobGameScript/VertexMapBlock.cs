using System.Runtime.InteropServices;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Graphics.PackedVector;

namespace DaveTheMonitor.BobGameScript
{
    // Layout should exactly match StudioForge.TotalMiner.Graphics.VertexMapBlock,
    // this is used for vertices for the map shader.
    [StructLayout(LayoutKind.Sequential)]
    public struct VertexMapBlock : IVertexType
    {
        public static readonly VertexDeclaration VertexDeclaration;
        VertexDeclaration IVertexType.VertexDeclaration => VertexDeclaration;
        public HalfVector4 Position;
        public NormalizedShort2 TexCoord;
        public NormalizedShort2 Light;

        static VertexMapBlock()
        {
            VertexDeclaration = new VertexDeclaration(new VertexElement[]
            {
                new VertexElement(0, VertexElementFormat.HalfVector4, VertexElementUsage.Position, 0),
                new VertexElement(8, VertexElementFormat.NormalizedShort2, VertexElementUsage.TextureCoordinate, 0),
                new VertexElement(12, VertexElementFormat.NormalizedShort2, VertexElementUsage.Color, 0)
            });
        }

        public VertexMapBlock(Vector4 p, Vector2 light, Vector2 tc)
        {
            Position = new HalfVector4(p);
            TexCoord = new NormalizedShort2(tc);
            Light = new NormalizedShort2(light);
        }

        public override int GetHashCode()
        {
            return 0;
        }

        public override string ToString()
        {
            return $"{{Position: {Position} TexCoord: {TexCoord} Light: {Light}}}";
        }

        public static bool operator ==(VertexMapBlock left, VertexMapBlock right)
        {
            return left.Position == right.Position &&
                left.TexCoord == right.TexCoord &&
                left.Light == right.Light;
        }

        public static bool operator !=(VertexMapBlock left, VertexMapBlock right)
        {
            return left.Position != right.Position ||
                left.TexCoord != right.TexCoord ||
                left.Light != right.Light;
        }

        public override bool Equals(object obj)
        {
            return obj is VertexMapBlock v && this == v;
        }
    }
}