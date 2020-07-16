//
//  AGLKPointParticleEffect.m
//  OpenGLES_Ch8_3
//

#import "ParticleEffect.h"
#import "VertexAttribArrayBuffer.h"

// 定义粒子属性的类型
typedef struct
{
   GLKVector3 Position; //位置
   GLKVector4 Color;
   GLKVector3 Velocity; //速度
   GLKVector3 Force;//力
   GLKVector2 Size;//大小
   GLKVector2 Life;//生命周期
}Particle;

//着色器属性
enum
{
   MVPMatrix,
   Samplers2D,
   LapsedSeconds,
   Gravity,
   NumUniforms
};

//属性标识符
typedef enum {
    ParticlePosition = 0,
    ParticleColor,
    ParticleVelocity,
    ParticleForce,
    ParticleSize,
    ParticleLife,
} ParticleAttrib;

@interface ParticleEffect ()
{
   GLfloat elapsedSeconds; //初始时间
   GLuint program;  //shader小程序
   GLint uniforms[NumUniforms];
}

@property (strong, nonatomic, readwrite) 
   VertexAttribArrayBuffer *particleAttributeBuffer; //粒子属性缓冲区
@property (nonatomic, assign, readonly) NSUInteger 
   numberOfParticles;//粒子数目
@property (nonatomic, strong, readonly) NSMutableData  
   *particleAttributesData;//粒子属性数据
@property (nonatomic, assign, readwrite) BOOL  
   particleDataWasUpdated;//粒子数据更新

- (BOOL)loadShaders;//导入shader
- (BOOL)compileShader:(GLuint *)shader //编译shader
   type:(GLenum)type 
   file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;//链接程序
- (BOOL)validateProgram:(GLuint)prog;//验证程序
@end

/////////////////////////////////////////////////////////////////
// 
@implementation ParticleEffect

@synthesize gravity;//重力
@synthesize elapsedSeconds;//经过的时间
@synthesize texture2d0;//纹理标识符
@synthesize transform;//转换
@synthesize particleAttributeBuffer;//粒子属性缓冲
@synthesize particleAttributesData;//粒子属性数据
@synthesize particleDataWasUpdated;//粒子数据更新



// 指定的初始化程序
- (id)init 
{
   if (nil != (self = [super init])) 
   {
      texture2d0 = [[GLKEffectPropertyTexture alloc] init];
      texture2d0.enabled = YES;
      texture2d0.name = 0;
      texture2d0.target = GLKTextureTarget2D;
      texture2d0.envMode = GLKTextureEnvModeReplace;
      transform = [[GLKEffectPropertyTransform alloc] init];
      gravity = DefaultGravity;
      elapsedSeconds = 0.0f;
      particleAttributesData = [NSMutableData data];
   }

   return self;
}


//遍历粒子属性
- (Particle)particleAtIndex:(NSUInteger)Index
{
   NSParameterAssert(Index < self.numberOfParticles);
   
   const Particle *particlesPtr = 
      (const Particle *)[self.particleAttributesData 
         bytes];
      
   return particlesPtr[Index]; 
}



//  设置粒子
- (void)setParticle:(Particle)aParticle
   atIndex:(NSUInteger)Index
{
   NSParameterAssert(Index < self.numberOfParticles);
   
   Particle *particlesPtr =
      (Particle *)[self.particleAttributesData 
         mutableBytes];
   particlesPtr[Index] = aParticle;
   self.particleDataWasUpdated = YES;
}


// 增加粒子坐标
- (void)addParticleAtPosition:(GLKVector3)Position
   velocity:(GLKVector3)Velocity
   force:(GLKVector3)Force
   size:(float)Size
   lifeSpanSeconds:(NSTimeInterval)Span
   fadeDurationSeconds:(NSTimeInterval)Duration;
{
   Particle newParticle;
   newParticle.Position = Position;
   newParticle.Velocity = Velocity;
   newParticle.Force = Force;
   newParticle.Size = GLKVector2Make(Size, Duration);
   newParticle.Life = GLKVector2Make(
      self.elapsedSeconds, self.elapsedSeconds + Span);
   BOOL foundSlot = NO;
   const int count = self.numberOfParticles;
      
   for(int i = 0; i < count && !foundSlot; i++)
   {
      Particle oldParticle =
         [self particleAtIndex:i];
         
      if(oldParticle.Life.y < self.elapsedSeconds)
      {
         [self setParticle:newParticle atIndex:i];
         foundSlot = YES; 
      }
   }

   if(!foundSlot)
   {
      [self.particleAttributesData appendBytes:&newParticle 
         length:sizeof(newParticle)];
      self.particleDataWasUpdated = YES;
   }      
}



