//
//  NSStringExtensions.m
//  NiceFind
//
//  Created by Brian Collins on 09-10-27.
//  Copyright 2009 Brian Collins. All rights reserved.
//

#import "NSStringExtensions.h"
#import "RegexKitLite.h"


@implementation NSString (nice_find)

- (NSArray *)rangesOfString:(NSString *)s caseless:(BOOL)caseless regex:(BOOL)regex {
	NSMutableArray *ranges = [NSMutableArray array];
	NSRange found;
	NSRange searchRange = NSMakeRange(0, NSUIntegerMax);
	do {
		if (regex)
			found = [self rangeOfRegex:s
							   options:(caseless ? RKLCaseless : 0) 
							   inRange:searchRange 
							   capture:0 
								 error:nil];
		else 
			found = [self rangeOfString:s
								options:(caseless ? NSCaseInsensitiveSearch : 0)
								  range:searchRange];
		
		if (found.location == NSNotFound) break;
		
		[ranges addObject:NSStringFromRange(found)];
		searchRange.location = found.location + found.length;
		searchRange.length = [self length] - searchRange.location;
		
	} while (searchRange.location < [self length]);
	
	return ranges;
}

@end
