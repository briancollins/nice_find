#import <Cocoa/Cocoa.h>


@interface NSString (nice_find) 

- (NSArray *)rangesOfString:(NSString *)s caseless:(BOOL)caseless regex:(BOOL)regex;

@end
