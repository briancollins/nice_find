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

@implementation NiceFind

- (id)initWithPlugInController:(id <TMPlugInController>)aController
{
	self = [self init];
	NSApp = [NSApplication sharedApplication];
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


- (id)findInProjectWithOptions:(id)fp8 {
	NSLog(@"%@", fp8);
	exit(1);	
}
@end 