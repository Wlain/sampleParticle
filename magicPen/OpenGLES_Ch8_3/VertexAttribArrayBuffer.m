//
//  AGLKVertexAttribArrayBuffer.m
//  
//

#import "VertexAttribArrayBuffer.h"

@interface VertexAttribArrayBuffer ()

@property (nonatomic, assign) GLsizeiptr bufferSizeBytes;

@property (nonatomic, assign) GLsizeiptr stride;

@end

@implementation VertexAttribArrayBuffer

@synthesize name;
@synthesize bufferSizeBytes;
@synthesize stride;


//此方法在当前OpenGL ES上下文中为调用此方法的线程创建一个顶点属性数组缓冲区
- (id)initWithAttribStride:(GLsizeiptr)aStride
   numberOfVertices:(GLsizei)count
   bytes:(const GLvoid *)dataPtr
   usage:(GLenum)usage;
{
   NSParameterAssert(0 < aStride);
   NSAssert((0 < count && NULL != dataPtr) ||
      (0 == count && NULL == dataPtr),
      @"data must not be NULL or count > 0");
      
   if(nil != (self = [super init]))
   {
      stride = aStride;
      bufferSizeBytes = stride * count;
      glGenBuffers(1,                // STEP 1
         &name);
      glBindBuffer(GL_ARRAY_BUFFER,  // STEP 2
         self.name); 
      glBufferData(                  // STEP 3
         GL_ARRAY_BUFFER,  //初始化缓冲区内容
         bufferSizeBytes,  // 要复制的字节数
         dataPtr,          // 要复制的字节地址
         usage);           //  在GPU内存中缓存
         
      NSAssert(0 != name, @"Failed to generate name");
   }
   
   return self;
}   


// 该方法加载接收器存储的数据。
- (void)reinitWithAttribStride:(GLsizeiptr)aStride
   numberOfVertices:(GLsizei)count
   bytes:(const GLvoid *)dataPtr;
{
   NSParameterAssert(0 < aStride);
   NSParameterAssert(0 < count);
   NSParameterAssert(NULL != dataPtr);
   NSAssert(0 != name, @"Invalid name");

   self.stride = aStride;
   self.bufferSizeBytes = aStride * count;
   
   glBindBuffer(GL_ARRAY_BUFFER,  // STEP 2
      self.name); 
   glBufferData(                  // STEP 3
      GL_ARRAY_BUFFER,  // 始化缓冲区内容
      bufferSizeBytes,  // 要复制的字节数
      dataPtr,          //要复制的字节地址
      GL_DYNAMIC_DRAW); 
}


//当应用程序想要使用缓冲区来渲染任何几何图形时，必须准备一个顶点属性数组缓冲区。应用程序准备一个缓冲区时，一些OpenGL ES状态会被更改为允许绑定缓冲区并配置指针
- (void)prepareToDrawWithAttrib:(GLuint)index
   numberOfCoordinates:(GLint)count
   attribOffset:(GLsizeiptr)offset
   shouldEnable:(BOOL)shouldEnable
{
   NSParameterAssert((0 < count) && (count < 4));
   NSParameterAssert(offset < self.stride);
   NSAssert(0 != name, @"Invalid name");

   glBindBuffer(GL_ARRAY_BUFFER,     // STEP 2
      self.name);

   if(shouldEnable)
   {
      glEnableVertexAttribArray(     // Step 4
         index); 
   }

   glVertexAttribPointer(            // Step 5
      index,               // 标识要使用的属性
      count,               // 属性的坐标数
      GL_FLOAT,
      GL_FALSE,
      self.stride,         //每个顶点存储的总数字节数
      NULL + offset);      //从每个顶点的起点偏移到属性的第一个坐标
    
#ifdef DEBUG
   {  // 报告任何错误
      GLenum error = glGetError();
      if(GL_NO_ERROR != error)
      {
         NSLog(@"GL Error: 0x%x", error);
      }
   }
#endif
}



//提交由模式标识的绘图命令，并指示OpenGL ES首先使用从索引顶点开始的缓冲区中的计数顶点。顶点索引从0开始
- (void)drawArrayWithMode:(GLenum)mode
   startVertexIndex:(GLint)first
   numberOfVertices:(GLsizei)count
{
   NSAssert(self.bufferSizeBytes >= 
      ((first + count) * self.stride),
      @"Attempt to draw more vertex data than available.");
      
   glDrawArrays(mode, first, count); // Step 6
}


// 提交由模式标识的绘图命令，并指示OpenGL ES使用预先准备好的缓冲区中的计数顶点，这些顶点从准备缓冲区中第一个索引处的顶点开始
+ (void)drawPreparedArraysWithMode:(GLenum)mode
   startVertexIndex:(GLint)first
   numberOfVertices:(GLsizei)count;
{
   glDrawArrays(mode, first, count); // Step 6
}



//当接收器被解除分配时，这个方法从当前上下文中删除接收者的缓冲区
- (void)dealloc
{
    // Delete buffer from current context
    if (0 != name)
    {
        glDeleteBuffers (1, &name); // Step 7 
        name = 0;
    }
}

@end
