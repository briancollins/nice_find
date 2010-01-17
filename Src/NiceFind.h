#import <Cocoa/Cocoa.h>

@protocol TMPlugInController
- (float)version;
@end

@interface NiceFind : NSObject
{
}
- (id)initWithPlugInController:(id <TMPlugInController>)aController;
@end


