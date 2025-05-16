// Shader created with Shader Forge v1.38 
// Shader Forge (c) Neat Corporation / Joachim Holmer - http://www.acegikmo.com/shaderforge/
// Note: Manually altering this data may prevent you from opening it in Shader Forge
/*SF_DATA;ver:1.38;sub:START;pass:START;ps:flbk:,iptp:0,cusa:False,bamd:0,cgin:,lico:1,lgpr:1,limd:3,spmd:1,trmd:0,grmd:0,uamb:True,mssp:True,bkdf:False,hqlp:False,rprd:False,enco:False,rmgx:True,imps:True,rpth:0,vtps:0,hqsc:True,nrmq:1,nrsp:0,vomd:0,spxs:False,tesm:0,olmd:1,culm:0,bsrc:3,bdst:7,dpts:2,wrdp:True,dith:0,atcv:False,rfrpo:True,rfrpn:Refraction,coma:15,ufog:False,aust:False,igpj:True,qofs:0,qpre:1,rntp:1,fgom:False,fgoc:False,fgod:False,fgor:False,fgmd:0,fgcr:0.5,fgcg:0.5,fgcb:0.5,fgca:1,fgde:0.01,fgrn:0,fgrf:300,stcl:False,atwp:False,stva:128,stmr:255,stmw:255,stcp:6,stps:0,stfa:0,stfz:0,ofsf:0,ofsu:0,f2p0:False,fnsp:False,fnfb:True,fsmp:False;n:type:ShaderForge.SFN_Final,id:4013,x:33147,y:32534,varname:node_4013,prsc:2|diff-2546-OUT,spec-5206-OUT,gloss-8705-OUT,normal-4387-RGB,emission-20-OUT,lwrap-1569-OUT,amdfl-6996-OUT,alpha-3788-OUT,clip-641-OUT;n:type:ShaderForge.SFN_Tex2d,id:3267,x:31721,y:32990,ptovrint:False,ptlb:MainTex,ptin:_MainTex,varname:_MainTex,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,ntxv:0,isnm:False;n:type:ShaderForge.SFN_Slider,id:3131,x:31781,y:32248,ptovrint:False,ptlb:Gloss,ptin:_Gloss,varname:_Gloss,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:1,max:1;n:type:ShaderForge.SFN_Tex2d,id:4387,x:32920,y:32707,ptovrint:False,ptlb:Normal,ptin:_Normal,varname:_Normal,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,ntxv:3,isnm:True;n:type:ShaderForge.SFN_Color,id:9795,x:33352,y:33159,ptovrint:False,ptlb:LightWrapping,ptin:_LightWrapping,varname:_LightWrapping,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,c1:0,c2:0,c3:0,c4:1;n:type:ShaderForge.SFN_Color,id:3452,x:32309,y:32493,ptovrint:False,ptlb:DiffuseColor,ptin:_DiffuseColor,varname:_DiffuseColor,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,c1:1,c2:1,c3:1,c4:1;n:type:ShaderForge.SFN_Multiply,id:2546,x:32618,y:32725,varname:node_2546,prsc:2|A-6421-OUT,B-3452-RGB;n:type:ShaderForge.SFN_Color,id:2182,x:32222,y:33294,ptovrint:False,ptlb:HeightColor,ptin:_HeightColor,varname:_HeightColor,prsc:2,glob:False,taghide:True,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,c1:0,c2:0,c3:0,c4:1;n:type:ShaderForge.SFN_Add,id:20,x:32676,y:33289,varname:node_20,prsc:2|A-7620-OUT,B-2182-RGB,C-1430-OUT,D-5504-OUT;n:type:ShaderForge.SFN_Slider,id:2764,x:31479,y:33275,ptovrint:False,ptlb:EmissionPower,ptin:_EmissionPower,varname:_EmissionPower,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:-1,cur:0,max:1;n:type:ShaderForge.SFN_Multiply,id:7620,x:32513,y:33193,varname:node_7620,prsc:2|A-2546-OUT,B-2764-OUT;n:type:ShaderForge.SFN_Tex2d,id:4696,x:31373,y:32213,ptovrint:False,ptlb: Glossiness(R) Metallic(G)CubeMap(B) ScrollMask(A),ptin:_GlossinessRMetallicGCubeMapBScrollMaskA,varname:_GlossinessRMetallicGCubeMapBScrollMaskA,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,ntxv:0,isnm:False;n:type:ShaderForge.SFN_Multiply,id:5206,x:31900,y:32352,varname:node_5206,prsc:2|A-5310-OUT,B-4696-G;n:type:ShaderForge.SFN_Slider,id:9846,x:32401,y:32963,ptovrint:False,ptlb:Cullout,ptin:_Cullout,varname:_Cullout,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:0,max:1;n:type:ShaderForge.SFN_Subtract,id:1611,x:32750,y:32886,varname:node_1611,prsc:2|A-3788-OUT,B-9846-OUT;n:type:ShaderForge.SFN_ViewVector,id:8190,x:31934,y:33490,varname:node_8190,prsc:2;n:type:ShaderForge.SFN_NormalVector,id:8335,x:31934,y:34054,prsc:2,pt:False;n:type:ShaderForge.SFN_Normalize,id:6717,x:32178,y:33532,varname:node_6717,prsc:2|IN-8190-OUT;n:type:ShaderForge.SFN_Dot,id:4336,x:32412,y:33824,varname:node_4336,prsc:2,dt:0|A-6717-OUT,B-8335-OUT;n:type:ShaderForge.SFN_Clamp01,id:3492,x:32647,y:33586,varname:node_3492,prsc:2|IN-4336-OUT;n:type:ShaderForge.SFN_OneMinus,id:1449,x:32715,y:33680,varname:node_1449,prsc:2|IN-3492-OUT;n:type:ShaderForge.SFN_Color,id:8379,x:32528,y:33873,ptovrint:False,ptlb:RimColor,ptin:_RimColor,varname:_RimColor,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,c1:0,c2:0,c3:0,c4:1;n:type:ShaderForge.SFN_Multiply,id:1430,x:32819,y:33797,varname:node_1430,prsc:2|A-1449-OUT,B-1144-OUT;n:type:ShaderForge.SFN_Color,id:1424,x:32327,y:34313,ptovrint:False,ptlb:SelectionColor,ptin:_SelectionColor,varname:_SelectionColor,prsc:2,glob:False,taghide:True,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,c1:0,c2:0,c3:0,c4:1;n:type:ShaderForge.SFN_If,id:1144,x:32775,y:33981,varname:node_1144,prsc:2|A-5838-OUT,B-1718-OUT,GT-1424-RGB,EQ-8379-RGB,LT-8379-RGB;n:type:ShaderForge.SFN_Vector1,id:1718,x:32346,y:34018,varname:node_1718,prsc:2,v1:0;n:type:ShaderForge.SFN_Max,id:5838,x:32667,y:34327,varname:node_5838,prsc:2|A-1424-R,B-1424-G,C-1424-B;n:type:ShaderForge.SFN_Multiply,id:6359,x:32225,y:32305,varname:node_6359,prsc:2|A-4696-R,B-3131-OUT;n:type:ShaderForge.SFN_Slider,id:5310,x:31373,y:32437,ptovrint:False,ptlb:Metallic,ptin:_Metallic,varname:_Metallic,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:0,max:1;n:type:ShaderForge.SFN_OneMinus,id:8705,x:32421,y:32355,varname:node_8705,prsc:2|IN-6359-OUT;n:type:ShaderForge.SFN_Tex2d,id:6722,x:31692,y:32796,ptovrint:False,ptlb:ColorTex,ptin:_ColorTex,varname:_ColorTex,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,ntxv:0,isnm:False;n:type:ShaderForge.SFN_Add,id:6421,x:32294,y:32728,varname:node_6421,prsc:2|A-3267-RGB,B-9112-OUT,C-9858-OUT;n:type:ShaderForge.SFN_Color,id:8467,x:31692,y:32460,ptovrint:False,ptlb:Color1,ptin:_Color1,varname:_Color1,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,c1:0,c2:0,c3:0,c4:1;n:type:ShaderForge.SFN_Multiply,id:9112,x:31930,y:32564,varname:node_9112,prsc:2|A-8467-RGB,B-6722-R;n:type:ShaderForge.SFN_Color,id:6375,x:31692,y:32630,ptovrint:False,ptlb:Color2,ptin:_Color2,varname:_Color2,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,c1:0,c2:0,c3:0,c4:1;n:type:ShaderForge.SFN_Multiply,id:9858,x:31930,y:32695,varname:node_9858,prsc:2|A-6375-RGB,B-6722-G;n:type:ShaderForge.SFN_Multiply,id:1569,x:33561,y:33159,varname:node_1569,prsc:2|A-9795-RGB,B-3422-OUT;n:type:ShaderForge.SFN_Slider,id:3422,x:33274,y:33333,ptovrint:False,ptlb:LightWrappingPower,ptin:_LightWrappingPower,varname:_LightWrappingPower,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:1,max:2;n:type:ShaderForge.SFN_Slider,id:3820,x:33017,y:34028,ptovrint:False,ptlb:ScrollSpeed,ptin:_ScrollSpeed,varname:_ScrollSpeed,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:0,max:1;n:type:ShaderForge.SFN_Append,id:7881,x:33378,y:33843,varname:node_7881,prsc:2|A-9258-OUT,B-5133-OUT;n:type:ShaderForge.SFN_Slider,id:9258,x:33028,y:33827,ptovrint:False,ptlb:ScrollU,ptin:_ScrollU,varname:_ScrollU,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:-1,cur:0,max:1;n:type:ShaderForge.SFN_Slider,id:5133,x:33028,y:33915,ptovrint:False,ptlb:ScrollV,ptin:_ScrollV,varname:_ScrollV,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:-1,cur:0,max:1;n:type:ShaderForge.SFN_Normalize,id:7498,x:33564,y:33843,varname:node_7498,prsc:2|IN-7881-OUT;n:type:ShaderForge.SFN_Multiply,id:7513,x:33730,y:33946,varname:node_7513,prsc:2|A-7498-OUT,B-3820-OUT,C-8246-T;n:type:ShaderForge.SFN_Time,id:8246,x:33448,y:34050,varname:node_8246,prsc:2;n:type:ShaderForge.SFN_TexCoord,id:2266,x:33123,y:33652,varname:node_2266,prsc:2,uv:0,uaff:False;n:type:ShaderForge.SFN_Add,id:551,x:33639,y:33619,varname:node_551,prsc:2|A-2266-UVOUT,B-7513-OUT;n:type:ShaderForge.SFN_Tex2d,id:4682,x:33314,y:33578,ptovrint:False,ptlb:ScrollTex,ptin:_ScrollTex,varname:_ScrollTex,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,ntxv:2,isnm:False|UVIN-551-OUT;n:type:ShaderForge.SFN_Multiply,id:5504,x:33222,y:33431,varname:node_5504,prsc:2|A-4696-A,B-4682-RGB;n:type:ShaderForge.SFN_Cubemap,id:8471,x:33670,y:32620,ptovrint:False,ptlb:CubeMap,ptin:_CubeMap,varname:_CubeMap,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,pvfc:0;n:type:ShaderForge.SFN_Slider,id:7516,x:33400,y:32789,ptovrint:False,ptlb:CubeMapPower,ptin:_CubeMapPower,varname:_CubeMapPower,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:1,max:5;n:type:ShaderForge.SFN_Multiply,id:6996,x:33483,y:32498,varname:node_6996,prsc:2|A-8471-RGB,B-7516-OUT,C-4696-B;n:type:ShaderForge.SFN_Slider,id:268,x:31989,y:32893,ptovrint:False,ptlb:Alpha,ptin:_Alpha,varname:_Alpha,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:1,max:1;n:type:ShaderForge.SFN_Multiply,id:3788,x:32401,y:32872,varname:node_3788,prsc:2|A-268-OUT,B-3267-A;n:type:ShaderForge.SFN_Add,id:641,x:32930,y:32886,varname:node_641,prsc:2|A-1611-OUT,B-3561-OUT;n:type:ShaderForge.SFN_Vector1,id:3561,x:32807,y:33066,varname:node_3561,prsc:2,v1:0.5;n:type:ShaderForge.SFN_Vector1,id:4414,x:32709,y:32322,varname:node_4414,prsc:2,v1:0;proporder:3452-3267-4387-4696-6722-2764-9795-3422-2182-9846-268-8379-1424-3131-5310-8467-6375-4682-3820-9258-5133-8471-7516;pass:END;sub:END;*/

