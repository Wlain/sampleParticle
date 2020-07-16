//
//  ParticleShader.fsh
//  
//

precision highp float;//精度声明
uniform highp mat4      mvpMatrix; //总变换矩阵
uniform sampler2D       samplers2D;//纹理标识符
uniform highp vec3      gravity; //重力
uniform highp float     elapsedSeconds;//初始时间

//varying lowp vec4       color;
varying lowp float      particleOpacity;//粒子透明度，由片段着色器传过来

void main()
{
    //纹理颜色
   //vec4 Color = vec4(1.0,0.0,0.0,0.0);
   lowp vec4 textureColor = texture2D(samplers2D,gl_PointCoord);
   textureColor.a = textureColor.r;
   textureColor.a = textureColor.a * particleOpacity;
   gl_FragColor = textureColor/* * color*/;
}
