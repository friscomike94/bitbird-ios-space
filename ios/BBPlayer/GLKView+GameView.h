//
//  GLKView+GameView.h
//  BBPlayer
//
//  Created by Nik Rudenko on 7/9/18.
//

#import <GLKit/GLKit.h>

@interface GLKView (GameView)
- (int) getWidth;
- (int) getHeight;
- (void) swapBuffers;
@end
