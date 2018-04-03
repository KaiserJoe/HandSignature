//
//  EasySignatureView.m
//  EsayHandwritingSignature
//
//  Created by Liangk on 2017/11/9.
//  Copyright © 2017年 liang. All rights reserved.
//

#import "EasySignatureView.h"
#import <QuartzCore/QuartzCore.h>
#import "SignatureModel.h"


#define StrWidth 210
#define StrHeight 20

/**
 *  @author Kaiser
 *
 *  计算中间点
 */
static CGPoint midpoint(CGPoint p0,CGPoint p1) {
    return (CGPoint) {
        (p0.x + p1.x) /2.0,
        (p0.y + p1.y) /2.0
    };
}

typedef NS_ENUM(int,UISignEvent){
    UISignEventTouchUp   = 1,
    UISignEventTouchDrag = 2,
    UISignEventTouchDown = 3,
};

@interface EasySignatureView ()<CAAnimationDelegate>
{
    UIBezierPath *path;     //路径
    CGPoint previousPoint;  //中点
    BOOL isHaveDraw;        //是否画线
    NSInteger playTime;     //重放 帧数
    NSInteger totalCount;   //速度控制
    long tempTime;
    
}
@property (nonatomic,strong) NSMutableArray <SignatureModel*> * trackArr;
@property (nonatomic,strong) CADisplayLink  * disPlay;
@property (nonatomic,strong) CAShapeLayer   * disPlayLayer;

@end

@implementation EasySignatureView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.clipsToBounds = YES;
        //记录点数组
        self.trackArr      = [NSMutableArray arrayWithCapacity:0];

        //屏幕刷新
        self.disPlay        = [CADisplayLink displayLinkWithTarget:self selector:@selector(secondAdd)];
        self.disPlay.paused = YES;
        [self.disPlay addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];

        //播放Layer
        self.disPlayLayer             = [CAShapeLayer new];
        self.disPlayLayer.frame       = self.bounds;
        self.disPlayLayer.lineCap     = kCALineCapButt;
        self.disPlayLayer.fillColor   = nil;
        self.disPlayLayer.strokeColor = [UIColor blackColor].CGColor;
        self.disPlayLayer.lineWidth   = 2;
        [self.layer addSublayer:self.disPlayLayer];
        

        //路径
        path = [UIBezierPath bezierPath];
        [path setLineWidth:2];
        
        //画笔
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        pan.maximumNumberOfTouches = pan.minimumNumberOfTouches =1;
        [self addGestureRecognizer:pan];
        
        [self commonInit];
    }
    return self;
}

/**
 *  @author Kaiser
 *
 *  初始化数据
 */
- (void)commonInit {
    totalCount    = 0;
    playTime      = 0;
    tempTime      = 0;
    previousPoint = CGPointMake(0, 0);
}

/**
 *  @author Kaiser
 *
 *  书写痕迹
 */
- (void)pan:(UIPanGestureRecognizer *)pan
{
    isHaveDraw           = YES;
    CGPoint currentPoint = [pan locationInView:self];
    CGPoint midPoint     = midpoint(previousPoint, currentPoint);
    
    
    if (pan.state ==UIGestureRecognizerStateBegan)
    {
        [path moveToPoint:currentPoint];
        
        NSTimeInterval timeInterval = [[NSDate date]timeIntervalSince1970] * 1000;
        [self touchRecordWithPointX:currentPoint.x PointY:currentPoint.y TouchFlag:UISignEventTouchDown systemTime:timeInterval];
    }
    else if (pan.state ==UIGestureRecognizerStateChanged)
    {
        [path addQuadCurveToPoint:midPoint controlPoint:previousPoint];
        
        [self touchRecordWithPointX:currentPoint.x PointY:currentPoint.y TouchFlag:UISignEventTouchDrag systemTime:0];
    }
    else if (pan.state == UIGestureRecognizerStateEnded)
    {
        NSTimeInterval timeInterval = [[NSDate date]timeIntervalSince1970] * 1000;
        [self touchRecordWithPointX:currentPoint.x PointY:currentPoint.y TouchFlag:UISignEventTouchUp systemTime:timeInterval];
    }
    
    previousPoint = currentPoint;
    [self setNeedsDisplay];
    
    
    if (self.delegate != nil &&[self.delegate respondsToSelector:@selector(onSignatureWriteAction)]) {
        [self.delegate onSignatureWriteAction];
    }
}

/**
 *  @author Kaiser
 *
 *  记录点的位置,状态
 */
