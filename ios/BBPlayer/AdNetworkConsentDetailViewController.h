//
//  NetworkConsentDetailViewController.h
//  BBPlayer
//
//  Created by armen on 11/20/19.
//

#import <UIKit/UIKit.h>
#import "AdNetworkConsentInformation.h"

NS_ASSUME_NONNULL_BEGIN

@interface AdNetworkConsentDetailViewController : UIViewController
@property (weak, nonatomic) AdNetworkConsentInformation *consentInfo;
@end

NS_ASSUME_NONNULL_END