Shader "shixiu/Role2" {
    Properties {
        _DiffuseColor ("DiffuseColor", Color) = (1,1,1,1)
        _MainTex ("MainTex", 2D) = "white" {}
        _Normal ("Normal", 2D) = "bump" {}
        _GlossinessRMetallicGCubeMapBScrollMaskA (" Glossiness(R) Metallic(G)CubeMap(B) ScrollMask(A)", 2D) = "white" {}
        _ColorTex ("ColorTex", 2D) = "white" {}
        _EmissionPower ("EmissionPower", Range(-1, 1)) = 0
        _LightWrapping ("LightWrapping", Color) = (0,0,0,1)
        _LightWrappingPower ("LightWrappingPower", Range(0, 2)) = 1
        [HideInInspector]_HeightColor ("HeightColor", Color) = (0,0,0,1)
        _Cullout ("Cullout", Range(0, 1)) = 0
        _Alpha ("Alpha", Range(0, 1)) = 1
        _RimColor ("RimColor", Color) = (0,0,0,1)
        [HideInInspector]_SelectionColor ("SelectionColor", Color) = (0,0,0,1)
        _Gloss ("Gloss", Range(0, 1)) = 1
        _Metallic ("Metallic", Range(0, 1)) = 0
        _Color1 ("Color1", Color) = (0,0,0,1)
        _Color2 ("Color2", Color) = (0,0,0,1)
        _ScrollTex ("ScrollTex", 2D) = "black" {}
        _ScrollSpeed ("ScrollSpeed", Range(0, 1)) = 0
        _ScrollU ("ScrollU", Range(-1, 1)) = 0
        _ScrollV ("ScrollV", Range(-1, 1)) = 0
        _CubeMap ("CubeMap", Cube) = "_Skybox" {}
        _CubeMapPower ("CubeMapPower", Range(0, 5)) = 1
        [HideInInspector]_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "RenderType"="Opaque"
        }
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            Blend SrcAlpha OneMinusSrcAlpha
            
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityStandardBRDF.cginc"
            #pragma multi_compile_fwdbase
            #pragma only_renderers d3d11 glcore gles gles3 metal 
            #pragma target 3.0
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform float _Gloss;
            uniform sampler2D _Normal; uniform float4 _Normal_ST;
            uniform float4 _LightWrapping;
            uniform float4 _DiffuseColor;
            uniform float4 _HeightColor;
            uniform float _EmissionPower;
            uniform sampler2D _GlossinessRMetallicGCubeMapBScrollMaskA; uniform float4 _GlossinessRMetallicGCubeMapBScrollMaskA_ST;
            uniform float _Cullout;
            uniform float4 _RimColor;
            uniform float4 _SelectionColor;
            uniform float _Metallic;
            uniform sampler2D _ColorTex; uniform float4 _ColorTex_ST;
            uniform float4 _Color1;
            uniform float4 _Color2;
            uniform float _LightWrappingPower;
            uniform float _ScrollSpeed;
            uniform float _ScrollU;
            uniform float _ScrollV;
            uniform sampler2D _ScrollTex; uniform float4 _ScrollTex_ST;
            uniform samplerCUBE _CubeMap;
            uniform float _CubeMapPower;
            uniform float _Alpha;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                float3 tangentDir : TEXCOORD3;
                float3 bitangentDir : TEXCOORD4;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                float3 lightColor = _LightColor0.rgb;
                o.pos = UnityObjectToClipPos( v.vertex );
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
                i.normalDir = normalize(i.normalDir);
                float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float3 _Normal_var = UnpackNormal(tex2D(_Normal,TRANSFORM_TEX(i.uv0, _Normal)));
                float3 normalLocal = _Normal_var.rgb;
                float3 normalDirection = normalize(mul( normalLocal, tangentTransform )); // Perturbed normals
                float3 viewReflectDirection = reflect( -viewDirection, normalDirection );
                float4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
                float node_3788 = (_Alpha*_MainTex_var.a);
                clip(((node_3788-_Cullout)+0.5) - 0.5);
                float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                float3 lightColor = _LightColor0.rgb;
                float3 halfDirection = normalize(viewDirection+lightDirection);
////// Lighting:
                float attenuation = 1;
                float3 attenColor = attenuation * _LightColor0.xyz;
                float Pi = 3.141592654;
                float InvPi = 0.31830988618;
///////// Gloss:
                float4 _GlossinessRMetallicGCubeMapBScrollMaskA_var = tex2D(_GlossinessRMetallicGCubeMapBScrollMaskA,TRANSFORM_TEX(i.uv0, _GlossinessRMetallicGCubeMapBScrollMaskA));
                float gloss = (1.0 - (_GlossinessRMetallicGCubeMapBScrollMaskA_var.r*_Gloss));
                float perceptualRoughness = 1.0 - (1.0 - (_GlossinessRMetallicGCubeMapBScrollMaskA_var.r*_Gloss));
                float roughness = perceptualRoughness * perceptualRoughness;
                float specPow = exp2( gloss * 10.0 + 1.0 );
/////// GI Data:
                UnityLight light;
                #ifdef LIGHTMAP_OFF
                    light.color = lightColor;
                    light.dir = lightDirection;
                    light.ndotl = LambertTerm (normalDirection, light.dir);
                #else
                    light.color = half3(0.f, 0.f, 0.f);
                    light.ndotl = 0.0f;
                    light.dir = half3(0.f, 0.f, 0.f);
                #endif
                UnityGIInput d;
                d.light = light;
                d.worldPos = i.posWorld.xyz;
                d.worldViewDir = viewDirection;
                d.atten = attenuation;
                Unity_GlossyEnvironmentData ugls_en_data;
                ugls_en_data.roughness = 1.0 - gloss;
                ugls_en_data.reflUVW = viewReflectDirection;
                UnityGI gi = UnityGlobalIllumination(d, 1, normalDirection, ugls_en_data );
                lightDirection = gi.light.dir;
                lightColor = gi.light.color;
////// Specular:
                float NdotL = saturate(dot( normalDirection, lightDirection ));
                float LdotH = saturate(dot(lightDirection, halfDirection));
                float3 specularColor = (_Metallic*_GlossinessRMetallicGCubeMapBScrollMaskA_var.g);
                float specularMonochrome;
                float4 _ColorTex_var = tex2D(_ColorTex,TRANSFORM_TEX(i.uv0, _ColorTex));
                float3 node_2546 = ((_MainTex_var.rgb+(_Color1.rgb*_ColorTex_var.r)+(_Color2.rgb*_ColorTex_var.g))*_DiffuseColor.rgb);
                float3 diffuseColor = node_2546; // Need this for specular when using metallic
                diffuseColor = DiffuseAndSpecularFromMetallic( diffuseColor, specularColor, specularColor, specularMonochrome );
                specularMonochrome = 1.0-specularMonochrome;
                float NdotV = abs(dot( normalDirection, viewDirection ));
                float NdotH = saturate(dot( normalDirection, halfDirection ));
                float VdotH = saturate(dot( viewDirection, halfDirection ));
                float visTerm = SmithJointGGXVisibilityTerm( NdotL, NdotV, 1.0-gloss );
                float normTerm = max(0,GGXTerm(NdotH, 1.0-gloss));
                float specularPBL = (visTerm*normTerm) * UNITY_PI;
                #ifdef UNITY_COLORSPACE_GAMMA
                    specularPBL = LinearToGammaSpace( specularPBL);
                #endif
                specularPBL = max(0, specularPBL * NdotL);
                #if defined(_SPECULARHIGHLIGHTS_OFF)
                    specularPBL = 0.0;
                #endif
                specularPBL *= any(specularColor) ? 1.0 : 0.0;
                float3 directSpecular = attenColor*specularPBL*FresnelTerm(specularColor, LdotH);
                float3 specular = directSpecular;
/////// Diffuse:
                NdotL = dot( normalDirection, lightDirection );
                float3 w = (_LightWrapping.rgb*_LightWrappingPower)*0.5; // Light wrapping
                float3 NdotLWrap = NdotL * ( 1.0 - w );
                float3 forwardLight = max(float3(0.0,0.0,0.0), NdotLWrap + w );
                NdotL = max(0.0,dot( normalDirection, lightDirection ));
                half fd90 = 0.5 + 2 * LdotH * LdotH * (1-gloss);
                float nlPow5 = Pow5(1-NdotLWrap);
                float nvPow5 = Pow5(1-NdotV);
                float3 directDiffuse = (forwardLight + ((1 +(fd90 - 1)*nlPow5) * (1 + (fd90 - 1)*nvPow5) * NdotL)) * attenColor;
                float3 indirectDiffuse = float3(0,0,0);
                indirectDiffuse += UNITY_LIGHTMODEL_AMBIENT.rgb; // Ambient Light
                indirectDiffuse += (texCUBE(_CubeMap,viewReflectDirection).rgb*_CubeMapPower*_GlossinessRMetallicGCubeMapBScrollMaskA_var.b); // Diffuse Ambient Light
                float3 diffuse = (directDiffuse + indirectDiffuse) * diffuseColor;
////// Emissive:
                float node_1144_if_leA = step(max(max(_SelectionColor.r,_SelectionColor.g),_SelectionColor.b),0.0);
                float node_1144_if_leB = step(0.0,max(max(_SelectionColor.r,_SelectionColor.g),_SelectionColor.b));
                float4 node_8246 = _Time;
                float2 node_551 = (i.uv0+(normalize(float2(_ScrollU,_ScrollV))*_ScrollSpeed*node_8246.g));
                float4 _ScrollTex_var = tex2D(_ScrollTex,TRANSFORM_TEX(node_551, _ScrollTex));
                float3 emissive = ((node_2546*_EmissionPower)+_HeightColor.rgb+((1.0 - saturate(dot(normalize(viewDirection),i.normalDir)))*lerp((node_1144_if_leA*_RimColor.rgb)+(node_1144_if_leB*_SelectionColor.rgb),_RimColor.rgb,node_1144_if_leA*node_1144_if_leB))+(_GlossinessRMetallicGCubeMapBScrollMaskA_var.a*_ScrollTex_var.rgb));
/// Final Color:
                float3 finalColor = diffuse + specular + emissive;
                return fixed4(finalColor,node_3788);
            }
            ENDCG
        }
        Pass {
            Name "FORWARD_DELTA"
            Tags {
                "LightMode"="ForwardAdd"
            }
            Blend One One
            
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDADD
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityStandardBRDF.cginc"
            #pragma multi_compile_fwdadd
            #pragma only_renderers d3d11 glcore gles gles3 metal 
            #pragma target 3.0
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform float _Gloss;
            uniform sampler2D _Normal; uniform float4 _Normal_ST;
            uniform float4 _LightWrapping;
            uniform float4 _DiffuseColor;
            uniform float4 _HeightColor;
            uniform float _EmissionPower;
            uniform sampler2D _GlossinessRMetallicGCubeMapBScrollMaskA; uniform float4 _GlossinessRMetallicGCubeMapBScrollMaskA_ST;
            uniform float _Cullout;
            uniform float4 _RimColor;
            uniform float4 _SelectionColor;
            uniform float _Metallic;
            uniform sampler2D _ColorTex; uniform float4 _ColorTex_ST;
            uniform float4 _Color1;
            uniform float4 _Color2;
            uniform float _LightWrappingPower;
            uniform float _ScrollSpeed;
            uniform float _ScrollU;
            uniform float _ScrollV;
            uniform sampler2D _ScrollTex; uniform float4 _ScrollTex_ST;
            uniform float _Alpha;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                float3 tangentDir : TEXCOORD3;
                float3 bitangentDir : TEXCOORD4;
                LIGHTING_COORDS(5,6)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                float3 lightColor = _LightColor0.rgb;
                o.pos = UnityObjectToClipPos( v.vertex );
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
                i.normalDir = normalize(i.normalDir);
                float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float3 _Normal_var = UnpackNormal(tex2D(_Normal,TRANSFORM_TEX(i.uv0, _Normal)));
                float3 normalLocal = _Normal_var.rgb;
                float3 normalDirection = normalize(mul( normalLocal, tangentTransform )); // Perturbed normals
                float4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
                float node_3788 = (_Alpha*_MainTex_var.a);
                clip(((node_3788-_Cullout)+0.5) - 0.5);
                float3 lightDirection = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.posWorld.xyz,_WorldSpaceLightPos0.w));
                float3 lightColor = _LightColor0.rgb;
                float3 halfDirection = normalize(viewDirection+lightDirection);
