//
//  Router.h
//  Router
//
//  Created by mike on 2017/9/20.
//  Copyright © 2017年 mike. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for Router.
FOUNDATION_EXPORT double RouterVersionNumber;

//! Project version string for Router.
FOUNDATION_EXPORT const unsigned char RouterVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Router/PublicHeader.h>

@protocol Router <NSObject>
-(void) push:(NSString*) uri;
-(void) replace:(NSString*) uri;
-(void) pop;

-(id<Router>) addSubRouter:(NSString*) pattern;
-(void) addRouter:(NSString*) pattern competent:(UIViewController*(^)(NSString*,NSDictionary*)) block;
@end
