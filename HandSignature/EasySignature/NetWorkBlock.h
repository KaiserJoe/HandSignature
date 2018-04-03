//
//  NetWorkBlock.h
//  Block
//
//  Created by llz on 14-12-25.
//  Copyright (c) 2014年 llz. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NetWorkBlock : NSObject

-(void)requestNetWithUrl:(NSString *)urlStr andInterface:(NSString*)interface andBodyOfRequestForKeyArr:(NSArray*)keyArr andValueArr:(NSArray*)valueArr
                andBlock:(void(^)(id result))block andGet:(BOOL)isGet;
@end
