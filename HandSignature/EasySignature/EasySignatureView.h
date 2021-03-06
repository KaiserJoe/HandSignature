//
//  EasySignatureView.h
//  EsayHandwritingSignature
//
//  Created by Liangk on 2017/11/9.
//  Copyright © 2017年 liang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SignatureModel.h"

//代理
@protocol SignatureViewDelegate <NSObject>
/**
 产生签名手写动作
 */
- (void)onSignatureWriteAction;

@end


/**
 手写签字视图
 */
@interface EasySignatureView : UIView

@property (nonatomic, strong) NSString              * showMessage;//签名完成后的水印文字
@property (nonatomic, assign) id<             SignatureViewDelegate> delegate;
@property (nonatomic,strong ) NSMutableArray <SignatureModel*> * trackArr;
/**
 清除
 */
- (void)clear;

/**
 确定
 */
- (void)sure:(UIButton *)sender;


-(NSArray *) imageRepresentation;
@end
