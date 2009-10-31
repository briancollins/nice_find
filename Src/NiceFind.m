//
//  NiceFind.mm
//  NiceFind
//
//  Created by Brian Collins on 09-10-23.
//  Copyright 2009 Brian Collins. All rights reserved.
//

#import <objc/runtime.h>

#import "NiceFind.h"
#import "MethodSwizzle.h"
#import "GTMStackTrace.h"
#import "FindController.h"

@implementation NiceFind

- (id)initWithPlugInController:(id <TMPlugInController>)aController
{
	self = [self init];
	NSApp = [NSApplication sharedApplication];
	methodSwizzle(objc_getClass("OakProjectController"), @selector(findInProjectWithOptions:), @selector(fip:));
	methodSwizzle(objc_getClass("OakFindManager"), @selector(performFindInProjectAction:), @selector(performFindInProjectActionNew:));
	return self;
}

@end


@interface AppDelegate (nice_find) @end

@implementation AppDelegate (nice_find)


- (void)orderFrontFindInProjectPanel:(id)sender {
	[[FindController sharedInstance] showAndMove];
}

@end

