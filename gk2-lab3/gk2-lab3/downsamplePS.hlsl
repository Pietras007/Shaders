sampler blurSampler;
Texture2D screen;
float cutoff;

struct VSOutput
{
	float4 pos:SV_POSITION;
	float2 tex : TEXCOORD0;
};

float4 main(VSOutput i) : SV_TARGET
{
	float4 color = float4(screen.Sample(blurSampler, i.tex).rgb, 1.0f);
	float luminance = dot(color.rgb, float3(0.3f, 0.58f, 0.12f));
	return luminance < cutoff ? float4(0.0f, 0.0f, 0.0f, 0.0f) : color;
}