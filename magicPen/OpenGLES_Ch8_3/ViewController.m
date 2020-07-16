//
//  OpenGLES_Ch8_3ViewController.m
//  OpenGLES_Ch8_3
//

#import "ViewController.h"
#import "Context.h"
#import "ParticleEffect.h"

@interface ViewController ()

@property (strong, nonatomic) GLKBaseEffect *baseEffect; //GLkit里面的基础变量
@property (strong, nonatomic) ParticleEffect *particleEffect;
@property (assign, nonatomic) NSTimeInterval autoSpawnDelta;
@property (assign, nonatomic) NSTimeInterval lastSpawnTime;
@property (assign, nonatomic) NSInteger currentEmitterIndex;
@property (strong, nonatomic) NSArray *emitterBlocks;
@property (strong, nonatomic) GLKTextureInfo 
   *ballParticleTexture;
@property (strong, nonatomic) GLKTextureInfo 
   *burstParticleTexture;
@property (strong, nonatomic) GLKTextureInfo 
   *smokeParticleTexture;
@property (strong, nonatomic) GLKTextureInfo
   *magicPenTexture;
@end

@implementation ViewController

@synthesize baseEffect = baseEffect_;
@synthesize particleEffect = particleEffect_;
@synthesize autoSpawnDelta = autoSpawnDelta_;
@synthesize lastSpawnTime = lastSpawnTime_;
@synthesize currentEmitterIndex = currentEmitterIndex_;//当前发射器指数
@synthesize emitterBlocks = emitterBlocks_;//发射器模块
@synthesize magicPenTexture = magicPenTexture;//魔幻笔发射器
//
@synthesize ballParticleTexture = ballParticleTexture_;
@synthesize burstParticleTexture = burstParticleTexture_;
@synthesize smokeParticleTexture = smokeParticleTexture_;

#pragma mark - View lifecycle

//当视图控制器的视图被加载时调用在视图被要求绘制之前执行初始化
- (void)viewDidLoad
{
    //NSLog(@"viewDidLoad");
   [super viewDidLoad];
   
   //验证Interface Builder自动创建的视图类型
   GLKView *view = (GLKView *)self.view;
   NSAssert([view isKindOfClass:[GLKView class]],
      @"View controller's view is not a GLKView");
   
   // 使用高分辨率深度缓冲区
   view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
         
   // 创建上下文
   view.context = [[AGLKContext alloc] 
      initWithAPI:kEAGLRenderingAPIOpenGLES2];
   
   // 设置为当前上下文
   [EAGLContext setCurrentContext:view.context];
   
   // 创建并配置基本效果
   self.baseEffect = [[GLKBaseEffect alloc] init];

//    self.baseEffect.constantColor = GL_TRUE;
    
   // 配置灯
//   self.baseEffect.light0.enabled = GL_TRUE;
//   self.baseEffect.light0.ambientColor = GLKVector4Make(
//      0.9f, // Red
//      0.9f, // Green
//      0.9f, // Blue
//      1.0f);// Alpha
//   self.baseEffect.light0.diffuseColor = GLKVector4Make(
//      1.0f, // Red
//      1.0f, // Green
//      1.0f, // Blue
//      1.0f);// Alpha
   
   //导入魔幻笔素材纹理
    NSString *path = [[NSBundle bundleForClass:[self class]]
      pathForResource:@"5" ofType:@"jpg"];
   NSAssert(nil != path, @"magicPen texture image not found");
   NSError *error = nil;
   self.ballParticleTexture = [GLKTextureLoader 
      textureWithContentsOfFile:path 
      options:nil 
      error:&error];
    
   // 创建并配置粒子效果
   self.particleEffect = [[ParticleEffect alloc] init];
   self.particleEffect.texture2d0.name =
      self.ballParticleTexture.name;
   self.particleEffect.texture2d0.target =
      self.ballParticleTexture.target;

   //设置其他持久上下文状态
   [(AGLKContext *)view.context setClearColor:
    //背景颜色
    GLKVector4Make(0.0f, 0.0f, 0.0f, 1.0f)];
   [(AGLKContext *)view.context enable:GL_DEPTH_TEST];
   [(AGLKContext *)view.context enable:GL_BLEND];
   [(AGLKContext *)view.context 
      setBlendSourceFunction:GL_SRC_ALPHA 
      destinationFunction:GL_ONE_MINUS_SRC_ALPHA];
}


- (void)particleInit:(float)X Y:(float)Y
{
    // 设置自动粒子产生之间的秒数
    self.autoSpawnDelta = 0.0f;//持续发射
    
    //设置初始发射器方法
    self.currentEmitterIndex = 0;
    self.emitterBlocks = [NSArray arrayWithObjects:
                          [^{  // Pulse
        self.autoSpawnDelta = 0.5f;
        
        // 打开重力
        self.particleEffect.gravity = GLKVector3Make(
                                                     0.0f, 0.0f, -3.5f);
        int val = (arc4random() % 120) + 10;
        float randomXVelocity = -0.5f + 1.0f *
        (float)random() / (float)RAND_MAX;
        float randomYVelocity = -0.5f + 1.0f *
        (float)random() / (float)RAND_MAX;
        float randomZVelocity = -0.5f + 1.0f *
        (float)random() / (float)RAND_MAX;
        int valX = (arc4random() % 5) + 1;
        int valY = (arc4random() % 5) + 1;
        float ramX= valX/10.0;
        float ramY = valY/10.0;
        [self.particleEffect
         addParticleAtPosition:GLKVector3Make(X, Y,0.0f)
         velocity:GLKVector3Make(
                                 randomXVelocity,
                                 randomYVelocity,
                                 randomZVelocity)
  
         force:GLKVector3Make(ramX, ramY, 0.9f)
         size:val*1.0
         lifeSpanSeconds:0.8f
         fadeDurationSeconds:0.5f];
} copy],nil];
}
/////////////////////////////////////////////////////////////////
// 当视图控制器的视图被卸载时调用当知道视图控制器的视图不会被要求再次绘制时，执行清理。
- (void)viewDidUnload
{
   [super viewDidUnload];

   self.baseEffect = nil;
   self.particleEffect = nil;
}

