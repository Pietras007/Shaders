#define NLIGHTS 2
SamplerState samp : register(s0);
Texture2D normTex : register(t0);
Texture2D albedoTex : register(t1);
Texture2D roughnessTex : register(t2);
Texture2D metallicTex : register(t3);

TextureCube irMap;
TextureCube pfEnvMap;
Texture2D brdfTex;

float4 lightPos[NLIGHTS];
float3 lightColor[NLIGHTS];
float3 surfaceColor;
//float3 albedo;
//float metallness;
//float roughness;

float3 normalMapping(float3 N, float3 T, float3 tn);
float normalDistributionGGX(float3 N, float3 H, float r);
float geometrySchlickGGX(float3 N, float3 W, float r);
float geometrySmith(float3 N, float3 V, float3 L, float r);
float3 fresnel(float3 f0, float3 N, float3 L);
float FCT(float3 f0, float3 norm, float3 view, float3 li, float3 h, float roughness);

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
	float3 albedo = albedoTex.Sample(samp, i.tex);
	float metallness = metallicTex.Sample(samp, i.tex);
	float roughness = roughnessTex.Sample(samp, i.tex);

	float3 color = float3(0,0,0);
	float3 abd = pow(albedo, 2.2f);
	float3 f0 = float3(0.04f, 0.04f, 0.04f) * (1.0f - metallness) + abd * metallness;
	float3 view = normalize(i.view);
	float3 N = normalize(i.norm);

	float3 Iir = irMap.Sample(samp, N).rgb;
	float3 kdv = (float3(1.0f, 1.0f, 1.0f) - fresnel(f0, N, view)) * (1.0f - metallness);
	float3 R = reflect(-view, N);
	float3 Ii = pfEnvMap.SampleLevel(samp, R, roughness * 6.0f).rgb;

	float2 brdf = brdfTex.Sample(samp, float2(max(dot(N, view), 0.0f), roughness)).rg;
	float3 Is = Ii * (f0 * brdf.x + brdf.y);
	float3 Id = kdv * abd * Iir + Is;


	for (int lightno = 0; lightno < NLIGHTS; lightno++)
	{
		float3 li = (lightPos[lightno].rgb - i.worldPos) / length(lightPos[lightno].rgb - i.worldPos);
		float3 Li = lightColor[lightno] * (max(dot(i.norm, li), 0)) / pow(length(lightPos[lightno].rgb - i.worldPos), 2);
		float3 h = (view + li) / length(view + li);

		float3 kd = (float3(1,1,1) - fresnel(f0, i.norm, li)) * (1.0f - metallness);
		float fl = abd / 3.141592f;
		float3 brdf = kd * fl + FCT(f0, i.norm, view, li, h, roughness);

		color = color + brdf * Li;
	}

	float3 ambient = 0.03f * abd + Id;
	color = pow(color + ambient, 0.4545f);
	return float4(color, 1.0f);
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

float normalDistributionGGX(float3 N, float3 H, float r)
{
	float _max = max(dot(N, H), 0);
	float _r2 = (r * r - 1);
	return (r * r) / (3.141592 * pow(pow(_max, 2) * _r2 + 1, 2));
}

float geometrySchlickGGX(float3 N, float3 W, float r)
{
	float q = (r + 1.0f) * (r + 1.0f) / 8.0f;
	float mx = max(dot(N, W), 0);
	return mx / (mx * (1 - q) + q);
}

float geometrySmith(float3 N, float3 V, float3 L, float r)
{
	return geometrySchlickGGX(N, V, r) * geometrySchlickGGX(N, L, r);
}

float3 fresnel(float3 f0, float3 N, float3 L)
{
	return f0 + (1.0f - f0) * pow(1.0f - max(dot(N, L), 0), 5);
}

float FCT(float3 f0, float3 norm, float3 view, float3 li, float3 h, float roughness)
{
	if (max(dot(norm, view), 0) * max(dot(norm, li), 0) == 0) return 0;
	return fresnel(f0, h, li) * normalDistributionGGX(norm, h, roughness) * geometrySmith(norm, view, li, roughness) / (4 * max(dot(norm, view), 0) * max(dot(norm, li), 0));
}