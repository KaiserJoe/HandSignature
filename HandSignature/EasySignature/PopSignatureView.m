//
//  PopSignatureView.m
//  EsayHandwritingSignature
//
//  Created by Liangk on 2017/11/9.
//  Copyright © 2017年 liang. All rights reserved.
//

#import "PopSignatureView.h"
#import "EasySignatureView.h"

#define ScreenWidth  [UIScreen mainScreen].bounds.size.width  //  设备的宽度
#define ScreenHeight [UIScreen mainScreen].bounds.size.height //   设备的高度

#define RGB(__R, __G, __B) [UIColor colorWithRed:(__R) / 255.0f green:(__G) / 255.0f blue:(__B) / 255.0f alpha:1.0]

#define ACTIONSHEET_BACKGROUNDCOLOR             [UIColor colorWithRed:106/255.00f green:106/255.00f blue:106/255.00f alpha:0.8]
#define WINDOW_COLOR                            [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4]

#define SignatureViewHeight ((ScreenWidth*(350))/(375))

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
    
    UILabel *headView        = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 44)];
    headView.backgroundColor = [UIColor whiteColor];
    headView.textAlignment   = NSTextAlignmentCenter;
    headView.textColor       = [UIColor colorWithRed:0.3258 green:0.3258 blue:0.3258 alpha:1.0];
    headView.font            = [UIFont systemFontOfSize:15];
    headView.text            = @"收拾收拾";
    [self.backGroundView addSubview:headView];
    
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
    [self.OKBtn setTitle:@"清除" forState:UIControlStateNormal];
    [self.OKBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.OKBtn addTarget:self action:@selector(onClear) forControlEvents:UIControlEventTouchUpInside];
    [self.backGroundView addSubview:self.OKBtn];

    self.cancelBtn                 = [[UIButton alloc] initWithFrame:CGRectMake(6, 0, 44, 44)];
    self.cancelBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.cancelBtn setTitle:@"完成" forState:UIControlStateNormal];
    [self.cancelBtn setTitle:@"重现" forState:UIControlStateSelected];
    [self.cancelBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.cancelBtn addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.backGroundView addSubview:self.cancelBtn];

    
    self.btn3                 = [[UIButton alloc] initWithFrame:CGRectMake(0, SignatureViewHeight-44, ScreenWidth, 44)];
    self.btn3.titleLabel.font = [UIFont systemFontOfSize:15];
    self.btn3.backgroundColor = [UIColor colorWithRed:0.1529 green:0.7765 blue:0.7765 alpha:1.0];
    [self.btn3 setTitle:@"提交" forState:UIControlStateNormal];
    [self.btn3 setTitleColor:WINDOW_COLOR forState:UIControlStateNormal];
    [self.btn3 addTarget:self action:@selector(okAction) forControlEvents:UIControlEventTouchUpInside];
    [self.backGroundView addSubview:self.btn3];

    
    [UIView animateWithDuration:0.5 animations:^{
        [self.backGroundView setFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height-SignatureViewHeight, [UIScreen mainScreen].bounds.size.width, SignatureViewHeight)];
    }];
}

#pragma mark - -- delegate ---

- (void)onSignatureWriteAction {
    [self.btn3 setTitleColor:RGB(255, 255, 255) forState:UIControlStateNormal];
}

//存or播放
- (void)cancelAction:(UIButton*)sender {
    
    if (sender.isSelected) {
        //自动绘制
    }
    else
    {   //保存图片
        
        
    }
}


//清除
- (void)onClear {
    
    //清空画布
    [signatureView clear];
    
    //调整按钮状态
    NSArray * tempBtnArr = @[self.OKBtn,self.cancelBtn,self.btn3];
    for (UIButton * btn in tempBtnArr) {
        btn.userInteractionEnabled = NO;
        [btn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    }
    self.OKBtn.selected = NO;//灰色完成
    [self.btn3 setTitleColor:WINDOW_COLOR forState:UIControlStateNormal];
}

//提交
- (void)okAction
{
     [signatureView sure];
    
    if(signatureView.SignatureImg)
    {
        NSLog(@"haveImage");
//        self.hidden = YES;
        [self hide];
        if (self.delegate != nil &&[self.delegate respondsToSelector:@selector(onSubmitBtn:)]) {
            [self.delegate onSubmitBtn:signatureView.SignatureImg];
        }
    }
    else
    {
        NSLog(@"NoImage");
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

@end
