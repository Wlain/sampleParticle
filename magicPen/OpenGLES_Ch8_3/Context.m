//
//  GLKContext.m
//  
//

#import "Context.h"

@implementation AGLKContext


//此方法设置背景颜色，在调用此方法之前，清除颜色是未定义的
- (void)setClearColor:(GLKVector4)clearColorRGBA
{
   clearColor = clearColorRGBA;
   
   NSAssert(self == [[self class] currentContext],
      @"Receiving context required to be current context");
      
   glClearColor(
      clearColorRGBA.r, 
      clearColorRGBA.g, 
      clearColorRGBA.b, 
      clearColorRGBA.a);
}



//通过-setClearColor：返回背景颜色
//如果没有通过-setClearColor设置清晰的颜色
//返回清除颜色未定义
- (GLKVector4)clearColor
{
   return clearColor;
}

//此方法指示OpenGL ES将每个渲染缓冲区类型中由掩码标识的当前上下文的渲染缓冲区中的所有数据设置为通过-setClearColor指定的颜色（值）和/或OpenGL ES函数。
- (void)clear:(GLbitfield)mask
{
   NSAssert(self == [[self class] currentContext],
      @"Receiving context required to be current context");
      
   glClear(mask);
}



- (void)enable:(GLenum)capability;
{
   NSAssert(self == [[self class] currentContext],
      @"Receiving context required to be current context");
   
   glEnable(capability);
}



- (void)disable:(GLenum)capability;
{
   NSAssert(self == [[self class] currentContext],
      @"Receiving context required to be current context");
   glDisable(capability);
}


//设置混合模式
- (void)setBlendSourceFunction:(GLenum)sfactor 
   destinationFunction:(GLenum)dfactor;
{
   glBlendFunc(sfactor, dfactor);
}
  
@end
