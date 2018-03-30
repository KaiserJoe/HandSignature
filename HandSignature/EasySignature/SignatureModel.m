//
//  SignatureModel.m
//  HandSignature
//
//  Created by Kaiser on 2018/3/29.
//  Copyright © 2018年 liang. All rights reserved.
//

#import "SignatureModel.h"

@implementation SignatureModel

-(instancetype)initWithDictionary:(NSDictionary*)dic
{
    self = [super init];
    if (self) {
        [self setValuesForKeysWithDictionary:dic];
    }
    
    return self;
}


-(void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    NSLog(@"%@",key);
}
@end
