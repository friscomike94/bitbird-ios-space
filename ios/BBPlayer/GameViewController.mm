//
//  GameViewController.m
//  BBPlayer
//
//  Created by Nik Rudenko on 9/12/17.
//
//

#import "GameViewController.h"
#import <OpenGLES/ES2/glext.h>
#import "PTModelController.h"
#import "PTModelGeneralSettings.h"
#import "PTPAppDelegate.h"
#import "cocos2d.h"
#import "PTPConfig.h"
#import "AdNetworkConsentManager.h"

#include "PTPSettingsController.h"
#include "AdIntegratorManager.h"

#define IOS_MAX_TOUCHES_COUNT     10

static PTPAppDelegate s_sharedApplication;

@interface GameViewController () {
    NSString* shareMessage;
    bool sheduledForShareWidget;
	bool consentDialogShown;
}
@property (strong, nonatomic) EAGLContext *context;

@end

@implementation GameViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	consentDialogShown = false;
    
    sheduledForShareWidget = false;
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    [view setMultipleTouchEnabled: YES];
    
    [self setPreferredFramesPerSecond:60];
    [EAGLContext setCurrentContext:self.context];
    
    PTModelController *mc = PTModelController::shared();
    mc->clean();
    
    ssize_t size = 0;
    char* pBuffer = (char*)CCFileUtils::sharedFileUtils()->getFileData("data/data.pkg", "rb", &size);
    if (pBuffer != NULL && size > 0){
        mc->setUsingDataEncryption( true );
    }
    
    mc->loadDataForSplashScreen("data/data.pkg", processor().c_str());
    
    s_sharedApplication.setDataArchiveProcessor(processor());
    
    cocos2d::GLView *glview = cocos2d::GLViewImpl::createWithEAGLView((__bridge void *)view);
    cocos2d::Director::getInstance()->setOpenGLView(glview);
    cocos2d::FileUtils::getInstance()->addSearchPath( "data" );
	cocos2d::Application::getInstance()->run();
}


-(void)viewDidAppear:(BOOL)animated
{
	if (!consentDialogShown){
		[[AdNetworkConsentManager sharedManager] presentConsentDialogWithViewController:self];
		consentDialogShown = YES;
	}
}


- (void)dealloc{
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    cocos2d::Director::getInstance()->setViewport();
    cocos2d::Director::getInstance()->mainLoop();
}


