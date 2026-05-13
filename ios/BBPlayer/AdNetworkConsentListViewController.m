//
//  ConsentNetworkListViewController.m
//  BBPlayer
//
//  Created by armen on 11/19/19.
//

//#import "AdIntegratorManager.h"

#import "AdNetworkConsentManager.h"

#import "AdNetworkConsentDetailViewController.h"
#import "AdNetworkConsentListViewController.h"
#import "AdNetworkConsentListTableViewCell.h"


@interface AdNetworkConsentListViewController () <UITableViewDataSource, UITableViewDelegate, AdNetworkConsentManagerDownloadDelegate>
@end

@implementation AdNetworkConsentListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[AdNetworkConsentManager sharedManager].downloadDelegate = self;
	
	_NetworkListView.dataSource = self;
	_NetworkListView.delegate = self;
}

#pragma mark Done
- (IBAction)consentSelectionDone:(UIButton *)doneButton
{
	[[AdNetworkConsentManager sharedManager] usePerNetworkConsentSettingForAll];
	[self dismissViewControllerAnimated:YES completion:^{
		[self.delegate close];
	}];
}

#pragma mark row selection
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	AdNetworkConsentDetailViewController* vvc = [[UIStoryboard storyboardWithName:@"Main" bundle:NSBundle.mainBundle]
									  instantiateViewControllerWithIdentifier:@"NetworkConsentDetailViewController"];
	vvc.consentInfo = [AdNetworkConsentManager sharedManager].networkConsentInfoArray[indexPath.item];
	[self presentViewController:vvc animated:YES completion:nil];
}

#pragma mark data source delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [AdNetworkConsentManager sharedManager].networkConsentInfoArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	AdNetworkConsentListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NetworkInfoCell"];
	
	__block AdNetworkConsentInformation *info = [AdNetworkConsentManager sharedManager].networkConsentInfoArray[indexPath.item];
	if (!info){
		NSLog(@"no network info for index path: %@", indexPath);
		return nil;
	}
	
    if (info.displayName){
        cell.networkNameField.text = info.displayName;
    }
	else {
		NSLog(@"network name not specified: %@", info);
		if (info.networkId){
			cell.networkNameField.text = info.networkId;
		}
		else {
			NSLog(@"network id not specified (how did it even get this far????): %@", info);
			return nil;
		}
	}
	
	if (info.iconURL)
	{
		NSURLSessionDataTask *session = [[NSURLSession sharedSession]
										 dataTaskWithURL:info.iconURL
										 completionHandler:^(	NSData * _Nullable data,
																NSURLResponse * _Nullable response,
																NSError * _Nullable error)
		{
			if (error != noErr){
				NSLog(@"error downloading icon from URL: %@", info.iconURL);
				return;
			}
			cell.networkIcon.image = [UIImage imageWithData:data];
		}];
		[session resume];
	}
	
	return cell;
}

#pragma mark ad network download completed protocol
-(void)networkInfoCompletedDownload
{
	[_NetworkListView reloadData];
}
@end