////// Lighting:
                float attenuation = LIGHT_ATTENUATION(i);
                float3 attenColor = attenuation * _LightColor0.xyz;
                float Pi = 3.141592654;
                float InvPi = 0.31830988618;
///////// Gloss:
                float4 _GlossinessRMetallicGCubeMapBScrollMaskA_var = tex2D(_GlossinessRMetallicGCubeMapBScrollMaskA,TRANSFORM_TEX(i.uv0, _GlossinessRMetallicGCubeMapBScrollMaskA));
                float gloss = (1.0 - (_GlossinessRMetallicGCubeMapBScrollMaskA_var.r*_Gloss));
                float perceptualRoughness = 1.0 - (1.0 - (_GlossinessRMetallicGCubeMapBScrollMaskA_var.r*_Gloss));
                float roughness = perceptualRoughness * perceptualRoughness;
                float specPow = exp2( gloss * 10.0 + 1.0 );
////// Specular:
                float NdotL = saturate(dot( normalDirection, lightDirection ));
                float LdotH = saturate(dot(lightDirection, halfDirection));
                float3 specularColor = (_Metallic*_GlossinessRMetallicGCubeMapBScrollMaskA_var.g);
                float specularMonochrome;
                float4 _ColorTex_var = tex2D(_ColorTex,TRANSFORM_TEX(i.uv0, _ColorTex));
                float3 node_2546 = ((_MainTex_var.rgb+(_Color1.rgb*_ColorTex_var.r)+(_Color2.rgb*_ColorTex_var.g))*_DiffuseColor.rgb);
                float3 diffuseColor = node_2546; // Need this for specular when using metallic
                diffuseColor = DiffuseAndSpecularFromMetallic( diffuseColor, specularColor, specularColor, specularMonochrome );
                specularMonochrome = 1.0-specularMonochrome;
                float NdotV = abs(dot( normalDirection, viewDirection ));
                float NdotH = saturate(dot( normalDirection, halfDirection ));
                float VdotH = saturate(dot( viewDirection, halfDirection ));
                float visTerm = SmithJointGGXVisibilityTerm( NdotL, NdotV, 1.0-gloss );
                float normTerm = max(0,GGXTerm(NdotH, 1.0-gloss));
                float specularPBL = (visTerm*normTerm) * UNITY_PI;
                #ifdef UNITY_COLORSPACE_GAMMA
                    specularPBL = LinearToGammaSpace( specularPBL);
                #endif
                specularPBL = max(0, specularPBL * NdotL);
                #if defined(_SPECULARHIGHLIGHTS_OFF)
                    specularPBL = 0.0;
                #endif
                specularPBL *= any(specularColor) ? 1.0 : 0.0;
                float3 directSpecular = attenColor*specularPBL*FresnelTerm(specularColor, LdotH);
                float3 specular = directSpecular;
