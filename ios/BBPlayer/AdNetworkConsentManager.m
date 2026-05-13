//
//  NetworkConsentInformationManager.m
//  BBPlayer
//
//  Created by armen on 11/20/19.
//

//#define TESTING

#define AD_NETWORK_IDS_KEY @"AdNetworkNamesKey"

#import <Foundation/Foundation.h>

#import "AdNetworkConsentManager.h"
#import "AdNetworkConsentInformation.h"

#import "AdNetworkConsentDialogViewController.h"

#import "BridgeHelper.h"

//#import "AdIntegratorManager.h"

@implementation AdNetworkConsentManager
+(AdNetworkConsentManager*)sharedManager
{
    static AdNetworkConsentManager* manager = nil;
    @synchronized(self){
        if(manager == nil) {
            manager = [[self alloc] init];
        }
    }
    return manager;
}

- (instancetype)init
{
	if (self = [super init]) {
		_networkConsentInfoArray = [NSMutableArray new];
		_installedNetworks = [NSMutableArray new];
		NSObject *is = [BridgeHelper getIntegrator:@"IronSourceAdIntegrator"];
		if (is){
			[_installedNetworks addObject:@"ironsource"];
		}
		NSObject *am = [BridgeHelper getIntegrator:@"AdMobAdIntegrator"];
		if (am){
			[_installedNetworks addObject:@"admob"];
		}
	}
	
	return self;
}

-(void)setupAdNetworks
{
	NSURLSessionTask *session = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString: @"https://sdks.api.8cell.com/v1/sdks"]
															completionHandler:^(NSData * _Nullable data,
																				NSURLResponse * _Nullable response,
																				NSError * _Nullable error)
	{
		if (error != noErr){
			NSLog(@"Got error: %@", error);
			return;
		}
		
		NSArray *sdkJson = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
		if (error != noErr){
			NSLog(@"Got error: %@", error);
			return;
		}
		
		NSDictionary *sdkJSONDictionary = [sdkJson firstObject];
		if (!sdkJSONDictionary || ![sdkJSONDictionary isKindOfClass:[NSDictionary class]]){
			NSLog(@"error with json dictionary: %@", sdkJSONDictionary);
			return;
		}
		
		NSArray *items = [sdkJSONDictionary objectForKey:@"items"];
		for (NSDictionary *item in items)
		{
			NSString *name = [item objectForKey:@"name"];
			if (![self->_installedNetworks containsObject:name.lowercaseString]){
				NSLog(@"Matching network not found in runtime for: %@", name);
				continue;
			}
            
            NSString *displayName = [item objectForKey:@"displayName"];
			
			NSString *iconPath = [item objectForKey:@"icon"];
			NSURL *iconURL;
			if (iconPath && [iconPath isKindOfClass:[NSString class]]){
				 iconURL = [NSURL URLWithString:iconPath];
			}
			
			NSArray *platforms = [item objectForKey:@"platforms"];
			if (![platforms containsObject:@"iOS"]){
				NSLog(@"iOS platform not specified in JSON :%@", item);
				continue;
			}
			
			NSDictionary *policyURLs = [item objectForKey:@"privacyPolicyUrls"];
			if (!policyURLs || ![policyURLs isKindOfClass:[NSDictionary class]]){
				NSLog(@"Policy URLs not specified in JSON :%@", item);
				continue;
			}
			
			NSString *iosPolicyPath = [policyURLs objectForKey:@"iOS"];
			if (!iosPolicyPath || ![iosPolicyPath isKindOfClass:[NSString class]]){
				NSLog(@"iOS policy URL not specified in JSON :%@", item);
				continue;
			}
			
			NSURL *policyURL = [NSURL URLWithString:iosPolicyPath];
            
            AdNetworkConsentInformation *info = [[AdNetworkConsentInformation alloc]
                                                 initWithNetworkID:name
                                                 name:name
                                                 displayName:displayName
                                                 privacyURL:policyURL
                                                 iconURL:iconURL];
			
			[self->_networkConsentInfoArray addObject: info];
			NSLog(@"network consent info: %@", info);
		}
		
		self->_networkConsentInfoArray = [NSMutableArray arrayWithArray:[self->_networkConsentInfoArray sortedArrayUsingDescriptors: @[
			[NSSortDescriptor sortDescriptorWithKey:@"networkName" ascending:YES]
		]]];
		
		[self->_downloadDelegate networkInfoCompletedDownload];
	}];
	
	[session resume];
}

-(void)presentConsentDialogWithViewController:(UIViewController*)rootVC
{
	if ([[NSUserDefaults standardUserDefaults] objectForKey:CONSENT_SHOWN_KEY]){
		return;
	}

	if (_installedNetworks.count > 0){
		AdNetworkConsentDialogViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:NSBundle.mainBundle] instantiateViewControllerWithIdentifier:@"ConsentDialogViewController"];
		
		[[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:CONSENT_SHOWN_KEY];
		[rootVC presentViewController:vc animated:YES completion:nil];
	}
}

-(void)consentToAllNetworksAccepted
{
	for (AdNetworkConsentInformation *network in _networkConsentInfoArray){
		network.consented = YES;
		[AdNetworkConsentManager setDeviceDefaultForAdNetwork:network];
	}
}

-(void)consentToAllNetworksDeclined
{
	for (AdNetworkConsentInformation *network in _networkConsentInfoArray){
		network.consented = NO;
		[AdNetworkConsentManager setDeviceDefaultForAdNetwork:network];
	}
}

-(void)usePerNetworkConsentSettingForAll
{
	for (AdNetworkConsentInformation *network in _networkConsentInfoArray){
		[AdNetworkConsentManager setDeviceDefaultForAdNetwork:network];
	}
}

+(void)setDeviceDefaultForAdNetwork:(AdNetworkConsentInformation*)network
{
	NSData *networkData = [NSKeyedArchiver archivedDataWithRootObject:network];
	if (!networkData){
		return;
	}

	[[NSUserDefaults standardUserDefaults] setObject:networkData forKey:network.networkId];
}

-(bool)getConsentStatusForNetworkWithName:(NSString*)networkName
{
	for (AdNetworkConsentInformation *info in _networkConsentInfoArray)
	{
		if ([info.networkName isEqualToString:networkName]){
			return info.consented;
		}
	}
	
	return NO;
}

-(void)loadConsentInfoForNetworks
{
	NSArray *networkNames = (NSArray*)[[NSUserDefaults standardUserDefaults] objectForKey:AD_NETWORK_IDS_KEY];
	NSMutableArray *tempNetworkList = [NSMutableArray new];
	for (NSString *name in networkNames)
	{
		NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:name];
		if (!data){
			continue;
		}

		AdNetworkConsentInformation *info = [NSKeyedUnarchiver unarchiveObjectWithData:data];
		if (!info || [info isKindOfClass:[AdNetworkConsentInformation class]]){
			continue;
		}
		
		[tempNetworkList addObject:info];
	}
	
	_networkConsentInfoArray = [NSMutableArray arrayWithArray:tempNetworkList];
}
@end
