sampler blurSampler;
Texture2D screen;

struct VSOutput
{
	float4 pos:SV_POSITION;
	float2 tex : TEXCOORD0;
};

float4 main(VSOutput i) : SV_TARGET
{
	return float4(screen.Sample(blurSampler, i.tex).rgb, 1.0f);
}