- (void)update{
    if(sheduledForShareWidget == true){
        sheduledForShareWidget = false;
        
        GLKView *view  = (GLKView *)self.view;
        UIImage* screenshot = view.snapshot;
        
        PTLog("Opens Share Widget: screenshot was taken");
        
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[shareMessage, screenshot] applicationActivities:nil];
        
        NSArray *excludeActivities = @[UIActivityTypeSaveToCameraRoll,
                                       UIActivityTypeAssignToContact];
        activityVC.excludedActivityTypes = excludeActivities;
        
        
        float iOSVersion = [[UIDevice currentDevice].systemVersion floatValue];
        if(iOSVersion > 8.0){
            activityVC.popoverPresentationController.sourceView = self.view;
        }
        
        [self presentViewController:activityVC animated:YES completion:nil];
        PTLog("opens Share Widget: view controller presented");
    }
}

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures{
    return UIRectEdgeTop | UIRectEdgeLeft | UIRectEdgeRight;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event{
    UITouch* ids[IOS_MAX_TOUCHES_COUNT] = {0};
    float xs[IOS_MAX_TOUCHES_COUNT] = {0.0f};
    float ys[IOS_MAX_TOUCHES_COUNT] = {0.0f};
    
    int i = 0;
    for (UITouch *touch in touches) {
        ids[i] = touch;
        xs[i] = [touch locationInView: [touch view]].x * self.view.contentScaleFactor;
        ys[i] = [touch locationInView: [touch view]].y * self.view.contentScaleFactor;
        ++i;
    }
    auto glview = cocos2d::Director::getInstance()->getOpenGLView();
    glview->handleTouchesBegin(i, (intptr_t*)ids, xs, ys);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event{
    UITouch* ids[IOS_MAX_TOUCHES_COUNT] = {0};
    float xs[IOS_MAX_TOUCHES_COUNT] = {0.0f};
    float ys[IOS_MAX_TOUCHES_COUNT] = {0.0f};
    float fs[IOS_MAX_TOUCHES_COUNT] = {0.0f};
    float ms[IOS_MAX_TOUCHES_COUNT] = {0.0f};
    
    int i = 0;
    for (UITouch *touch in touches) {
        ids[i] = touch;
        xs[i] = [touch locationInView: [touch view]].x * self.view.contentScaleFactor;;
        ys[i] = [touch locationInView: [touch view]].y * self.view.contentScaleFactor;;
#if defined(__IPHONE_9_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0)
        // running on iOS 9.0 or higher version
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0f) {
            fs[i] = touch.force;
            ms[i] = touch.maximumPossibleForce;
        }
#endif
        ++i;
    }
    auto glview = cocos2d::Director::getInstance()->getOpenGLView();
    glview->handleTouchesMove(i, (intptr_t*)ids, xs, ys, fs, ms);
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event{
    UITouch* ids[IOS_MAX_TOUCHES_COUNT] = {0};
    float xs[IOS_MAX_TOUCHES_COUNT] = {0.0f};
    float ys[IOS_MAX_TOUCHES_COUNT] = {0.0f};
    
    int i = 0;
    for (UITouch *touch in touches) {
        ids[i] = touch;
        xs[i] = [touch locationInView: [touch view]].x * self.view.contentScaleFactor;;
        ys[i] = [touch locationInView: [touch view]].y * self.view.contentScaleFactor;;
        ++i;
    }
    auto glview = cocos2d::Director::getInstance()->getOpenGLView();
    glview->handleTouchesEnd(i, (intptr_t*)ids, xs, ys);
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event{
    UITouch* ids[IOS_MAX_TOUCHES_COUNT] = {0};
    float xs[IOS_MAX_TOUCHES_COUNT] = {0.0f};
    float ys[IOS_MAX_TOUCHES_COUNT] = {0.0f};
    
    int i = 0;
    for (UITouch *touch in touches) {
        ids[i] = touch;
        xs[i] = [touch locationInView: [touch view]].x * self.view.contentScaleFactor;;
        ys[i] = [touch locationInView: [touch view]].y * self.view.contentScaleFactor;;
        ++i;
    }
    auto glview = cocos2d::Director::getInstance()->getOpenGLView();
    glview->handleTouchesCancel(i, (intptr_t*)ids, xs, ys);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    PTModelGeneralSettingsPtr generalSettings = PTModelGeneralSettings::shared();
    if(generalSettings->orientation() == PTModelGeneralSettings::LandscapeOrientation){
        return UIInterfaceOrientationIsLandscape( interfaceOrientation );
    }
    else if(generalSettings->orientation() == PTModelGeneralSettings::PortraitOrientation){
        return UIInterfaceOrientationIsPortrait( interfaceOrientation );
    }
    
    return NO;
}

- (NSUInteger) supportedInterfaceOrientations{
    PTModelGeneralSettingsPtr generalSettings = PTModelGeneralSettings::shared();
    if(generalSettings->orientation() == PTModelGeneralSettings::LandscapeOrientation){
        return UIInterfaceOrientationMaskLandscape;
        
    }
    else if(generalSettings->orientation() == PTModelGeneralSettings::PortraitOrientation){
        return UIInterfaceOrientationMaskPortrait;
    }
    
    return NO;
}

- (BOOL) shouldAutorotate {
    return NO;
}

-(void) scheduleOpenShareWidget:(const char*) message{
    shareMessage = [[NSString stringWithUTF8String:message] copy];
    sheduledForShareWidget = true;
}

@end
