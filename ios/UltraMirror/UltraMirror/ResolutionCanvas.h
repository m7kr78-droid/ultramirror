#import <Foundation/Foundation.h>

@interface ResolutionCanvas : NSObject
+ (NSInteger)nativeWidth;
+ (NSInteger)nativeHeight;
+ (BOOL)applyWidth:(NSInteger)width height:(NSInteger)height stretch:(BOOL)stretch error:(NSError **)error;
+ (BOOL)restoreNativeWithError:(NSError **)error;
@end
