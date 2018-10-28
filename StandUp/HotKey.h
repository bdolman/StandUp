//
//  HotKey.h
//  StandUp
//
//  Created by Ben Dolman on 11/17/15.
//  Copyright © 2015 Ben Dolman. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DDHotKeyCenter.h"

typedef void (^HotKeyBlock)(NSEvent*);

/// Do this in Objective-C because it's nigh unto impossible in Swift
@interface HotKey : NSObject

+ (DDHotKey *)registerPresetHotKey:(int32_t)presetNumber block:(HotKeyBlock)block;
+ (DDHotKey *)registerRaiseHotKey:(HotKeyBlock)block;
+ (DDHotKey *)registerLowerHotKey:(HotKeyBlock)block;

@end
