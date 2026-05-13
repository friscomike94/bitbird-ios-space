//
//  GLKView+GameView.m
//  BBPlayer
//
//  Created by Nik Rudenko on 7/9/18.
//

#import "GLKView+GameView.h"

@implementation GLKView (GameView)
- (int) getWidth{
    CGSize bound = [self bounds].size;
    return (int)bound.width * self.contentScaleFactor;
}
- (int) getHeight{
    CGSize bound = [self bounds].size;
    return (int)bound.height * self.contentScaleFactor;
}
- (void) swapBuffers{
    
}
@end