- (NSUInteger)numberOfParticles;
{
   return [self.particleAttributesData length] / sizeof(Particle);
}



- (void)prepareToDraw
{
   if(0 == program)
   {
      [self loadShaders];
   }
   
   if(0 != program)
   {
      glUseProgram(program);
              
      //预先计算总变换矩阵
      GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Multiply(
         self.transform.projectionMatrix, 
         self.transform.modelviewMatrix);
      glUniformMatrix4fv(uniforms[MVPMatrix], 1, 0, 
         modelViewProjectionMatrix.m);

      // 一个纹理采样器
      glUniform1i(uniforms[Samplers2D], 0); 

      // 设置粒子物理属性
      glUniform3fv(uniforms[Gravity], 1, self.gravity.v);
      glUniform1fv(uniforms[LapsedSeconds], 1, &elapsedSeconds);

      if(self.particleDataWasUpdated)
      {
         if(nil == self.particleAttributeBuffer && 
            0 < [self.particleAttributesData length])
         {  // 此时顶点属性尚未发送给GPU
            self.particleAttributeBuffer = 
               [[VertexAttribArrayBuffer alloc]
               initWithAttribStride:sizeof(Particle)
               numberOfVertices:[self.particleAttributesData length] / sizeof(Particle)
               bytes:[self.particleAttributesData bytes]
               usage:GL_DYNAMIC_DRAW];
         }
         else
         {
            [self.particleAttributeBuffer
               reinitWithAttribStride:
                  sizeof(Particle)
               numberOfVertices:
                  [self.particleAttributesData length] / sizeof(Particle)
               bytes:[self.particleAttributesData bytes]];
         }
         
         self.particleDataWasUpdated = NO;
      }

      [self.particleAttributeBuffer
         prepareToDrawWithAttrib:ParticlePosition
         numberOfCoordinates:3
         attribOffset:
            offsetof(Particle, Position)
         shouldEnable:YES];
//       [self.particleAttributeBuffer
//        prepareToDrawWithAttrib:ParticleColor
//        numberOfCoordinates:4
//        attribOffset:
//        offsetof(Particle, Color)
//        shouldEnable:YES];

      [self.particleAttributeBuffer
         prepareToDrawWithAttrib:ParticleVelocity
         numberOfCoordinates:3
         attribOffset:
            offsetof(Particle, Velocity)
         shouldEnable:YES];

      [self.particleAttributeBuffer
         prepareToDrawWithAttrib:ParticleForce
         numberOfCoordinates:3
         attribOffset:
            offsetof(Particle, Force)
         shouldEnable:YES];

      [self.particleAttributeBuffer
         prepareToDrawWithAttrib:ParticleSize
         numberOfCoordinates:2
         attribOffset:
            offsetof(Particle, Size)
         shouldEnable:YES];

      [self.particleAttributeBuffer
         prepareToDrawWithAttrib:ParticleLife
         numberOfCoordinates:2
         attribOffset:
            offsetof(Particle, Life)
         shouldEnable:YES];

      // 将所有纹理绑定到它们各自的单位
      glActiveTexture(GL_TEXTURE0);
      if(0 != self.texture2d0.name && self.texture2d0.enabled)
      {
         glBindTexture(GL_TEXTURE_2D, self.texture2d0.name);
      }
      else
      {
         glBindTexture(GL_TEXTURE_2D, 0);
      }
   }
}



- (void)draw;
{
   glDepthMask(GL_FALSE);  //禁用深度缓冲区写入
   [self.particleAttributeBuffer 
      drawArrayWithMode:GL_POINTS
      startVertexIndex:0
      numberOfVertices:self.numberOfParticles];//动态计算
   glDepthMask(GL_TRUE);  // 重新启用深度缓冲区写入
}


#pragma mark -  OpenGL ES 2 shader compilation

