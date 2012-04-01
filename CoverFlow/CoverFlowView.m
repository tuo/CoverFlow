//
//  Created by tuo on 4/1/12.
//
// to change "templates" to "placeholder"
//

#import "CoverFlowView.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>

@interface CoverFlowView ()

//setup templates
-(void)setupTemplateLayers;
//setup images
-(void)setupImages;
//remove sublayers (after a certain delay)
-(void)removeLayersAfterSeconds:(id)layerToBeRemoved;
//remove all sublayers
-(void)removeSublayers;
//empty imagelayers
-(void)cleanImageLayers;
//add reflections
-(void)showImageAndReflection:(CALayer *)layer;
//adjust the bounds
-(void)scaleBounds: (CALayer *) layer x:(CGFloat)scaleWidth y:(CGFloat)scaleHeight;
//add uipagecontrol
-(void)addPageControl;

@end


@implementation CoverFlowView {
@private

    NSMutableArray *_images;
    NSMutableArray *_imageLayers;
    NSMutableArray *_templateLayers;
    int _currentRenderingImageIndex;
    UIPageControl *_pageControl;
    int _sideVisibleImageCount;
    CGFloat _sideVisibleImageScale;
    CGFloat _middleImageScale;
}


@synthesize images = _images;
@synthesize imageLayers = _imageLayers;
@synthesize templateLayers = _templateLayers;
@synthesize currentRenderingImageIndex = _currentRenderingImageIndex;
@synthesize pageControl = _pageControl;
@synthesize sideVisibleImageCount = _sideVisibleImageCount;
@synthesize sideVisibleImageScale = _sideVisibleImageScale;
@synthesize middleImageScale = _middleImageScale;


+ (id)coverFlowViewWithFrame:(CGRect)frame andImages:(NSMutableArray *)rawImages sideImageCount:(int)sideCount sideImageScale:(CGFloat)sideImageScale middleImageScale:(CGFloat)middleImageScale {
    CoverFlowView *flowView = [[CoverFlowView alloc] initWithFrame:frame];

    flowView.sideVisibleImageCount = sideCount;
    flowView.sideVisibleImageScale = sideImageScale;
    flowView.middleImageScale = middleImageScale;

    //default set middle image to the first image in the source images array
    flowView.currentRenderingImageIndex = 6;

    flowView.images = [NSMutableArray arrayWithArray:rawImages];
    flowView.imageLayers = [[NSMutableArray alloc] initWithCapacity:flowView.sideVisibleImageCount* 2 + 1];
    flowView.templateLayers = [[NSMutableArray alloc] initWithCapacity:(flowView.sideVisibleImageCount + 1)* 2 + 1];

    //register the pan gesture to figure out whether user has intention to move to next/previous image
    UIPanGestureRecognizer *gestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:flowView action:@selector(moveOneStepAction:)];
    [flowView addGestureRecognizer:gestureRecognizer];

    //now almost setup
    [flowView setupTemplateLayers];

    [flowView setupImages];

    [flowView addPageControl];

    return flowView;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        //set up perspective
        CATransform3D transformPerspective = CATransform3DIdentity;
                        transformPerspective.m34 = -1.0 / 500.0;
                        self.layer.sublayerTransform = transformPerspective;
    }

    return self;
}

-(void)setupTemplateLayers {
    CGFloat centerX = self.bounds.size.width/2;
    CGFloat centerY = self.bounds.size.height/2;

    //the angle to rotate
    CGFloat leftRadian = M_PI/3;
    CGFloat rightRadian = -M_PI/3;

    //gap between images in side
    CGFloat gapAmongSideImages = 30.0f;

    //gap between middle one and neigbour(this word is so hard to type wrong: WTF)
    CGFloat gapBetweenMiddleAndSide = 100.0f;

    //setup the layer templates
    //let's start from left side
    for(int i = 0; i <= self.sideVisibleImageCount; i++){
       CALayer *layer = [CALayer layer];
       layer.position = CGPointMake(centerX - gapBetweenMiddleAndSide - gapAmongSideImages * (self.sideVisibleImageCount - i), centerY);
       layer.zPosition = (i - self.sideVisibleImageCount - 1) * 10;
       layer.transform = CATransform3DMakeRotation(leftRadian, 0, 1, 0);
       [self.templateLayers addObject:layer];
    }

    //middle

    CALayer *layer = [CALayer layer];
    layer.position = CGPointMake(centerX, centerY);
    [self.templateLayers addObject:layer];
    //right
    for(int i = 0; i <= self.sideVisibleImageCount; i++){
        CALayer *layer = [CALayer layer];
        layer.position = CGPointMake(centerX + gapBetweenMiddleAndSide + gapAmongSideImages * i, centerY);
        layer.zPosition = (i + 1) * -10;
        layer.transform = CATransform3DMakeRotation(rightRadian, 0, 1, 0);
        [self.templateLayers addObject:layer];
    }
}

