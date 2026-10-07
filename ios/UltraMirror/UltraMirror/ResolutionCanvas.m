#import "ResolutionCanvas.h"
#import <UIKit/UIKit.h>

static NSString * const kCanvasSuite = @"com.apple.iokit.IOMobileGraphicsFamily";
static NSString * const kSystemPrefs = @"/var/mobile/Library/Preferences/com.apple.iokit.IOMobileGraphicsFamily.plist";

@implementation ResolutionCanvas

+ (NSInteger)nativeWidth {
    return (NSInteger)round(UIScreen.mainScreen.nativeBounds.size.width);
}

+ (NSInteger)nativeHeight {
    return (NSInteger)round(UIScreen.mainScreen.nativeBounds.size.height);
}

+ (NSError *)blockedError {
    return [NSError errorWithDomain:@"by.sonic.resolution"
                               code:1
                           userInfo:@{
        NSLocalizedDescriptionKey:
            @"iOS blocked the display change. A normal sideloaded app cannot change another game's resolution."
    }];
}

+ (BOOL)applyWidth:(NSInteger)width height:(NSInteger)height stretch:(BOOL)stretch error:(NSError **)error {
    if (width < 320 || height < 320) {
        if (error) {
            *error = [NSError errorWithDomain:@"by.sonic.resolution"
                                         code:2
                                     userInfo:@{NSLocalizedDescriptionKey: @"Width and height must be at least 320."}];
        }
        return NO;
    }

    NSDictionary *payload = @{
        @"canvas_width": @(width),
        @"canvas_height": @(height),
        @"stretch": @(stretch)
    };

    NSUserDefaults *suite = [[NSUserDefaults alloc] initWithSuiteName:kCanvasSuite];
    [suite setInteger:width forKey:@"canvas_width"];
    [suite setInteger:height forKey:@"canvas_height"];
    [suite setBool:stretch forKey:@"enable-external-display-stretch"];
    [suite synchronize];

    CFPreferencesSetAppValue(CFSTR("canvas_width"), (__bridge CFNumberRef)@(width), (__bridge CFStringRef)kCanvasSuite);
    CFPreferencesSetAppValue(CFSTR("canvas_height"), (__bridge CFNumberRef)@(height), (__bridge CFStringRef)kCanvasSuite);
    CFPreferencesAppSynchronize((__bridge CFStringRef)kCanvasSuite);

    NSError *writeError = nil;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:payload
                                                              format:NSPropertyListBinaryFormat_v1_0
                                                             options:0
                                                               error:&writeError];
    BOOL wroteSystem = data && [data writeToFile:kSystemPrefs options:NSDataWritingAtomic error:&writeError];
    if (!wroteSystem) {
        if (error) {
            *error = [self blockedError];
        }
        return NO;
    }
    return YES;
}

+ (BOOL)restoreNativeWithError:(NSError **)error {
    return [self applyWidth:[self nativeWidth] height:[self nativeHeight] stretch:NO error:error];
}

@end
