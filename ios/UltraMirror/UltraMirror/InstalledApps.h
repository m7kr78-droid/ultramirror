#import <Foundation/Foundation.h>

@interface InstalledApps : NSObject
+ (NSArray<NSDictionary *> *)userApps;
+ (BOOL)openBundleID:(NSString *)bundleID;
@end
