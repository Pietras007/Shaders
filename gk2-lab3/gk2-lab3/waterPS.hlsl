float4 camPos;
sampler samp;
textureCUBE envMap;
texture3D perlin;
float time;

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
	if (dot(N, V) < 0)
	{
		N = -N;
	}

	float cos = max(dot(N, V), 0);
	return F0 + (1.0f - F0) * pow((1.0f - cos), 5);
}

float4 main(PSInput i) :SV_TARGET
{
	float3 viewVec = normalize(camPos.xyz - i.worldPos);
	//float3 norm = float3(0.0f, 1.0f, 0.0f);

	float3 tex = float3(i.localPos.xz * 10.0f, time);
	float ex = perlin.Sample(samp, tex);
	tex.x += float3(0.5f, 0.5f, 0.5f);

	float ez = perlin.Sample(samp, tex);
	float3 N = normalize(float3(ex, 20.0f, ez));

	float3 reflection = reflect(-viewVec, N);
	float n1 = 1.0f;
	float n2 = 4.0f / 3.0f;
	float x = n1 / n2;
	if (dot(N, viewVec) < 0) x = n2 / n1;
	float3 refraction = refract(-viewVec, N, x);
	float fres = fresnel(n1, n2, N, viewVec);

	float3 reflect = intersectRay(i.localPos, reflection);
	float3 colorReflect = envMap.Sample(samp, reflect).rgb;

	float3 refract = intersectRay(i.localPos, refraction);
	float3 colorRefract = envMap.Sample(samp, refract).rgb;
	float3 color = fres * colorReflect + (1.0f - fres) * colorRefract;
	if (dot(N, viewVec) < 0)
	{
		refract.y = -refract.y;
		color = envMap.Sample(samp, refract).rgb;
		if (!any(refraction))
		{
			color = colorReflect;
		}
	}

	color = pow(color, 0.4545f);
	return float4(color, 1.0f);

}