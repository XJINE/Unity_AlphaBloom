using System.Collections.Generic;
using UnityEngine;

public class AlphaBloom : ImageEffectBase
{
    #region Enum

    public enum CompositeType
    {
        _COMPOSITE_TYPE_ADDITIVE = 0,
        _COMPOSITE_TYPE_SCREEN   = 1,
        _COMPOSITE_TYPE_DEBUG    = 2
    }

    #endregion Enum

    #region Field

    private static Dictionary<CompositeType, string> CompositeTypes = new Dictionary<CompositeType, string>()
    {
        { CompositeType._COMPOSITE_TYPE_ADDITIVE, CompositeType._COMPOSITE_TYPE_ADDITIVE.ToString() },
        { CompositeType._COMPOSITE_TYPE_SCREEN,   CompositeType._COMPOSITE_TYPE_SCREEN.ToString()   },
        { CompositeType._COMPOSITE_TYPE_DEBUG,    CompositeType._COMPOSITE_TYPE_DEBUG.ToString()    }
    };

    public AlphaBloom.CompositeType compositeType = AlphaBloom.CompositeType._COMPOSITE_TYPE_ADDITIVE;

    [Range(0,  10)] public float peek      = 1;
    [Range(0,   1)] public float threshold = 1;
    [Range(0, 100)] public float intensity = 1;
    [Range(1,  10)] public float size      = 1;
    [Range(1,  10)] public int   divide    = 3;
    [Range(1,   5)] public int   iteration = 5;

    private int idCompositeTex   = 0;
    private int idParameter      = 0;

    #endregion Field

    #region Method

    protected override void Start()
    {
        base.Start();
        this.idCompositeTex   = Shader.PropertyToID("_CompositeTex");
        this.idParameter      = Shader.PropertyToID("_Parameter");
    }

    protected override void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        RenderTexture resizedTex1 = RenderTexture.GetTemporary(source.width / this.divide,
                                                               source.height / this.divide,
                                                               0,
                                                               RenderTextureFormat.DefaultHDR);
        RenderTexture resizedTex2 = RenderTexture.GetTemporary(resizedTex1.descriptor);

        // STEP:0
        // Get resized birghtness image.

        base.material.SetVector(this.idParameter, new Vector4(this.peek, this.threshold, this.intensity, this.size));

        Graphics.Blit(source, resizedTex1, base.material, 0);

        // DEBUG:
        // Graphics.Blit(resizedTex1, destination ,base.material, 0);
        // RenderTexture.ReleaseTemporary(resizedTex1);
        // RenderTexture.ReleaseTemporary(resizedTex2);
        // return;

        // STEP:1,2
        // Get blurred brightness image.

        for (int i = 1; i <= this.iteration; i++)
        {
            Graphics.Blit(resizedTex1, resizedTex2, base.material, 1);
            Graphics.Blit(resizedTex2, resizedTex1, base.material, 2);

            base.material.SetVector(this.idParameter, new Vector4(this.peek, this.threshold, this.intensity, this.size + i));
        }

        // STEP:3
        // Composite.

        base.material.EnableKeyword(AlphaBloom.CompositeTypes[this.compositeType]);
        base.material.SetTexture(this.idCompositeTex, resizedTex1);

        Graphics.Blit(source, destination, base.material, 3);

        // STEP:4
        // Close.

        base.material.DisableKeyword(AlphaBloom.CompositeTypes[this.compositeType]);

        RenderTexture.ReleaseTemporary(resizedTex1);
        RenderTexture.ReleaseTemporary(resizedTex2);
    }

    #endregion Method
}