//
//  NiceFind.mm
//  NiceFind
//
//  Created by Brian Collins on 09-10-23.
//  Copyright 2009 Brian Collins. All rights reserved.
//

#import "NiceFind.h"
#import "MethodSwizzle.h"
#import <objc/runtime.h>
#import "GTMStackTrace.h"

@implementation NiceFind

- (id)initWithPlugInController:(id <TMPlugInController>)aController
{
	self = [self init];
	NSApp = [NSApplication sharedApplication];
	MethodSwizzle(objc_getClass("OakProjectController"), @selector(findInProjectWithOptions:), @selector(fip:));
	MethodSwizzle(objc_getClass("OakFindManager"), @selector(performFindInProjectAction:), @selector(performFindInProjectActionNew:));
	return self;
}

- (void)test:(id)foo {
	exit(1);
}

- (float)version {
	return 0.01;
}

@end

@implementation OakProjectController (nice_find)


- (id)fip:(id)fp8 {
	NSLog(@"%@", GTMStackTrace());
	NSLog(@"input: %@", fp8);
	id result = [self fip:fp8];
	NSLog(@"result: %@", result);
	return result;
}
@end 

@interface OakFindManager : NSObject 
@end

@interface OakFindManager (nice_find)
@end

@implementation OakFindManager (nice_find)

- (void)performFindInProjectActionNew:(id)obj {

	[self performFindInProjectActionNew: obj];
}
@end