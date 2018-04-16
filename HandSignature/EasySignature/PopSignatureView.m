//
//  PopSignatureView.m
//  EsayHandwritingSignature
//
//  Created by Liangk on 2017/11/9.
//  Copyright © 2017年 liang. All rights reserved.
//

#import "PopSignatureView.h"
#import "EasySignatureView.h"
#import "NetWorkBlock.h"
#import "MJExtension.h"

@interface PopSignatureView () <SignatureViewDelegate> {
    UIView* _mainView;
    UIButton* _maskView;
    EasySignatureView *signatureView;
}

@property (nonatomic,strong) UIView *backGroundView;
@property (nonatomic,strong) UIButton *OKBtn;
@property (nonatomic,strong) UIButton *cancelBtn;
@property (nonatomic,strong) UIButton *btn3;
@end

@implementation PopSignatureView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        self.frame                  = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        self.backgroundColor        = WINDOW_COLOR;
        self.userInteractionEnabled = YES;
        [self setupView];
        
    }
    return self;
}


- (void)setupView
{
    //黑色蒙板背景
    _maskView = [UIButton buttonWithType:UIButtonTypeCustom];
    _maskView.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight);
    _maskView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
    _maskView.userInteractionEnabled = YES;
    [_maskView addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_maskView];
    
    //背景
    self.backGroundView                        = [[UIView alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height,
                                                                                   [UIScreen mainScreen].bounds.size.width, 0)];
    self.backGroundView.backgroundColor        = [UIColor whiteColor];
    self.backGroundView.userInteractionEnabled = YES;
    [_maskView addSubview:self.backGroundView];
    
    //标题
    UIButton * centerBtn      = [[UIButton alloc] initWithFrame:CGRectMake((ScreenWidth/2)-50, 0, 100, 44)];
    centerBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [centerBtn setTitle:@"DownloadCloud" forState:UIControlStateNormal];
    [centerBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [centerBtn addTarget:self action:@selector(signatureGetData) forControlEvents:UIControlEventTouchUpInside];
    [self.backGroundView addSubview:centerBtn];
    
    
    UIView *sepView1         = [[UIView alloc] initWithFrame:CGRectMake(0, 45, ScreenWidth, 1)];
    sepView1.backgroundColor = RGB(238, 238, 238);
    [self.backGroundView addSubview:sepView1];
//手写View
    signatureView                 = [[EasySignatureView alloc] initWithFrame:CGRectMake(0,46, ScreenWidth, SignatureViewHeight - 44 - 44)];
    signatureView.backgroundColor = [UIColor whiteColor];
    signatureView.delegate        = self;
    signatureView.showMessage     = @"";
    [self.backGroundView addSubview:signatureView];
    
    self.OKBtn     = [[UIButton alloc] initWithFrame:CGRectMake(ScreenWidth - 50, 0, 44, 44)];
    self.OKBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.OKBtn setTitle:@"Clean" forState:UIControlStateNormal];
    [self.OKBtn setTitleColor:ACTIONSHEET_BACKGROUNDCOLOR forState:UIControlStateNormal];
    [self.OKBtn addTarget:self action:@selector(onClear) forControlEvents:UIControlEventTouchUpInside];
    [self.backGroundView addSubview:self.OKBtn];

    self.cancelBtn                 = [[UIButton alloc] initWithFrame:CGRectMake(6, 0, 55, 44)];
    self.cancelBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.cancelBtn setTitle:@"Replay" forState:UIControlStateNormal];
    [self.cancelBtn setTitleColor:ACTIONSHEET_BACKGROUNDCOLOR forState:UIControlStateNormal];
    [self.cancelBtn addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.backGroundView addSubview:self.cancelBtn];

    
    self.btn3                 = [[UIButton alloc] initWithFrame:CGRectMake(0, SignatureViewHeight-44, ScreenWidth, 44)];
    self.btn3.titleLabel.font = [UIFont systemFontOfSize:15];
    self.btn3.backgroundColor = [UIColor colorWithRed:0.1529 green:0.7765 blue:0.7765 alpha:1.0];
    [self.btn3 setTitle:@"Submit" forState:UIControlStateNormal];
    [self.btn3 setTitleColor:WINDOW_COLOR forState:UIControlStateNormal];
    [self.btn3 addTarget:self action:@selector(okAction) forControlEvents:UIControlEventTouchUpInside];
    [self.backGroundView addSubview:self.btn3];

    [self onClear];
    
    [UIView animateWithDuration:0.5 animations:^{
        [self.backGroundView setFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height-SignatureViewHeight, [UIScreen mainScreen].bounds.size.width, SignatureViewHeight)];
    }];
}

#pragma mark - -- delegate ---