-(void)touchRecordWithPointX:(float)pointX PointY:(float)pointY TouchFlag:(int)status systemTime:(long)time
{
    NSDictionary * tempDic      = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithFloat:pointX],@"pointX",
                                   [NSNumber numberWithFloat:pointY],@"pointY",
                                   [NSNumber numberWithInt:status],@"pointFlag",
                                   [NSNumber numberWithLong:time],@"systemTime",nil];
    
    SignatureModel * signModel  = [[SignatureModel alloc]initWithDictionary:tempDic];
    
    [self.trackArr addObject:signModel];
}

- (void)drawRect:(CGRect)rect
{
    [path stroke];
    
    if(!isHaveDraw)
    {//No
        NSString *str = @"此处手写签名: 正楷, 工整书写";
        CGRect rect1  = CGRectMake((rect.size.width -StrWidth)/2, (rect.size.height -StrHeight)/3-5,StrWidth, StrHeight);
        [str drawInRect:rect1 withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15],NSForegroundColorAttributeName:RGB(199, 199, 199)}];
    }
}



- (void)clear
{
    [self.trackArr removeAllObjects];   //清空等待
    [self commonInit];

    [path removeAllPoints];    //清空路径
    [self setNeedsDisplay];

    self.disPlayLayer.path      = path.CGPath;
    self.userInteractionEnabled = YES;
    isHaveDraw                  = NO;
}


-(void)secondAdd{

    totalCount ++;
    if (totalCount%1 ==0) {
        
        if (playTime < self.trackArr.count ){
            
            SignatureModel * obj = [self.trackArr objectAtIndex:playTime];
            
            switch ([obj.pointFlag intValue]) {
                case UISignEventTouchUp:
                {
                    tempTime = [obj.systemTime longValue];
                }
                    break;
                case UISignEventTouchDrag:
                {
                    [path addQuadCurveToPoint:CGPointMake([obj.pointX floatValue], [obj.pointY floatValue]) controlPoint:previousPoint];
                    
                }
                    break;
                case UISignEventTouchDown:
                {
                    if (tempTime!=0){
                        //如果存在间隙
                        long currentTime    = [obj.systemTime longValue];
                        long timeGap        = (currentTime - tempTime);
                        self.disPlay.paused = YES;

                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeGap * USEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            self.disPlay.paused = NO;
                        });
                        [path moveToPoint:CGPointMake([obj.pointX floatValue], [obj.pointY floatValue])];
                        
                    }else {
                        //如果不存在间隙
                        [path moveToPoint:CGPointMake([obj.pointX floatValue], [obj.pointY floatValue])];
                    }
                }
                    break;
            }
            previousPoint = CGPointMake([obj.pointX floatValue], [obj.pointY floatValue]);
        }
        playTime ++;
    }
    
    if (playTime == self.trackArr.count ) {
        self.disPlay.paused           = YES;
        UIButton * tmpBtn             = [[UIApplication sharedApplication].keyWindow viewWithTag:111];
        tmpBtn.userInteractionEnabled = YES;
        
        [self commonInit];
        return;
    }
    
    self.disPlayLayer.path = path.CGPath;
}

/**
 *  @author Kaiser
 *
 *  重现的方法
 */
- (void)sure:(UIButton*)sender{
    
    sender.userInteractionEnabled = NO;//重写禁止 .防止扰乱动画
    self.userInteractionEnabled   = NO;//画布静止
    sender.tag                    = 111;
    
    [path removeAllPoints];
    [self setNeedsDisplay];

    self.disPlay.paused = NO;
}

#pragma mark - -- MakeImage ---


-(UIImage *) imageRepresentation {
    
    UIGraphicsBeginImageContextWithOptions(self.bounds.size,NO, [UIScreen mainScreen].scale);
    
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *image =UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();

    //        image = [self imageBlackToTransparent:image];
    
    //    NSLog(@"width:%f,height:%f",image.size.width,image.size.height);
    
    //    UIImage *img = [self cutImage:image];
    
    //    self.SignatureImg = image;//[self scaleToSize:img];
    
    return image;
}



#pragma mark - -- 没有使用的方法 ---

//只截取签名部分图片
- (UIImage *)cutImage
{
    //    UIGraphicsBeginImageContext(self.bounds.size);
    UIGraphicsBeginImageContextWithOptions(self.bounds.size,NO, [UIScreen mainScreen].scale);
    
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *image =UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return image;
}

-(void)pauseLayer:(CALayer*)layer {
    CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
    layer.speed               = 0.0;
    layer.timeOffset          = pausedTime;
}

-(void)resumeLayer:(CALayer*)layer {
    
    CFTimeInterval pausedTime     = [layer timeOffset];
    layer.speed                   = 1.0;
    layer.timeOffset              = 0.0;
    layer.beginTime               = 0.0;
    CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    layer.beginTime               = timeSincePause;
}


