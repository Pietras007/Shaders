matrix modelMtx, modelInvTMtx, viewProjMtx;
float time, xmax, vmax, thalf;
float4 camPos;
float h0;
static const int halfTimes = 4;

struct VSInput
{
	float3 pos : POSITION0;
	float3 norm : NORMAL0;
	float2 tex : TEXCOORD0;
};

struct VSOutput
{
	float4 pos : SV_POSITION;
	float3 worldPos : POSITION0;
	float3 norm : NORMAL0;
	float3 view : VIEWVEC0;
	float2 tex : TEXCOORD0;
};

float springHeight(float time);

VSOutput main(VSInput i)
{
	VSOutput o;
	float4 worldPos = mul(modelMtx, float4(i.pos, 1.0f)); 
	int x;
	worldPos.y += h0 + springHeight(modf(time / (halfTimes *thalf), x) * halfTimes * thalf);
	o.tex = i.tex / 4.0f;

	o.view = normalize(camPos.xyz - worldPos.xyz);
	o.norm = normalize(mul(modelInvTMtx, float4(i.norm, 0.0f)).xyz);
	o.worldPos = worldPos.xyz;
	o.pos = mul(viewProjMtx, worldPos);
	return o;
}

float springHeight(float time)
{
	return xmax * exp(-0.693147f * time / thalf) * sin(vmax * time / xmax);
}