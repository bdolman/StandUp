//
//  HotKey.h
//  GeekDesk
//
//  Created by Ben Dolman on 11/17/15.
//  Copyright © 2015 Hit Labs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void (^HotKeyBlock)(NSEvent*);

@interface HotKey : NSObject

+ (void)registerRaiseHotKey:(HotKeyBlock)block;
+ (void)registerLowerHotKey:(HotKeyBlock)block;

@end
