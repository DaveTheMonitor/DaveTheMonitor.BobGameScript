using System.Runtime.InteropServices;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace DaveTheMonitor.BobGameScript
{
    [StructLayout(LayoutKind.Sequential)]
    public struct ScreenVertex : IVertexType
    {
        public static readonly VertexDeclaration VertexDeclaration;
        VertexDeclaration IVertexType.VertexDeclaration => VertexDeclaration;
        public Vector3 Position;
        public Vector2 TexCoord;

        static ScreenVertex()
        {
            VertexDeclaration = new VertexDeclaration(new VertexElement[]
            {
                new VertexElement(0, VertexElementFormat.Vector3, VertexElementUsage.Position, 0),
                new VertexElement(12, VertexElementFormat.Vector2, VertexElementUsage.TextureCoordinate, 0)
            });
        }

        public ScreenVertex(Vector3 p, Vector2 tc)
        {
            Position = p;
            TexCoord = tc;
        }

        public override int GetHashCode()
        {
            return 0;
        }

        public override string ToString()
        {
            return $"{{Position: {Position} TexCoord: {TexCoord}}}";
        }

        public static bool operator ==(ScreenVertex left, ScreenVertex right)
        {
            return left.Position == right.Position &&
                left.TexCoord == right.TexCoord;
        }

        public static bool operator !=(ScreenVertex left, ScreenVertex right)
        {
            return left.Position != right.Position ||
                left.TexCoord != right.TexCoord;
        }

        public override bool Equals(object obj)
        {
            return obj is ScreenVertex v && this == v;
        }
    }
}