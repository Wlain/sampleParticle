//
//  ParticleShader.vsh
//
//
// 顶点属性

attribute vec3 Position;//初始位置
attribute vec3 Velocity;//速度
attribute vec3 Force;//力 ：f=ma 即加速度
attribute vec2 size;//粒子大小
attribute vec2 DeathTimes;//死亡时间

uniform lowp vec4 vertexColor;
varying lowp vec4 color;

// 一致属性
//uniform lowp vec4       vertexColor;
uniform highp mat4      mvpMatrix; //总变换矩阵
uniform sampler2D       samplers2D; //纹理采样器//纹理取样标实
uniform highp vec3      gravity; //重力
uniform highp float     elapsedSeconds;//经过的时间，初始时间


//varying lowp vec4       color;
varying lowp float      particleOpacity;//粒子透明度


void main()
{
    color = vertexColor;
    //color = vertexColor;
    //过去时间=初始时间 - 死亡时间
    highp float elapsedTime = elapsedSeconds - DeathTimes.x;
    //存活时间
    // 质量假设为单位1, 加速度a=f/m
    //v = v0 + at
    highp vec3 velocity = Velocity + ((Force + gravity) * elapsedTime);
    
    // s = s0 + 0.5 * (v0 + v) * t 画个vt图，求面积就是总距离
    highp vec3 untransformedPosition = Position + 0.5 * (Velocity + velocity) * elapsedTime;
    //gl_Position = 总变换矩阵*（s，1.0）;
    //gl_PointSize =size.x = gl_Position.w偏移度
    gl_Position = mvpMatrix * vec4(untransformedPosition, 1.0);
    gl_PointSize = size.x / gl_Position.w;
    //如果particle生命> 经过时间然而且最大值不小于0
    // 透明度为1，否则透明度为0，淡入size.y秒
    //求粒子透明度
    particleOpacity = max(0.0, min(1.0,(DeathTimes.y - elapsedSeconds) / max(size.y, 0.00001)));
}


