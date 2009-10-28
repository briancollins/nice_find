//
//  NSStringExtensions.h
//  NiceFind
//
//  Created by Brian Collins on 09-10-27.
//  Copyright 2009 Brian Collins. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (nice_find) 

- (NSArray *)rangesOfString:(NSString *)s caseless:(BOOL)caseless regex:(BOOL)regex;

@end
