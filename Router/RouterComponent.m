//
//  RouterCompetent.m
//  Router
//
//  Created by mike on 2017/9/20.
//  Copyright © 2017年 mike. All rights reserved.
//

#import "RouterComponent.h"

@implementation RouterComponent
-(UIViewController*) component:(NSString*) path parameters:(NSDictionary*) parameters{
    return nil;
}
@end

@interface BlockRouterComponent ()
@property (nonatomic,copy) UIViewController*(^block)(NSString*,NSDictionary*);
@end

@implementation BlockRouterComponent
-(id) initWithBlock:(UIViewController* (^)(NSString *, NSDictionary *))block{
    self = [super init];
    if (self) {
        self.block = block;
    }
    return self;
}
-(UIViewController*) component:(NSString *)path parameters:(NSDictionary *)parameters{
    return self.block(path,parameters);
}
@end
