//
//  NetWorkBlock.m
//  Block
//
//  Created by kaiser on 14-12-25.
//  Copyright (c) 2014年 kaiser. All rights reserved.
//

#import "NetWorkBlock.h"

@implementation NetWorkBlock
- (void)requestNetWithUrl:(NSString *)urlStr
			 andInterface:(NSString*)interface
andBodyOfRequestForKeyArr:(NSArray*)keyArr
			  andValueArr:(NSArray*)valueArr
				 andBlock:(void (^)(id))block
				  andGet:(BOOL)isGet
{
	//get请求参数
    NSMutableString *reqStr    = [NSMutableString stringWithCapacity:0];\
    //Post请求Body
    NSMutableString *objectStr = [NSMutableString stringWithCapacity:0];
    
    if(isGet && interface !=nil)
        [reqStr appendFormat:@"%@%@?",urlStr,interface];
    else if(!isGet && interface != nil)
        [reqStr appendFormat:@"%@%@",urlStr,interface];
    else
        [reqStr appendFormat:@"%@",urlStr];
		
	
	if (!isGet)
	{//post
		for(int i = 0;i<valueArr.count;i++)
		{
			[objectStr appendFormat:@"%@=%@",keyArr[i],[self encodeToPercentEscapeString:valueArr[i]]];
			
			if(i<valueArr.count-1)
				[objectStr appendString:@"&"];
		}
	}
	else
	{
		for(int i = 0;i<valueArr.count;i++)
		{
			[reqStr appendFormat:@"%@=%@",keyArr[i],[self encodeToPercentEscapeString:valueArr[i]]];
			
			if(i<valueArr.count-1)
				[reqStr appendString:@"&"];
		}
	}

	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:reqStr]
													   cachePolicy:NSURLRequestUseProtocolCachePolicy
												   timeoutInterval:30];
	
	if(!isGet)
	{//post
		[req setHTTPMethod:@"POST"];
		[req setHTTPBody:[objectStr dataUsingEncoding:NSUTF8StringEncoding]];
	}
	[req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];//请求头
	
	NSLog(@"当前网络请求地址---%@",reqStr);

	 NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession]dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		 
		 dispatch_async(dispatch_get_main_queue(), ^{
			 if(error)
			 {
				 block(@{@"error":error.localizedDescription});
				 NSLog(@"%@",error);
			 }
			 else
			 {
//                 id dic = [NSJSONSerialization JSONObjectWithData:data options :NSJSONReadingMutableContainers error:nil];
                 
				 block([[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);
			 }
		 });

	}];
	
	[dataTask resume];
	
}


- (NSString *)encodeToPercentEscapeString: (NSString *)input
{
    CFStringRef aCFString =(CFStringRef)
    CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                            (CFStringRef)input,
                                            NULL,
                                            (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                            kCFStringEncodingUTF8);
    
   NSString *aNSString = (__bridge NSString *)aCFString;
    
   CFRelease(aCFString);
    
   return aNSString;
}

@end
