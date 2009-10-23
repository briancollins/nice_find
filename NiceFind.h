//
//  NiceFind.h
//  NiceFind
//
//  Created by Brian Collins on 09-10-23.
//  Copyright 2009 Brian Collins. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol TMPlugInController
- (float)version;
@end

@interface NiceFind : NSObject
{
}
- (id)initWithPlugInController:(id <TMPlugInController>)aController;
@end

@interface OakProjectController : NSObject
@end

@interface OakProjectController (nice_find)
@end
