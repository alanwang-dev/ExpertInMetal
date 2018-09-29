//
//  ViewController.m
//  ExpertInMetal
//
//  Created by 王可成 on 2018/9/29.
//  Copyright © 2018 王可成. All rights reserved.
//

#import "ViewController.h"
#import <MetalKit/MetalKit.h>
#import <Metal/Metal.h>
#import <ModelIO/ModelIO.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __cplusplus
}
#endif

static NSString *shaders = @""" \
#include <metal_stdlib> \n \
using namespace metal; \
\
struct VertexIn { \
    float4 position [[ attribute(0) ]]; \
}; \
\
vertex float4 vertex_main(const VertexIn vertex_in [[ stage_in ]]) { \
    return vertex_in.position; \
} \
\
fragment float4 fragment_main() { \
    return float4(1, 0, 0, 1); \
} \
""";

@interface ViewController ()<MTKViewDelegate>

@property (nonatomic) MTKView *displayView;
@property (nonatomic) id<MTLDevice> device;
@property (nonatomic) id<MTLCommandQueue> commandQueue;
@property (nonatomic) id<MTLLibrary> library;

@property (nonatomic) id<MTLFunction> vertexFunction;
@property (nonatomic) id<MTLFunction> fragmentFunction;

@property (nonatomic) id<MTLRenderPipelineState> pipelineState;

@property (nonatomic) MTKMesh *mesh;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _displayView = [[MTKView alloc] initWithFrame:self.view.bounds];
    _displayView.clearColor = MTLClearColorMake(1, 1, 1, 1);
    [self.view addSubview:_displayView];
    _displayView.delegate = self;
    _device = MTLCreateSystemDefaultDevice();
    _displayView.device = _device;
    _commandQueue = _device.newCommandQueue;
    
    [self loadShaderFunctions];
    
    [self loadMesh];
    
    [self createRenderPipelineState];
    
    [(MTKView *)self.displayView draw];
}

- (void)loadShaderFunctions {
    // shader functions
    _library = [_device newLibraryWithSource:shaders options:nil error:nil];
    _vertexFunction = [_library newFunctionWithName:@"vertex_main"];
    _fragmentFunction = [_library newFunctionWithName:@"fragment_main"];
}

- (void)loadMesh {
    id<MDLMeshBufferAllocator> allocator = [[MTKMeshBufferAllocator alloc] initWithDevice:_device];
    vector_float3   vec{ 0.75, 0.75, 0.75 };
    vector_uint2    vec2{ 100, 100 };

    MDLMesh *mesh = [[MDLMesh alloc] initSphereWithExtent:vec
                                                 segments:vec2
                                            inwardNormals:NO
                                             geometryType:MDLGeometryTypeTriangles allocator:allocator];
    
    _mesh = [[MTKMesh alloc] initWithMesh:mesh device:_device error:nil];
}

- (void)createRenderPipelineState {
    MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDescriptor.vertexFunction = _vertexFunction;
    pipelineDescriptor.fragmentFunction = _fragmentFunction;
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(_mesh.vertexDescriptor);
    
    NSError *error;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    if (error) {
        NSLog(@"%@", error);
        return;
    }
}



#pragma mark - MTKViewDelegage
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

- (void)drawInMTKView:(MTKView *)view {
    id<MTLCommandBuffer> command = [_commandQueue commandBuffer];
    [command setLabel:@"pass-through"];
    
    id<MTLRenderCommandEncoder> encoder = [command renderCommandEncoderWithDescriptor:view.currentRenderPassDescriptor];
    
    [encoder setRenderPipelineState:_pipelineState];
    [encoder setVertexBuffer:_mesh.vertexBuffers[0].buffer offset:0 atIndex:0];
    
    [encoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                        indexCount:_mesh.submeshes[0].indexCount
                         indexType:_mesh.submeshes[0].indexType
                       indexBuffer:_mesh.submeshes[0].indexBuffer.buffer
                 indexBufferOffset:0];
    
    [encoder endEncoding];
    [command presentDrawable:view.currentDrawable];
    [command commit];
}

@end
