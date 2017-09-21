//
//  ModuleRouter.m
//  Router
//
//  Created by mike on 2017/9/20.
//  Copyright © 2017年 mike. All rights reserved.
//

#import "ModuleRouter.h"
#import "Router.h"
#import "RouterImp.h"

@protocol ModuleInjection <NSObject>
-(id) moduleForInterface:(Protocol*) interface;
@end

@protocol Module <NSObject>
+(NSDictionary*) ModuleInfo;
-(id) initWithInjection:(id) injection;
@end

@interface ModuleRouter () <Module, Router>
@property(nonatomic,weak) id<ModuleInjection> injection;
@property(nonatomic,strong) RouterImp* root;
@end

@implementation ModuleRouter
+(NSDictionary*) ModuleInfo{
    return @{
             @"name":NSStringFromClass(self),
             @"module":self,
             @"interfaces":@[@protocol(Router)],
             @"init":@(YES)
            };
}
-(id) initWithInjection:(id) injection{
    self = [super init];
    if (self) {
        self.injection = injection;
        self.root = [[RouterImp alloc] initWithParent:self];
    }
    return self;
}
-(void) push:(NSString*) uri{
    UIViewController * controller = [self.root competent:uri parameters:@{}];
    if (controller) {
        [[self rootNavigation] pushViewController:controller animated:YES];
    }
}
-(void) replace:(NSString*) uri{
    UIViewController * controller = [self.root competent:uri parameters:@{}];
    if (controller) {
        NSMutableArray * controllers = [[[self rootNavigation] viewControllers] mutableCopy];
        [controllers removeLastObject];
        [controllers addObject:controller];
        [[self rootNavigation] setViewControllers:controllers animated:YES];
    }
}
-(void) pop{
    [[self rootNavigation] popViewControllerAnimated:YES];
}

-(id<Router>) addSubRouter:(NSString*) pattern{
    return [self.root addSubRouter:pattern];
}
-(void) addRouter:(NSString*) pattern competent:(UIViewController*(^)(NSString*,NSDictionary*)) block{
    return [self.root addRouter:pattern competent:block];
}
-(UINavigationController*) rootNavigation{
    return nil;
}
@end
