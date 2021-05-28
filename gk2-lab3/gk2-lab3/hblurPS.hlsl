sampler blurSampler;
Texture2D halfscreen1;
float blurScale;
float2 viewportDim;

struct VSOutput
{
	float4 pos:SV_POSITION;
	float2 tex : TEXCOORD0;
};

float4 main(VSOutput i) : SV_TARGET
{
	static const float blurWeights[13] = {
		0.002216f,
		0.008764f,
		0.026995f,
		0.064759f,
		0.120985f,
		0.176033f,
		0.199471f,
		0.176033f,
		0.120985f,
		0.064759f,
		0.026995f,
		0.008764f,
		0.002216f
	};

	float4 color = float4(0.0f, 0.0f, 0.0f, 0.0f);
	float2 texelSize = blurScale * 2.0f / viewportDim;
	for (int k = 0; k < 13; ++k)
		color += blurWeights[k] * halfscreen1.Sample(blurSampler, i.tex + float2(((k - 6) * 2 - 0.5f) * texelSize.x,	0.0f));



	return float4(halfscreen1.Sample(blurSampler, i.tex).rgb, 1.0f);
}