//
//  EasySignatureView.m
//  EsayHandwritingSignature
//
//  Created by Liangk on 2017/11/9.
//  Copyright © 2017年 liang. All rights reserved.
//

#import "EasySignatureView.h"
#import <QuartzCore/QuartzCore.h>

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

typedef NS_ENUM(NSInteger,UISignEvent){
    UISignEventTouchUp   = 1,
    UISignEventTouchDrag = 2,
    UISignEventTouchDown = 3,
};

@interface EasySignatureView ()<CAAnimationDelegate>
{
    UIBezierPath *path;     //路径
    CGPoint previousPoint;  //中点
    BOOL isHaveDraw;        //是否画线
    int indexFlag;          //停顿位 标识
    int trackTime;          //停顿时间
    NSInteger playTime;     //重放 帧数
    NSInteger totalCount;   //速度控制
}
@property (nonatomic,strong) NSMutableArray * trackArr;

@end

@implementation EasySignatureView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.trackArr = [NSMutableArray arrayWithCapacity:0];

        path = [UIBezierPath bezierPath];
        [path setLineWidth:2];
        // Capture touches
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        pan.maximumNumberOfTouches = pan.minimumNumberOfTouches =1;
        [self addGestureRecognizer:pan];
        
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    
    isHaveDraw    = NO;
    indexFlag     = 0;
    trackTime     = 0;
    totalCount    = 0;
    playTime      = 0;
    
    previousPoint = CGPointMake(0, 0);
    
    [self.layer removeAllAnimations];//清空动画

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
    
    //    CGFloat viewHeight   = self.frame.size.height;
    //    CGFloat currentY     = currentPoint.y;//触点Y
    
    if (pan.state ==UIGestureRecognizerStateBegan)
    {
        [path moveToPoint:currentPoint];
        if (trackTime!=0) {
            [self.trackSecond setFireDate:[NSDate distantFuture]];
            trackTime = 0;
        }
    }
    else if (pan.state ==UIGestureRecognizerStateChanged)
        [path addQuadCurveToPoint:midPoint controlPoint:previousPoint];
    else if (pan.state == UIGestureRecognizerStateEnded)
        [self.trackSecond setFireDate:[NSDate date]];
    
    
    
    
    
    /*if(0 <= currentY && currentY <= viewHeight)
     {//确定截图大小,判断是否draw
     if(max == 0&&min == 0)
     {
     max = currentPoint.x;
     min = currentPoint.x;
     }
     else
     {
     if(max <= currentPoint.x)
     {
     max = currentPoint.x;
     }
     if(min>=currentPoint.x)
     {
     min = currentPoint.x;
     }
     }
     
     }*/
    
    previousPoint = currentPoint;
    
    [self setNeedsDisplay];
    
    [self.totalArr addObject:(__bridge UIImage*)[[self cutImage] CGImage]];
    
    
    if (self.delegate != nil &&[self.delegate respondsToSelector:@selector(onSignatureWriteAction)]) {
        [self.delegate onSignatureWriteAction];
    }
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
    //暂停定时
    self.disPlay.paused = YES;
    [self.trackSecond setFireDate:[NSDate distantFuture]];
    [self.totalArr removeAllObjects];   //清空帧图
    [self.trackArr removeAllObjects];   //清空等待
    [self commonInit];
    
    [path removeAllPoints];    //清空路径
    [self setNeedsDisplay];
    
    self.userInteractionEnabled = YES;
}



- (void)sure:(UIButton*)sender{
    
    sender.userInteractionEnabled = NO;//重写 .防止扰乱动画
    self.userInteractionEnabled   = NO;
    sender.tag                    = 111;
    
    [self.trackSecond setFireDate:[NSDate distantFuture]];
    
    self.disPlay.paused = NO;
}

-(void)secondAdd{
    
    totalCount ++;
    if (totalCount%2 ==0) {
        
        if (playTime < [self.trackArr.lastObject integerValue] ){
            
            if (indexFlag<= self.trackArr.count)  {//数组还有比对的意义
                
                if (playTime == [[self.trackArr objectAtIndex:indexFlag]integerValue]) {
                    
                    indexFlag ++;
                    self.disPlay.paused = YES;
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        self.disPlay.paused = NO;
                    });
                    
                    return;
                }
            }
            playTime ++;
        }
        
        if (playTime == self.totalArr.count ) {
            self.disPlay.paused           = YES;
            UIButton * tmpBtn             = [[UIApplication sharedApplication].keyWindow viewWithTag:111];
            tmpBtn.userInteractionEnabled = YES;
            
            [self commonInit];
            return;
        }
        
        self.layer.contents = [self.totalArr objectAtIndex:playTime];
    }
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

#pragma mark - -- 没有使用的方法 ---


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
