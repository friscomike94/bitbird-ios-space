//
//  NetworkConsentDetailViewController.m
//  BBPlayer
//
//  Created by armen on 11/20/19.
//

#import "AdNetworkConsentDetailViewController.h"
#import <WebKit/WebKit.h>

@interface AdNetworkConsentDetailViewController ()
@property (weak, nonatomic) IBOutlet UILabel *NetworkNameLabel;
@property (weak, nonatomic) IBOutlet UISwitch *ConsentSwitch;
@property (weak, nonatomic) IBOutlet UIView *WebKitParentView;
@property (strong, nonatomic) WKWebView *PrivacyURLWebView;  //wkwebview has to be added programmatically because it doesn't work with IB before iOS 11.
@end

@implementation AdNetworkConsentDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self setupWebView];
	
	_NetworkNameLabel.text = _consentInfo.displayName;
	_ConsentSwitch.on = _consentInfo.consented;
}

-(void)setupWebView
{
	_PrivacyURLWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, _WebKitParentView.frame.size.width, _WebKitParentView.frame.size.height)];
	
	[_WebKitParentView addSubview:_PrivacyURLWebView];
	
	NSURLRequest *req = [NSURLRequest requestWithURL:_consentInfo.privacyPolicyURL];
	if (req){
		[_PrivacyURLWebView loadRequest:req];
	}
}

- (IBAction)backButtonPressed:(UIButton *)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)consentSwitchToggled:(UISwitch *)consentSwitch {
	_consentInfo.consented = consentSwitch.on;
}

@end
