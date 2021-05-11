float4 camPos;
sampler samp;
textureCUBE envMap;

struct PSInput
{
	float4 pos:SV_POSITION;
	float3 localPos:POSITION0;
	float3 worldPos:POSITION1;
};


float3 intersectRay(float3 p, float3 d)
{
	float tx = max((1 - p.x) / d.x, (-1 - p.x) / d.x);
	float ty = max((1 - p.y) / d.y, (-1 - p.y) / d.y);
	float tz = max((1 - p.z) / d.z, (-1 - p.z) / d.z);

	float t = min(tx, min(ty, tz));
	return p + d * t;
}

float fresnel(float n1, float n2, float3 N, float3 V)
{
	float F0 = pow((n2 - n1) / (n2 + n1), 2);
	/*if (dot(N, V) < 0)
	{
		N = -N
	};*/
	float cos = max(dot(N, V), 0);
	return F0 + (1.0f - F0) * pow((1.0f - cos), 5);
}

float4 main(PSInput i) :SV_TARGET
{
	float3 viewVec = normalize(camPos.xyz - i.worldPos);
	float3 norm = float3(0.0f, 1.0f, 0.0f);
	float3 reflection = reflect(viewVec, norm);
	float3 refraction = refract(viewVec, norm, 0.17f);
	/*float3 color = envMap.Sample(samp, i.tex).rgb;
	color = pow(color, 0.4545f);
	return float4(color, 1.0f);*/

	float3 reflect = intersectRay(i.localPos, reflection);
	float3 color = envMap.Sample(samp, reflect).rgb;
	color = pow(color, 0.4545f);
	return float4(color, 1.0f);

}