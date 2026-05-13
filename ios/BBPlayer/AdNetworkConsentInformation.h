//
//  AdNetworkConsentInformation.h
//  BBPlayer
//
//  Created by armen on 11/20/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AdNetworkConsentInformation : NSObject <NSCoding>

- (instancetype)initWithNetworkID:(NSString*)networkID
                             name:(NSString*)networkName
                      displayName:(NSString*)networkDisplayName
                       privacyURL:(NSURL*)url
                          iconURL:(NSURL*)iconURL;

@property (strong, nonatomic) NSString *networkId;
@property (strong, nonatomic) NSString *networkName;
@property (strong, nonatomic) NSString *displayName;
@property (strong, nonatomic) NSURL *privacyPolicyURL;
@property (strong, nonatomic) NSURL *iconURL;
@property (assign, nonatomic) bool consented;

@end

NS_ASSUME_NONNULL_END
