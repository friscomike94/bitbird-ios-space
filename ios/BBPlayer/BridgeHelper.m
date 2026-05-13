//
//  BridgeHelper.m
//  BBPlayer
//
//  Created by Cody Thompson on 11/15/19.
//

#import <Foundation/Foundation.h>
#import "BridgeHelper.h"

#define BB_INIT_AD_SEL @"initAdNetwork:withKeyValuePairs:withViewController:"
#define BB_INIT_AD_SEL_CUSTOM @"initAdNetwork:withViewController:"

@implementation BridgeHelper

+ (NSObject*)getIntegrator:(NSString *)className {
    // https://stackoverflow.com/a/20058585/2453932
    Class classType = NSClassFromString(className);
    if (classType != nil) {
        SEL methodSelector = NSSelectorFromString(@"shared");
        if ([classType respondsToSelector:methodSelector]) {
            IMP methodImp = [classType methodForSelector:methodSelector];
            NSObject* (*func)(id, SEL) = (void *)methodImp;
            return func(classType, methodSelector);
        }
        else {
            return nil;
        }
    }
    else {
        return nil;
    }
}

+ (NSString* _Nullable)validateIntegrator:(NSObject *)integrator {
    NSMutableArray* requiredMethods = [NSMutableArray arrayWithObjects:
        @"setConsent:",
        @"initBanner",
        @"showBanner",
        @"hideBanner",
        @"isBannerVisible",
        @"initInterstitial",
        @"showInterstitial",
        @"initRewardedVideo",
        @"showRewardedVideo",
        @"isRewardedVideoAvailable",
        nil];
    
    if (![integrator respondsToSelector:NSSelectorFromString(BB_INIT_AD_SEL)]
        && ![integrator respondsToSelector:NSSelectorFromString(BB_INIT_AD_SEL_CUSTOM)]) {
        return [NSString stringWithFormat:@"Integrator must implement the method %@ OR %@", BB_INIT_AD_SEL, BB_INIT_AD_SEL_CUSTOM];
    }
    
    for (NSString* selectorStr in requiredMethods) {
        if (![integrator respondsToSelector:NSSelectorFromString(selectorStr)]) {
            return [NSString stringWithFormat:@"Integrator must implement the method %@", selectorStr];
        }
    }
    
    return nil;
}

+ (void)callVoidMethod:(NSString*)methodName withObj:(NSObject*)obj {
    // https://stackoverflow.com/a/20058585/2453932
    SEL methodSelector = NSSelectorFromString(methodName);
    IMP methodImp = [obj methodForSelector:methodSelector];
    void (*func)(id, SEL) = (void *)methodImp;
    func(obj, methodSelector);
}

+ (bool)callBoolMethod:(NSString*)methodName withObj:(NSObject*)obj {
    // https://stackoverflow.com/a/20058585/2453932
    SEL methodSelector = NSSelectorFromString(methodName);
    IMP methodImp = [obj methodForSelector:methodSelector];
    bool (*func)(id, SEL) = (void*)methodImp;
    return func(obj, methodSelector);
}

+ (void)callVoidMethod:(NSString*)methodName withObj:(NSObject*)obj withBoolArg:(bool)boolArg {
    // https://stackoverflow.com/a/20058585/2453932
    SEL methodSelector = NSSelectorFromString(methodName);
    IMP methodImp = [obj methodForSelector:methodSelector];
    void (*func)(id, SEL, bool) = (void *)methodImp;
    func(obj, methodSelector, boolArg);
}

+ (void)setConsent:(NSObject*)integrator withConsentValue:(bool)consented {
    [self callVoidMethod:@"setConsent:" withObj:integrator withBoolArg:consented];
}

+ (void)initAdNetwork:(NSObject *)integrator withNetworkId:(NSString *)networkId withKeyValuePairs:(NSDictionary<NSString*,NSString*>*)keyValuePairs withViewController:(UIViewController *)viewController {
    // https://stackoverflow.com/a/20058585/2453932
    SEL methodSelector = NSSelectorFromString(@"initAdNetwork:withKeyValuePairs:withViewController:");
    IMP methodImp = [integrator methodForSelector:methodSelector];
    void (*func)(id, SEL, NSString*, NSDictionary<NSString*,NSString*>*, UIViewController*) = (void *)methodImp;
    func(integrator, methodSelector, networkId, keyValuePairs, viewController);
}

// this is for custom integrators
+ (void)initAdNetwork:(NSObject *)integrator withNetworkId:(NSString *)networkId withViewController:(UIViewController *)viewController {
    // https://stackoverflow.com/a/20058585/2453932
    SEL methodSelector = NSSelectorFromString(@"initAdNetwork:withViewController:");
    IMP methodImp = [integrator methodForSelector:methodSelector];
    void (*func)(id, SEL, NSString*, UIViewController*) = (void *)methodImp;
    func(integrator, methodSelector, networkId, viewController);
}

@end
