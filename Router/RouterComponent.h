//
//  RouterCompetent.h
//  Router
//
//  Created by mike on 2017/9/20.
//  Copyright © 2017年 mike. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol Component <NSObject>
-(UIViewController*) component:(NSString*) path parameters:(NSDictionary*) parameters;
@end

@interface RouterComponent : NSObject <Component>
@end

@interface BlockRouterComponent : RouterComponent
-(id) initWithBlock:(UIViewController*(^)(NSString*,NSDictionary*)) block;
@end
