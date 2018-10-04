//
//  HotKey.m
//  StandUp
//
//  Created by Ben Dolman on 11/17/15.
//  Copyright © 2015 Ben Dolman. All rights reserved.
//

#import "HotKey.h"
#import "DDHotKeyCenter.h"
#import <Carbon/Carbon.h>


@implementation HotKey

+ (void)registerRaiseHotKey:(HotKeyBlock)block {
    DDHotKey *hotKey = [DDHotKey hotKeyWithKeyCode:kVK_UpArrow
                                     modifierFlags:NSShiftKeyMask|NSCommandKeyMask
                                              task:block];
    [[DDHotKeyCenter sharedHotKeyCenter] registerHotKey:hotKey];
}

+ (void)registerLowerHotKey:(HotKeyBlock)block {
    DDHotKey *hotKey = [DDHotKey hotKeyWithKeyCode:kVK_DownArrow
                                     modifierFlags:NSShiftKeyMask|NSCommandKeyMask
                                              task:block];
    [[DDHotKeyCenter sharedHotKeyCenter] registerHotKey:hotKey];
}

@end
