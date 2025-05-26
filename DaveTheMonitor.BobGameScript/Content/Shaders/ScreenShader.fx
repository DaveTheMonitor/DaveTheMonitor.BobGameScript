#if OPENGL
    #define SV_POSITION POSITION
    #define VS_SHADERMODEL vs_3_0
    #define PS_SHADERMODEL ps_3_0
#else
    #define VS_SHADERMODEL vs_4_0_level_9_1
    #define PS_SHADERMODEL ps_4_0_level_9_1
#endif

extern const matrix View;
extern const matrix Projection;
extern const matrix World;
extern const texture Tex;

sampler2D TexSampler = sampler_state
{
    Texture = <Tex>;
};

struct VSIn
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
};

struct VSOut
{
    float4 Position : SV_POSITION;
    float2 TexCoord : TEXCOORD0;
};

VSOut MainVS(in VSIn input)
{
    VSOut output;
    float4 worldPos = mul(input.Position, World);

    output.Position = mul(mul(worldPos, View), Projection);
    output.TexCoord = input.TexCoord;

    return output;
}

float4 MainPS(VSOut input) : COLOR
{
    float4 color = tex2D(TexSampler, input.TexCoord);
    
    //clip(color.a - 0.1);
    
    return color;
}

technique BasicColorDrawing
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL MainVS();
        PixelShader = compile PS_SHADERMODEL MainPS();
    }
};