- (void)setupImages {
    // setup the visible area, and start index and end index
    int startingImageIndex = (self.currentRenderingImageIndex - self.sideVisibleImageCount <= 0) ? 0 : self.currentRenderingImageIndex - self.sideVisibleImageCount;
    int endImageIndex = (self.currentRenderingImageIndex + self.sideVisibleImageCount < self.images.count )  ? (self.currentRenderingImageIndex + self.sideVisibleImageCount) : (self.images.count -1 );

    //step2: set up images that ready for rendering
    for (int i = startingImageIndex; i <= endImageIndex; i++) {
       UIImage *image = [self.images objectAtIndex:i];
       CALayer *imageLayer = [CALayer layer];
       imageLayer.contents = (__bridge id)image.CGImage;
       CGFloat scale = (i == self.currentRenderingImageIndex) ? self.middleImageScale : self.sideVisibleImageScale;
       imageLayer.bounds = CGRectMake(0, 0, image.size.width * scale, image.size.height*scale);
       [self.imageLayers addObject:imageLayer];
    }

    //step3 : according to templates, set its geometry info to corresponding image layer
    //1 means the extra layer in templates layer
    //damn mathmatics
    int indexOffsetFromImageLayersToTemplates = (self.currentRenderingImageIndex - self.sideVisibleImageCount < 0) ? (self.sideVisibleImageCount + 1 - self.currentRenderingImageIndex) : 1;
    for (int i = 0; i < self.imageLayers.count; i++) {
        CALayer *correspondingTemplateLayer = [self.templateLayers objectAtIndex:(i + indexOffsetFromImageLayersToTemplates)];
        CALayer *imageLayer = [self.imageLayers objectAtIndex:i];
        imageLayer.position = correspondingTemplateLayer.position;
        imageLayer.zPosition = correspondingTemplateLayer.zPosition;
        imageLayer.transform = correspondingTemplateLayer.transform;
        //show its reflections
        [self showImageAndReflection:imageLayer];
    }

}

// 添加layer及其“倒影”
- (void)showImageAndReflection:(CALayer*)layer
{
    // 制作reflection
    CALayer *reflectLayer = [CALayer layer];
    reflectLayer.contents = layer.contents;
    reflectLayer.bounds = layer.bounds;
    reflectLayer.position = CGPointMake(layer.bounds.size.width/2, layer.bounds.size.height*1.5);
    reflectLayer.transform = CATransform3DMakeRotation(M_PI, 1, 0, 0);

    // 给该reflection加个半透明的layer
    CALayer *blackLayer = [CALayer layer];
    blackLayer.backgroundColor = [UIColor blackColor].CGColor;
    blackLayer.bounds = reflectLayer.bounds;
    blackLayer.position = CGPointMake(blackLayer.bounds.size.width/2, blackLayer.bounds.size.height/2);
    blackLayer.opacity = 0.6;
    [reflectLayer addSublayer:blackLayer];

    // 给该reflection加个mask
    CAGradientLayer *mask = [CAGradientLayer layer];
    mask.bounds = reflectLayer.bounds;
    mask.position = CGPointMake(mask.bounds.size.width/2, mask.bounds.size.height/2);
    mask.colors = [NSArray arrayWithObjects:
                   (__bridge id)[UIColor clearColor].CGColor,
                   (__bridge id)[UIColor whiteColor].CGColor, nil];
    mask.startPoint = CGPointMake(0.5, 0.35);
    mask.endPoint = CGPointMake(0.5, 1.0);
    reflectLayer.mask = mask;

    // 作为layer的sublayer
    [layer addSublayer:reflectLayer];
    // 加入UICoverFlowView的sublayers
    [self.layer addSublayer:layer];
}

- (void)addPageControl {


}


- (int)getIndexForMiddle {

    return 0;
}



@end