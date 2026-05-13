//
//  BridgeHelper.h
//  BBPlayer
//
//  Created by Cody Thompson on 11/15/19.
//

#ifndef BridgeHelper_h
#define BridgeHelper_h

#import <UIKit/UIKit.h>

@interface BridgeHelper : NSObject

+ (NSObject*)getIntegrator:(NSString*)className;
+ (NSString*)validateIntegrator:(NSObject*)integrator;
+ (void)callVoidMethod:(NSString*)methodName withObj:(NSObject*)obj;
+ (bool)callBoolMethod:(NSString*)methodName withObj:(NSObject*)obj;
+ (void)callVoidMethod:(NSString*)methodName withObj:(NSObject*)obj withBoolArg:(bool)boolArg;

+ (void)setConsent:(NSObject *)integrator withConsentValue:(bool)consented;
+ (void)initAdNetwork:(NSObject *)integrator withNetworkId:(NSString *)networkId withKeyValuePairs:(NSDictionary<NSString*,NSString*>*)keyValuePairs withViewController:(UIViewController *)viewController;
+ (void)initAdNetwork:(NSObject *)integrator withNetworkId:(NSString *)networkId withViewController:(UIViewController *)viewController;

@end

#endif /* BridgeHelper_h */
