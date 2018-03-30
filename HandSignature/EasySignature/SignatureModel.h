//
//  SignatureModel.h
//  HandSignature
//
//  Created by Kaiser on 2018/3/29.
//  Copyright © 2018年 liang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SignatureModel : NSObject
@property (nonatomic) NSNumber * pointX;
@property (nonatomic) NSNumber * pointY;
@property (nonatomic) NSNumber * pointFlag;
@property (nonatomic) NSNumber * systemTime;


-(instancetype)initWithDictionary:(NSDictionary*)dic;
@end
