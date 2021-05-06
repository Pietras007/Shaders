#define NLIGHTS 2
SamplerState samp : register(s0);
Texture2D normTex : register(t0);

float4 lightPos[NLIGHTS];
float3 lightColor[NLIGHTS];
float3 surfaceColor;
float ks, kd, ka, m;

float3 normalMapping(float3 N, float3 T, float3 tn);
float4 phong(float3 worldPos, float3 norm, float3 view);

struct PSInput
{
	float4 pos : SV_POSITION;
	float3 worldPos : POSITION0;
	float3 norm : NORMAL0;
	float3 view : VIEWVEC0;
	float2 tex : TEXCOORD0;
};

float4 main(PSInput i) : SV_TARGET
{
	float3 tn = normTex.Sample(samp, i.tex);
	tn = (tn + 1.0f) / 2.0f;

	float3 N = normalize(i.norm);
	float3 dPdx = ddx(i.worldPos);
	float3 dPdy = ddy(i.worldPos);
	float2 dtdx = ddx(i.tex);
	float2 dtdy = ddy(i.tex);
	float3 T = normalize(-dPdx * dtdy.y + dPdy * dtdx.y);

	float3 norm = normalMapping(N, T, tn);

	return phong(i.worldPos, norm, i.view);
}

float3 normalMapping(float3 N, float3 T, float3 tn)
{
	float3 B = normalize(cross(N, T));
	T = cross(B, N);
	float3x3 mtx = { T,B,N };
	mtx = transpose(mtx);
	float3 result = mul(mtx, tn);
	return result;
}

float4 phong(float3 worldPos, float3 norm, float3 view)
{
	view = normalize(view);
	norm = normalize(norm);
	float3 color = surfaceColor * ka; //ambient
	for (int k = 0; k < NLIGHTS; ++k)
	{
		float3 lightVec = normalize(lightPos[k].xyz - worldPos);
		float3 halfVec = normalize(view + lightVec);
		color += lightColor[k] * kd * surfaceColor * saturate(dot(norm, lightVec));//diffuse
		color += lightColor[k] * ks * pow(saturate(dot(norm, halfVec)), m);//specular
	}

	return saturate(float4(color, 1.0f));
}