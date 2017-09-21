//
//  RouterImp.m
//  Router
//
//  Created by mike on 2017/9/20.
//  Copyright © 2017年 mike. All rights reserved.
//

#import "RouterImp.h"
#import "RouterComponent.h"

@interface RouterImp ()
@property (nonatomic,weak) id<Router> parent;
@property (nonatomic,strong) NSArray * subRouters;
@property (nonatomic,strong) NSArray * patterns;
@end

@implementation RouterImp
-(id) initWithParent:(id<Router>)parent{
    self = [super init];
    if (self) {
        self.parent = parent;
        self.subRouters = @[];
        self.patterns = @[];
    }
    return self;
}
-(void) push:(NSString*) uri{
    return [self.parent push:uri];
}
-(void) replace:(NSString*) uri{
    return [self.parent replace:uri];
}
-(void) pop{
    return [self.parent pop];
}

-(id<Router>) addSubRouter:(NSString*) pattern{
    NSLog(@"add sub router[%@]",pattern);
    RouterImp * sub = [[RouterImp alloc] initWithParent:self];
    RouterComponent * component = [[BlockRouterComponent alloc] initWithBlock:^UIViewController *(NSString * path, NSDictionary * parameters) {
        return [sub component:path parameters:parameters];
    }];
    self.subRouters = [self.subRouters arrayByAddingObject:sub];
    self.patterns = [self.patterns arrayByAddingObject:@{@"pattern":pattern,
                                                         @"component":component,
                                                         @"router":sub
                                                         }];
    return sub;
}
-(void) addRouter:(NSString*) pattern competent:(UIViewController*(^)(NSString*,NSDictionary*)) block{
    NSLog(@"add router[%@]",pattern);
    RouterComponent * competent = [[BlockRouterComponent alloc] initWithBlock:block];
    self.patterns = [self.patterns arrayByAddingObject:@{@"pattern":pattern,
                                                         @"component":competent
                                                         }];
}
-(UIViewController*) component:(NSString *)path parameters:(NSDictionary *)parameters{
    //sample match
    NSArray * patterns = self.patterns;
    for (NSDictionary * router in patterns) {
        NSString * pattern = [router objectForKey:@"pattern"];
        if ([path containsString:pattern]) {
            RouterComponent * component = [router objectForKey:@"component"];
            return [component component:path parameters:parameters];
        }
    }
    return nil;
}
@end
