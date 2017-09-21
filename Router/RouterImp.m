//
//  RouterImp.m
//  Router
//
//  Created by mike on 2017/9/20.
//  Copyright © 2017年 mike. All rights reserved.
//

#import "RouterImp.h"
#import "RouterCompetent.h"

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
    RouterImp * sub = [[RouterImp alloc] initWithParent:self];
    RouterCompetent * competent = [[BlockRouterCompetent alloc] initWithBlock:^UIViewController *(NSString * path, NSDictionary * parameters) {
        return [sub competent:path parameters:parameters];
    }];
    self.subRouters = [self.subRouters arrayByAddingObject:sub];
    self.patterns = [self.patterns arrayByAddingObject:@{@"pattern":pattern,
                                                         @"competent":competent,
                                                         @"router":sub
                                                         }];
    return sub;
}
-(void) addRouter:(NSString*) pattern competent:(UIViewController*(^)(NSString*,NSDictionary*)) block{
    RouterCompetent * competent = [[BlockRouterCompetent alloc] initWithBlock:block];
    self.patterns = [self.patterns arrayByAddingObject:@{@"pattern":pattern,
                                                         @"competent":competent
                                                         }];
}
-(UIViewController*) competent:(NSString *)path parameters:(NSDictionary *)parameters{
    return nil;
}
@end
