//
//  ConsentNetworkListViewController.h
//  BBPlayer
//
//  Created by armen on 11/19/19.
//

#import <UIKit/UIKit.h>

@class AdNetworkConsentDialogViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol AdNetworkConsentListParentDelegate <NSObject>
-(void)close;
@end

@interface AdNetworkConsentListViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITableView *NetworkListView;
@property (nonatomic, weak) id <AdNetworkConsentListParentDelegate> delegate;
-(void)networkInfoCompletedDownload;
@end

NS_ASSUME_NONNULL_END
