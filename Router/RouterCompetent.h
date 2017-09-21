//
//  RouterCompetent.h
//  Router
//
//  Created by mike on 2017/9/20.
//  Copyright © 2017年 mike. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol Competent <NSObject>
-(UIViewController*) competent:(NSString*) path parameters:(NSDictionary*) parameters;
@end

@interface RouterCompetent : NSObject <Competent>
@end

@interface BlockRouterCompetent : RouterCompetent
-(id) initWithBlock:(UIViewController*(^)(NSString*,NSDictionary*)) block;
@end
