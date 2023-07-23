
#include "ReShade.fxh"

uniform int framecount < source = "framecount"; >;

texture prevFrameBuffer
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
};

sampler prevBufferSampler
{
    Texture = prevFrameBuffer;
    MagFilter = POINT;
    MinFilter = POINT;
    MipFilter = POINT;

};

// this is for saving the current frame buffer into the prevBuffer
void saveTargetPass(
    float4 vpos         : SV_Position,
    float2 texcoord     : TEXCOORD,
    out float4 Target   : SV_Target
)
{
    // Set target framerate
    float N = 2;
    bool newFrame = frac(framecount * (1/N)) != 0.0;
    Target = newFrame ? tex2D(prevBufferSampler, texcoord) : tex2D(ReShade::BackBuffer, texcoord);
}

void combineEyes(
    float4 vpos        : SV_Position,
    float2 texcoord    : TEXCOORD,
    out float4 Image   : SV_Target
)
{
    //Set target framerate
    float N = 2;
    bool newFrame = frac(framecount * (1/N)) != 0.0;
    bool leftEye = texcoord.x  < 0.5;
     
    if(leftEye)
    {
        // Rerender foveal pixel based on distance
        float distancecutoff = 0.3f;
        float xcentercutoff = 0.3f;
        bool foveal_pixel = (texcoord.x > xcentercutoff) || (distance(float2(0.5, 0.5), texcoord) < distancecutoff); // arbitrary cutoff
        Image = foveal_pixel ? tex2D(ReShade::BackBuffer, texcoord) : tex2D(prevBufferSampler, texcoord);
    }

    // Is there a nice way to remove these if/else's?
    else
    {
        Image = tex2D(ReShade::BackBuffer, texcoord);
    }


}

technique ReusePeriphery
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = saveTargetPass;
        RenderTarget = prevFrameBuffer;
        ClearRenderTargets = false;
        BlendEnable = true;
            BlendOp = ADD;
                SrcBlend = SRCALPHA;
                DestBlend = INVSRCALPHA;
    }
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = combineEyes;
    }
}