/////////////////////////////////////////////////////////////////
// 
- (BOOL)loadShaders
{
   GLuint vertShader, fragShader;
   NSString *vertShaderPathname, *fragShaderPathname;
   
   // 创建shader小程序
   program = glCreateProgram();
   
   // 创建并且编译顶点着色器
   vertShaderPathname = [[NSBundle mainBundle] pathForResource:
      @"magicPen" ofType:@"vsh"];
   if (![self compileShader:&vertShader type:GL_VERTEX_SHADER 
      file:vertShaderPathname]) 
   {
      NSLog(@"Failed to compile vertex shader");
      return NO;
   }
   
   //创建并且编译片元着色器
   fragShaderPathname = [[NSBundle mainBundle] pathForResource:
      @"magicPen" ofType:@"fsh"];
   if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER 
      file:fragShaderPathname]) 
   {
      NSLog(@"Failed to compile fragment shader");
      return NO;
   }
   
   //附加顶点着色器进行编程。
   glAttachShader(program, vertShader);
   
   //将片元着色器附加到程序
   glAttachShader(program, fragShader);
   
   // 绑定shader属性，这需要在链接之前完成
   glBindAttribLocation(program, ParticlePosition, "Position");
   glBindAttribLocation(program, ParticleColor,"color");
   glBindAttribLocation(program, ParticleVelocity, "Velocity");
   glBindAttribLocation(program, ParticleForce, "Force");
   glBindAttribLocation(program, ParticleSize, "size");
   glBindAttribLocation(program, ParticleLife, "DeathTimes");
   //链接
   if (![self linkProgram:program]) 
   {
      NSLog(@"Failed to link program: %d", program);
      
      if (vertShader) 
      {
         glDeleteShader(vertShader);
         vertShader = 0;
      }
      if (fragShader) 
      {
         glDeleteShader(fragShader);
         fragShader = 0;
      }
      if (program) 
      {
         glDeleteProgram(program);
         program = 0;
      }
      
      return NO;
   }

   // 获得统一的位置.
   uniforms[MVPMatrix] = glGetUniformLocation(program, 
      "mvpMatrix");
   uniforms[Samplers2D] = glGetUniformLocation(program, 
      "samplers2D");
   uniforms[Gravity] = glGetUniformLocation(program, 
      "gravity");
   uniforms[LapsedSeconds] = glGetUniformLocation(program, 
      "elapsedSeconds");
   
   // 删除顶点和片元着色器。
   if (vertShader) 
   {
      glDetachShader(program, vertShader);
      glDeleteShader(vertShader);
   }
   if (fragShader) 
   {
      glDetachShader(program, fragShader);
      glDeleteShader(fragShader);
   }
   
   return YES;
}



//编译着色器
- (BOOL)compileShader:(GLuint *)shader 
   type:(GLenum)type 
   file:(NSString *)file
{
   GLint status;
   const GLchar *source;
   
   source = (GLchar *)[[NSString stringWithContentsOfFile:file 
      encoding:NSUTF8StringEncoding error:nil] UTF8String];
   if (!source) 
   {
      NSLog(@"Failed to load vertex shader");
      return NO;
   }
   
   *shader = glCreateShader(type);
   glShaderSource(*shader, 1, &source, NULL);
   glCompileShader(*shader);
   
#if defined(DEBUG)
   GLint logLength;
   glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
   if (logLength > 0) 
   {
      GLchar *log = (GLchar *)malloc(logLength);
      glGetShaderInfoLog(*shader, logLength, &logLength, log);
      NSLog(@"Shader compile log:\n%s", log);
      free(log);
   }
#endif
   
   glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
   if (status == 0) 
   {
      glDeleteShader(*shader);
      return NO;
   }
   
   return YES;
}



//链接程序
- (BOOL)linkProgram:(GLuint)prog
{
   GLint status;
   glLinkProgram(prog);
   
#if defined(DEBUG)
   GLint logLength;
   glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
   if (logLength > 0) 
   {
      GLchar *log = (GLchar *)malloc(logLength);
      glGetProgramInfoLog(prog, logLength, &logLength, log);
      NSLog(@"Program link log:\n%s", log);
      free(log);
   }
#endif
   
   glGetProgramiv(prog, GL_LINK_STATUS, &status);
   if (status == 0) 
   {
      return NO;
   }
   
   return YES;
}



// 验证程序
- (BOOL)validateProgram:(GLuint)prog
{
   GLint logLength, status;
   
   glValidateProgram(prog);
   glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
   if (logLength > 0) 
   {
      GLchar *log = (GLchar *)malloc(logLength);
      glGetProgramInfoLog(prog, logLength, &logLength, log);
      NSLog(@"Program validate log:\n%s", log);
      free(log);
   }
   
   glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
   if (status == 0) 
   {
      return NO;
   }
   
   return YES;
}

@end


/////////////////////////////////////////////////////////////////
// Default gravity acceleration vector matches Earth's 
// {0, (-9.80665 m/s/s), 0} assuming +Y up coordinate system
const GLKVector3 DefaultGravity = {0.0f, -9.80665f, -3.0f};
