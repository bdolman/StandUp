//
//  HotKey.h
//  StandUp
//
//  Created by Ben Dolman on 11/17/15.
//  Copyright © 2015 Ben Dolman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void (^HotKeyBlock)(NSEvent*);

/// Do this in Objective-C because it's nigh unto impossible in Swift
@interface HotKey : NSObject

+ (void)registerRaiseHotKey:(HotKeyBlock)block;
+ (void)registerLowerHotKey:(HotKeyBlock)block;

@end
