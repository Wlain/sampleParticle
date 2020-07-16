//
//  AGLKPointParticleEffect.h
//  OpenGLES_Ch8_3
//

#import <GLKit/GLKit.h>


//默认重力加速度矢量与地球相匹配
// {0, (-9.80665 m/s/s), 0} 假设 +Y up 坐标系统
extern const GLKVector3 DefaultGravity;

@interface ParticleEffect : NSObject  <GLKNamedEffect>

@property (nonatomic, assign) GLKVector3 gravity;                
@property (nonatomic, assign) GLfloat elapsedSeconds;
@property (strong, nonatomic, readonly) GLKEffectPropertyTexture* texture2d0;
@property (strong, nonatomic, readonly) GLKEffectPropertyTransform* transform;

- (void)addParticleAtPosition:(GLKVector3)Position
   velocity:(GLKVector3)Velocity
   force:(GLKVector3)Force
   size:(float)Size
   lifeSpanSeconds:(NSTimeInterval)Span
   fadeDurationSeconds:(NSTimeInterval)Duration;

- (void)prepareToDraw;
- (void)draw;

@end