-(void)removeAllSubLeyer
{
    NSArray<CALayer *> *tempArr =[self.layer sublayers];
    NSArray<CALayer *> *tempArr2 = [tempArr filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [evaluatedObject isKindOfClass:[CALayer class]];
    }]];
    
    [tempArr2 enumerateObjectsUsingBlock:^(CALayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperlayer];
    }];
}






- (UIImage*) imageBlackToTransparent:(UIImage*) image
{
    // 分配内存
    const int imageWidth    = image.size.width;
    const int imageHeight   = image.size.height;
    size_t      bytesPerRow = imageWidth * 4;
    uint32_t* rgbImageBuf   = (uint32_t*)malloc(bytesPerRow * imageHeight);
    
    // 创建context
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context       = CGBitmapContextCreate(rgbImageBuf, imageWidth, imageHeight, 8, bytesPerRow, colorSpace,
                                                       kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    
    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), image.CGImage);
    
    // 遍历像素
    int pixelNum      = imageWidth * imageHeight;
    uint32_t* pCurPtr = rgbImageBuf;
    
    for (int i =0; i < pixelNum; i++, pCurPtr++)
    {
        //        if ((*pCurPtr & 0xFFFFFF00) == 0)    //将黑色变成透明
        if (*pCurPtr == 0xffffff)
        {
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[0] =0;
        }
        
        //改成下面的代码，会将图片转成灰度
        /*uint8_t* ptr = (uint8_t*)pCurPtr;
         // gray = red * 0.11 + green * 0.59 + blue * 0.30
         uint8_t gray = ptr[3] * 0.11 + ptr[2] * 0.59 + ptr[1] * 0.30;
         ptr[3] = gray;
         ptr[2] = gray;
         ptr[1] = gray;*/
    }
    
    // 将内存转成image
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rgbImageBuf, bytesPerRow * imageHeight,/*ProviderReleaseData**/NULL);
    CGImageRef imageRef            = CGImageCreate(imageWidth, imageHeight, 8,32, bytesPerRow, colorSpace,
                                                   kCGImageAlphaLast | kCGBitmapByteOrder32Little, dataProvider,
                                                   NULL, true,kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    
    UIImage* resultUIImage = [UIImage imageWithCGImage:imageRef];
    
    // 释放
    CGImageRelease(imageRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    return resultUIImage;
}

/**
 *  @author Kaiser
 *
 *  压缩图片
 */
- (UIImage *)scaleToSize:(UIImage *)img {
    CGRect rect ;
    CGFloat imageWidth = img.size.width;
    //判断图片宽度
    if(imageWidth >= 128)
    {
        rect =CGRectMake(0,0, 128, self.frame.size.height);
    }
    else
    {
        rect =CGRectMake(0,0, img.size.width,self.frame.size.height);
        
    }
    CGSize size = rect.size;
    UIGraphicsBeginImageContext(size);
    [img drawInRect:rect];
    UIImage* scaledImage =UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self setNeedsDisplay];
    return scaledImage;
}



//签名完成，给签名照添加新的水印
- (UIImage *) addText:(UIImage *)img text:(NSString *)mark {
    int w = img.size.width;
    int h = img.size.height;
    
    //根据截取图片大小改变文字大小
    CGFloat size = 20;
    UIFont *textFont = [UIFont systemFontOfSize:size];
    CGSize sizeOfTxt = [mark sizeWithFont:textFont constrainedToSize:CGSizeMake(128,30)];
    
    if(w<sizeOfTxt.width)
    {
        
        while (sizeOfTxt.width>w) {
            size --;
            textFont = [UIFont systemFontOfSize:size];
            
            sizeOfTxt = [mark sizeWithFont:textFont constrainedToSize:CGSizeMake(128,30)];
        }
        
    }
    else
    {
        
        size =45;
        textFont = [UIFont systemFontOfSize:size];
        sizeOfTxt = [mark sizeWithFont:textFont constrainedToSize:CGSizeMake(self.frame.size.width,30)];
        while (sizeOfTxt.width>w) {
            size ++;
            textFont = [UIFont systemFontOfSize:size];
            sizeOfTxt = [mark sizeWithFont:textFont constrainedToSize:CGSizeMake(self.frame.size.width,30)];
        }
        
    }
    UIGraphicsBeginImageContext(img.size);
    [[UIColor redColor] set];
    [img drawInRect:CGRectMake(0,0, w, h)];
    [mark drawInRect:CGRectMake((w-sizeOfTxt.width)/2,(h-sizeOfTxt.height)/2, sizeOfTxt.width, sizeOfTxt.height)withFont:textFont];
    UIImage *aimg =UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return aimg;
}


@end
