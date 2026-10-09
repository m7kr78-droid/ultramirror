#import "InstalledApps.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

@implementation InstalledApps

+ (BOOL)openBundleID:(NSString *)bundleID {
    if (bundleID.length == 0) {
        return NO;
    }

    Class wsClass = NSClassFromString(@"LSApplicationWorkspace");
    id workspace = [wsClass performSelector:NSSelectorFromString(@"defaultWorkspace")];
    SEL openSel = NSSelectorFromString(@"openApplicationWithBundleID:");
    if ([workspace respondsToSelector:openSel]) {
        NSMethodSignature *signature = [workspace methodSignatureForSelector:openSel];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:workspace];
        [invocation setSelector:openSel];
        NSString *identifier = bundleID;
        [invocation setArgument:&identifier atIndex:2];
        [invocation invoke];
        if (signature.methodReturnLength == sizeof(BOOL)) {
            BOOL result = NO;
            [invocation getReturnValue:&result];
            if (result) {
                return YES;
            }
        }
    }

    UIApplication *application = [UIApplication sharedApplication];
    SEL launchSel = NSSelectorFromString(@"launchApplicationWithIdentifier:suspended:");
    if ([application respondsToSelector:launchSel]) {
        NSMethodSignature *signature = [application methodSignatureForSelector:launchSel];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:application];
        [invocation setSelector:launchSel];
        NSString *identifier = bundleID;
        BOOL suspended = NO;
        [invocation setArgument:&identifier atIndex:2];
        [invocation setArgument:&suspended atIndex:3];
        [invocation invoke];
        if (signature.methodReturnLength > 0) {
            BOOL result = NO;
            [invocation getReturnValue:&result];
            return result;
        }
        return YES;
    }
    return NO;
}

+ (NSArray<NSDictionary *> *)userApps {
    NSMutableArray *result = [NSMutableArray array];
    NSMutableSet *seen = [NSMutableSet set];
    Class wsClass = NSClassFromString(@"LSApplicationWorkspace");
    id workspace = [wsClass performSelector:NSSelectorFromString(@"defaultWorkspace")];

    for (NSString *selectorName in @[@"allInstalledApplications", @"allApplications"]) {
        SEL selector = NSSelectorFromString(selectorName);
        if (![workspace respondsToSelector:selector]) {
            continue;
        }
        NSArray *apps = [workspace performSelector:selector];
        for (id proxy in apps) {
            [self addProxy:proxy to:result seen:seen];
        }
    }

    SEL enumSelector = NSSelectorFromString(@"enumerateApplicationsOfType:block:");
    if ([workspace respondsToSelector:enumSelector]) {
        void (^block)(id) = ^(id proxy) {
            [self addProxy:proxy to:result seen:seen];
        };
        NSMethodSignature *signature = [workspace methodSignatureForSelector:enumSelector];
        for (NSUInteger type = 0; type < 2; type++) {
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:workspace];
            [invocation setSelector:enumSelector];
            NSUInteger applicationType = type;
            void (^copiedBlock)(id) = [block copy];
            [invocation setArgument:&applicationType atIndex:2];
            [invocation setArgument:&copiedBlock atIndex:3];
            [invocation invoke];
        }
    }

    return result;
}

+ (void)addProxy:(id)proxy to:(NSMutableArray *)result seen:(NSMutableSet *)seen {
    SEL idSelector = NSSelectorFromString(@"applicationIdentifier");
    if (![proxy respondsToSelector:idSelector]) {
        return;
    }
    NSString *bundleID = [proxy performSelector:idSelector];
    if (bundleID.length == 0 || [seen containsObject:bundleID]) {
        return;
    }
    if ([bundleID hasPrefix:@"com.apple."]) {
        return;
    }
    NSString *name = @"";
    SEL nameSelector = NSSelectorFromString(@"localizedName");
    if ([proxy respondsToSelector:nameSelector]) {
        name = [proxy performSelector:nameSelector] ?: @"";
    }
    [seen addObject:bundleID];
    [result addObject:@{
        @"id": bundleID,
        @"name": name.length > 0 ? name : bundleID
    }];
}

@end

#pragma clang diagnostic pop
