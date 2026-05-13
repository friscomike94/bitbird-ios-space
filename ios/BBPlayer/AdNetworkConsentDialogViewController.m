//
//  ConsentDialogViewController.m
//  BBPlayer
//
//  Created by armen on 11/19/19.
//

#import "AdNetworkConsentDialogViewController.h"

#import "AdNetworkConsentManager.h"
#import "AdNetworkConsentListViewController.h"
@interface AdNetworkConsentDialogViewController () <AdNetworkConsentListParentDelegate>
@end

@implementation AdNetworkConsentDialogViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)acceptAll:(id)sender {
	[[AdNetworkConsentManager sharedManager] consentToAllNetworksAccepted];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)declineAll:(id)sender {
	[[AdNetworkConsentManager sharedManager] consentToAllNetworksDeclined];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)customSettings:(id)sender
{
	AdNetworkConsentListViewController* vvc = [[UIStoryboard storyboardWithName:@"Main" bundle:NSBundle.mainBundle]
									  	instantiateViewControllerWithIdentifier:@"NetworkConsentList"];
	vvc.modalPresentationStyle = UIModalPresentationCurrentContext;
	vvc.delegate = self;
	[self presentViewController:vvc animated:YES completion:nil];
}

- (void)close {
	[self dismissViewControllerAnimated:YES completion:nil];
}
@end