// 配置self.baseEffect的投影和模型视图矩阵
- (void)preparePointOfViewWithAspectRatio:(GLfloat)aspectRatio
{
   // 配置baseEffect
   self.baseEffect.transform.projectionMatrix = 
      GLKMatrix4MakePerspective(
         GLKMathDegreesToRadians(85.0f),//标准视野
         aspectRatio,
         0.1f,   // 不要靠近太近
         20.0f); //

   // 将初始视角设置为合理的任意值
   self.baseEffect.transform.modelviewMatrix =
      GLKMatrix4MakeLookAt(
         0.0, 0.0, 1.0,   // 眼睛的位置
         0.0, 0.0, 0.0,   // 观察位置
         0.0, 1.0, 0.0);  // 向上的方向
   
}


//GLKView的委托方法：只要Cocoa Touch要求视图控制器的视图自行绘制，就由视图控制器的视图调用。（在这种情况下，渲染到与Core Animation Layer共享内存的帧缓冲区中）
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
   //计算场景的高宽比并设置透视投影
   const GLfloat  aspectRatio = 
      (GLfloat)view.drawableWidth / (GLfloat)view.drawableHeight;
   
   //清除背景帧缓冲区颜色（擦除上一张图）
   [(AGLKContext *)view.context clear:
      GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT];
   
   // 配置包括动画的视角
   [self preparePointOfViewWithAspectRatio:aspectRatio];
   

   
   // 画粒子
   self.particleEffect.transform.projectionMatrix = 
      self.baseEffect.transform.projectionMatrix;
   self.particleEffect.transform.modelviewMatrix = 
      self.baseEffect.transform.modelviewMatrix;
   [self.particleEffect prepareToDraw];
   [self.particleEffect draw];
   [self.baseEffect prepareToDraw];
   
   //可以在这里任何其他绘图
   
#ifdef DEBUG
   {  // Report any errors 
      GLenum error = glGetError();
      if(GL_NO_ERROR != error)
      {
         NSLog(@"GL Error: 0x%x", error);
      }
   }
#endif
}



//自动调用并允许所有标准设备方向
- (BOOL)shouldAutorotateToInterfaceOrientation:
   (UIInterfaceOrientation)interfaceOrientation
{
    // 对于支持的方向返回YES
    return (interfaceOrientation != 
       UIInterfaceOrientationPortraitUpsideDown);
}


//由用户界面对象调用的Action方法
- (IBAction)takeSelectedEmitterFrom:(UISegmentedControl *)sender;
{
   self.currentEmitterIndex = [sender selectedSegmentIndex];
}


//处理最开始的触摸
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    NSSet *allTouches = [event allTouches];    //返回与当前接收者有关的所有的触摸对象
    UITouch *touch = [allTouches anyObject];   //视图中的所有对象
    CGPoint point = [touch locationInView:[touch view]]; //返回触摸点在视图中的当前坐标
    float x = point.x;
    float y = point.y;
    // 坐标映射转换
    float X = ((x/320.0)*2 - 1);
    float Y = -((y/480.0)*2 - 1);
    
    [self particleInit:X Y:Y];
    
    NSTimeInterval timeElapsed = self.timeSinceLastResume;
    
    self.particleEffect.elapsedSeconds = timeElapsed;
    
    if(self.autoSpawnDelta < (timeElapsed - self.lastSpawnTime))
    {
        self.lastSpawnTime = timeElapsed;
        
        //调用一个块来发射粒子
        void(^emitterBlock)() = [self.emitterBlocks objectAtIndex:
                                 self.currentEmitterIndex];
        emitterBlock();
    }
    NSLog(@"touchesBegan ");
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSSet *allTouches = [event allTouches];    //返回与当前接收者有关的所有的触摸对象
    UITouch *touch = [allTouches anyObject];   //视图中的所有对象
    CGPoint point = [touch locationInView:[touch view]]; //返回触摸点在视图中的当前坐标
    float x = point.x;
    float y = point.y;
    //NSLog(@"touch moved (x, y) is (%d, %d)", x, y);
    float X = ((x/320.0)*2 - 1);
    float Y = -((y/480.0)*2 - 1);
    
     [self particleInit:X Y:Y];

    //UITouch* touch = [[event touchesForView:self] anyObject];
    NSTimeInterval timeElapsed = self.timeSinceLastResume;
    
    self.particleEffect.elapsedSeconds = timeElapsed;
    
    if(self.autoSpawnDelta < (timeElapsed - self.lastSpawnTime))
    {
        self.lastSpawnTime = timeElapsed;
        
        //调用一个块来发射粒子
        void(^emitterBlock)() = [self.emitterBlocks objectAtIndex:
                                 self.currentEmitterIndex];
        emitterBlock();
    }
    NSLog(@"touchesMoved:");
}

//处理触摸事件结束
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //CGRect                bounds = [self bounds];
    UITouch*            touch = [[event touchesForView:self] anyObject];
    NSLog(@"touchesEnded");
    //double time = basicTimer.GetTotal();
}
@end
//touch坐标 320 480
