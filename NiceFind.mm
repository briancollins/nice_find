//
//  NiceFind.mm
//  NiceFind
//
//  Created by Brian Collins on 09-10-23.
//  Copyright 2009 Brian Collins. All rights reserved.
//

#import "NiceFind.h"
#import "MethodSwizzle.h"

@implementation NiceFind

- (id)initWithPlugInController:(id <TMPlugInController>)aController
{
	self = [self init];
	NSApp = [NSApplication sharedApplication];

	return self;
}
@end
