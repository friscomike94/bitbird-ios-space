//
//  AdNetworkConsentInformation.m
//  BBPlayer
//
//  Created by armen on 11/20/19.
//

#define NETWORK_ID_KEY @"NETWORK_ID_KEY"
#define NETWORK_NAME_KEY @"NETWORK_NAME_KEY"
#define NETWORK_PRIVACY_POLICY_URL_KEY @"NETWORK_PRIVACY_POLICY_URL_KEY"
#define NETWORK_CONSENT_VALUE_KEY @"NETWORK_CONSENT_VALUE_KEY"

#import "AdNetworkConsentInformation.h"

@implementation AdNetworkConsentInformation
- (instancetype)initWithNetworkID:(NSString*)networkID
                             name:(NSString*)networkName
                      displayName:(NSString*)networkDisplayName
                       privacyURL:(NSURL*)url
                          iconURL:(NSURL*)iconURL
{
    if (self = [super init])
    {
        _networkId = networkID;
        _networkName = networkName;
        _displayName = networkDisplayName;
        _privacyPolicyURL = url;
        _consented = YES;
    }
    return self;
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder
{
	if (self = [super init])
	{
		_networkId = [coder decodeObjectForKey:NETWORK_ID_KEY];
		_networkName = [coder decodeObjectForKey:NETWORK_NAME_KEY];
		_privacyPolicyURL = [coder decodeObjectForKey:NETWORK_PRIVACY_POLICY_URL_KEY];
		_consented = [coder decodeBoolForKey:NETWORK_CONSENT_VALUE_KEY];
	}
	return self;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder
{
	[coder encodeObject:_networkId forKey:NETWORK_ID_KEY];
	[coder encodeObject:_networkName forKey:NETWORK_NAME_KEY];
	[coder encodeObject:_privacyPolicyURL forKey:NETWORK_PRIVACY_POLICY_URL_KEY];
	[coder encodeBool:_consented forKey:NETWORK_CONSENT_VALUE_KEY];
}


@end
