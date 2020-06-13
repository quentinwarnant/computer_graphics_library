#ifndef SDF_2D_CGINC
#define SDF_2D_CGINC

static const float PI = 3.141592653589793238462;

float2 SDF_Translate(float2 position, float2 offset)
{
    //Substract because we're redefining where position is by shifting the whole space by offset
    return position - offset;
}

fixed2 SDF_Rotate(float2 position, float rotation_radiants)
{
    float rotation = rotation_radiants * PI * 2;
    rotation *= -1; // we're rotating the space, not the shape, therefore it's backwards
    float sine, cosine;
    sincos(rotation,sine,cosine);
    return float2(cosine * position.x + sine * position.y, cosine * position.y - sine * position.x);
}

fixed2 SDF_Scale(float2 position, float scale)
{
    //Divide because we're reducing de scale of the space to make the object look bigger
    return position / scale;
}


fixed SDF_Circle(float2 position, float size)
{
    return length(position) - size;
}

fixed SDF_Rectangle_Simple(float2 position, float2 size)
{
    float2 halfSize = size * 0.5;
    float2 distanceEdge = abs(position) - halfSize;
    return max(distanceEdge.x, distanceEdge.y);
}

fixed SDF_Rectangle(float2 position, float2 size)
{
    float2 halfSize = size * 0.5;
    float2 distanceEdge = abs(position) - halfSize;
    float distanceInside = min(max(distanceEdge.x, distanceEdge.y), 0 );
    float distanceOutside = length(max(distanceEdge, 0));
    return distanceInside + distanceOutside;
}

float AA_step(float compValue, float gradient)
{
    float halfPixelChange = fwidth(gradient) /2 ; 
    // [][] pixels , get halfway between them
    float lowerEdge = compValue - halfPixelChange;
    float upperEdge = compValue + halfPixelChange;
    //inverse interpolation
    float invInterpolation = saturate( (gradient - lowerEdge) / (upperEdge - lowerEdge) );

    return invInterpolation;
}

#endif