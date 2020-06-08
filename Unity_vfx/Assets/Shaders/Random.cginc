#ifndef Q_RANDOM
#define Q_RANDOM

float Random3dTo1d(float3 vec, float3 dotDir = float3(42.04, 21.251, 11.501))
{
    // Reduce scope of value, to avoid artefacts.
    vec = sin(vec);
    float result = dot(vec, dotDir);

    // Sin is again used to reduce scope, to avoid hitting float precision limit
    result = frac( sin(result) * 59442.11230);

    return result;
}

float3 Random3dTo3d(float3 vec)
{
    float3 result;
    result.x = Random3dTo1d(vec, float3(42.04, 21.251, 11.501));
    result.y = Random3dTo1d(vec, float3(12.44, 91.651, 44.105));
    result.z = Random3dTo1d(vec, float3(4.04, 1.251, 156.671));

    return result;
}

float Random1dto1d(float value )
{
    float mutator = 45112.1233125;
    value = frac(sin( value + mutator) * 512.05532);
    return value;
}

#endif