/////// Diffuse:
                NdotL = dot( normalDirection, lightDirection );
                float3 w = (_LightWrapping.rgb*_LightWrappingPower)*0.5; // Light wrapping
                float3 NdotLWrap = NdotL * ( 1.0 - w );
                float3 forwardLight = max(float3(0.0,0.0,0.0), NdotLWrap + w );
                NdotL = max(0.0,dot( normalDirection, lightDirection ));
                half fd90 = 0.5 + 2 * LdotH * LdotH * (1-gloss);
                float nlPow5 = Pow5(1-NdotLWrap);
                float nvPow5 = Pow5(1-NdotV);
                float3 directDiffuse = (forwardLight + ((1 +(fd90 - 1)*nlPow5) * (1 + (fd90 - 1)*nvPow5) * NdotL)) * attenColor;
                float3 diffuse = directDiffuse * diffuseColor;
/// Final Color:
                float3 finalColor = diffuse + specular;
                return fixed4(finalColor * node_3788,0);
            }
            ENDCG
        }
        Pass {
            Name "ShadowCaster"
            Tags {
                "LightMode"="ShadowCaster"
            }
            Offset 1, 1
            Cull Back
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_SHADOWCASTER
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityStandardBRDF.cginc"
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_shadowcaster
            #pragma only_renderers d3d11 glcore gles gles3 metal 
            #pragma target 3.0
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform float _Cullout;
            uniform float _Alpha;
            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                V2F_SHADOW_CASTER;
                float2 uv0 : TEXCOORD1;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.pos = UnityObjectToClipPos( v.vertex );
                TRANSFER_SHADOW_CASTER(o)
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
                float4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
                float node_3788 = (_Alpha*_MainTex_var.a);
                clip(((node_3788-_Cullout)+0.5) - 0.5);
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
    CustomEditor "ShaderForgeMaterialInspector"
}
