//
//  HotKey.m
//  StandUp
//
//  Created by Ben Dolman on 11/17/15.
//  Copyright © 2015 Ben Dolman. All rights reserved.
//

#import "HotKey.h"
#import <Carbon/Carbon.h>


@implementation HotKey

+ (DDHotKey *)registerPresetHotKey:(int)presetNumber block:(HotKeyBlock)block {
    unsigned short keyCode;
    switch (presetNumber) {
        case 1:
            keyCode = kVK_ANSI_1;
            break;
        case 2:
            keyCode = kVK_ANSI_2;
            break;
        case 3:
            keyCode = kVK_ANSI_3;
            break;
        case 4:
            keyCode = kVK_ANSI_4;
            break;
        case 5:
            keyCode = kVK_ANSI_5;
            break;
        case 6:
            keyCode = kVK_ANSI_6;
            break;
        case 7:
            keyCode = kVK_ANSI_7;
            break;
        case 8:
            keyCode = kVK_ANSI_8;
            break;
        case 9:
            keyCode = kVK_ANSI_9;
            break;
        default:
            return nil;
    }
    DDHotKey *hotKey = [DDHotKey hotKeyWithKeyCode:keyCode
                                     modifierFlags:NSShiftKeyMask|NSControlKeyMask
                                              task:block];
    [[DDHotKeyCenter sharedHotKeyCenter] registerHotKey:hotKey];
    return hotKey;
}

+ (DDHotKey *)registerRaiseHotKey:(HotKeyBlock)block {
    DDHotKey *hotKey = [DDHotKey hotKeyWithKeyCode:kVK_UpArrow
                                     modifierFlags:NSShiftKeyMask|NSCommandKeyMask
                                              task:block];
    [[DDHotKeyCenter sharedHotKeyCenter] registerHotKey:hotKey];
    return hotKey;
}

+ (DDHotKey *)registerLowerHotKey:(HotKeyBlock)block {
    DDHotKey *hotKey = [DDHotKey hotKeyWithKeyCode:kVK_DownArrow
                                     modifierFlags:NSShiftKeyMask|NSCommandKeyMask
                                              task:block];
    [[DDHotKeyCenter sharedHotKeyCenter] registerHotKey:hotKey];
    return hotKey;
}

@end
