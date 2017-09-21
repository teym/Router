//
//  RouterImp.h
//  Router
//
//  Created by mike on 2017/9/20.
//  Copyright © 2017年 mike. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Router.h"
#import "RouterCompetent.h"

@interface RouterImp : NSObject <Router, Competent>
-(id) initWithParent:(id<Router>) parent;
@end