- (void)onSignatureWriteAction {
    
    if (!self.btn3.isSelected) {
        NSArray * tempBtnArr = @[self.OKBtn,self.cancelBtn,self.btn3];
        for (UIButton * btn in tempBtnArr) {
            btn.userInteractionEnabled = YES;
            [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        }
        
        self.OKBtn.selected = YES;//黑色完成
        [self.btn3 setTitleColor:RGB(255, 255, 255) forState:UIControlStateNormal];
    }
}

//播放
- (void)cancelAction:(UIButton*)sender {
    [signatureView sure:sender];
}


//清除
- (void)onClear {
    
    //清空画布
    [signatureView clear];
    
    //调整按钮状态
    NSArray * tempBtnArr = @[self.OKBtn,self.cancelBtn,self.btn3];
    for (UIButton * btn in tempBtnArr) {
        btn.userInteractionEnabled = NO;
        [btn setTitleColor:ACTIONSHEET_BACKGROUNDCOLOR forState:UIControlStateNormal];
    }
    self.OKBtn.selected = NO;//灰色完成
    [self.btn3 setTitleColor:WINDOW_COLOR forState:UIControlStateNormal];
}

//提交
- (void)okAction
{
    [self hide];
    if (self.delegate != nil &&[self.delegate respondsToSelector:@selector(onSubmitBtn:)]) {
        
        NSArray * arr = [signatureView imageRepresentation];
        [self.delegate onSubmitBtn:[arr objectAtIndex:1]];
        [self signatureUpdate:arr.firstObject];
    }
}

#pragma mark - -- Action ---


- (void)show {
    [UIView animateWithDuration:1.5 animations:^{
        UIWindow* window = [UIApplication sharedApplication].keyWindow;
        [window addSubview:self];
    }];
}
- (void)hide {
    [UIView animateWithDuration:0.3 animations:^{
        [self.backGroundView setFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, SignatureViewHeight)];
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}


#pragma mark - -- 网络 ---
 
-(void)signatureUpdate:(NSArray*)updatesStr
{
    
    NSMutableArray * tempArr = [NSMutableArray arrayWithCapacity:0];
    [updatesStr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [tempArr addObject:[obj mj_keyValues]];
    }];
    
    NSString * tempStr =   [[NSJSONSerialization dataWithJSONObject:tempArr
                                                           options:NSJSONWritingPrettyPrinted error:nil]
                           base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    
//    NSString * tempStr = [[tempArr mj_JSONData] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    
    [[[NetWorkBlock alloc]init]requestNetWithUrl:@"http://10.7.7.100:8001/write/submit"
                                    andInterface:nil
                       andBodyOfRequestForKeyArr:@[@"keys"]
                                     andValueArr:@[tempStr]
                                        andBlock:^(id result) {
                                            NSLog(@"cg");
                                        } andGet:NO];

}

-(void)signatureGetData
{
    [[[NetWorkBlock alloc]init]requestNetWithUrl:@"http://10.7.7.100:8001/write/get"
                                    andInterface:nil
                       andBodyOfRequestForKeyArr:nil
                                     andValueArr:nil
                                        andBlock:^(id result) {

                                            NSError *err;
                                            NSString * newStr = [result substringFromIndex:[result rangeOfString:@"keys="].length];
                                            
                                            NSData * base64Data = [[NSData alloc]initWithBase64EncodedString:[self encodeToPercentEscapeString:newStr]
                                                                                                     options:NSDataBase64DecodingIgnoreUnknownCharacters];
                                            NSArray *arr = [NSJSONSerialization JSONObjectWithData:base64Data
                                                                                           options:NSJSONReadingMutableContainers
                                                                                             error:&err];
                                            
//                                            NSArray * arr     = [[[NSData alloc]initWithBase64EncodedString:newStr
//                                                                                                    options:NSDataBase64DecodingIgnoreUnknownCharacters]mj_JSONObject];
                                            if (arr==nil)
                                                return;
                                            
                                            NSMutableArray * tempArr = [NSMutableArray arrayWithCapacity:0];
                                            [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                               [tempArr addObject:[SignatureModel mj_objectWithKeyValues:obj]];
                                            }];
                                            
                                            [signatureView.trackArr removeAllObjects];
                                            signatureView.trackArr  = tempArr;
                                            
                                            [self onSignatureWriteAction];
                                            [signatureView sure:self.cancelBtn];
                                            
                                        } andGet:YES];
}

- (NSString *)encodeToPercentEscapeString: (NSString *)input
{
    
    NSString *encodedString = input;
    NSString *decodedString  = (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                                                                     (__bridge CFStringRef)encodedString,
                                                                                                                     CFSTR(""),
                                                                                                                     CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    return decodedString;
}

@end
