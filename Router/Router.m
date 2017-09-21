    //
    //  Router.m
    //  Router
    //
    //  Created by mike on 2017/9/20.
    //  Copyright © 2017年 mike. All rights reserved.
    //

#import "Router.h"
#import "RouterImp.h"
#import <Module/Module.h>

@interface Router:NSObject <Module, Router>
@property(nonatomic,weak) id<ModuleInjection> injection;
@property(nonatomic,strong) RouterImp* root;
@end

@implementation Router
+(NSArray*) Interfaces{
    return @[@protocol(Router)];
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
    UIViewController * controller = [self.root component:uri parameters:@{}];
    if (controller) {
        [[self rootNavigation] pushViewController:controller animated:YES];
    }
}
-(void) replace:(NSString*) uri{
    UIViewController * controller = [self.root component:uri parameters:@{}];
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
    UINavigationController *ctrl = (UINavigationController*)[[[UIApplication sharedApplication] keyWindow] rootViewController];
    if (![ctrl isKindOfClass:[UINavigationController class]]) {
        ctrl = [[UINavigationController alloc] initWithRootViewController:ctrl ? ctrl : [UIViewController new]];
        [[[UIApplication sharedApplication] keyWindow] setRootViewController:ctrl];
    }
    return ctrl;
}
@end

ModuleLoader(Router)
