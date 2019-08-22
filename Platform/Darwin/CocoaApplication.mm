#include "CocoaApplication.h"
#include <string.h>

#import "AppDelegate.h"
#import "WindowDelegate.h"

#import <Carbon/Carbon.h>

using namespace newbieGE;

int CocoaApplication::Initialize() {
    int result = 0;

    [NSApplication sharedApplication];

    // Menu
    NSString *appName = [NSString stringWithFormat:@"%s", m_Config.appName];
    id menubar        = [[NSMenu alloc] initWithTitle:appName];
    id appMenuItem    = [NSMenuItem new];
    [menubar addItem:appMenuItem];
    [NSApp setMainMenu:menubar];

    id appMenu      = [NSMenu new];
    id quitMenuItem = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];
    [appMenu addItem:quitMenuItem];
    [appMenuItem setSubmenu:appMenu];

    id appDelegate = [AppDelegate new];
    [NSApp setDelegate:appDelegate];
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp finishLaunching];

    NSInteger style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable |
                      NSWindowStyleMaskBorderless;  // | NSWindowStyleMaskResizable;

    m_pWindow = [[NSWindow alloc] initWithContentRect:CGRectMake(0, 0, m_Config.screenWidth, m_Config.screenHeight)
                                            styleMask:style
                                              backing:NSBackingStoreBuffered
                                                defer:NO];
    [m_pWindow setTitle:appName];
    [m_pWindow makeKeyAndOrderFront:nil];
    id winDelegate = [WindowDelegate new];
    [m_pWindow setDelegate:winDelegate];

    return result;
}

void CocoaApplication::Finalize() {
    //    [m_pWindow release];
    m_pWindow = nil;
}

void CocoaApplication::Tick() {
    BaseApplication::Tick();
    // Process all pending events or return immidiately if no event
    while (NSEvent *event = [NSApp nextEventMatchingMask:NSEventMaskAny
                                               untilDate:nil
                                                  inMode:NSDefaultRunLoopMode
                                                 dequeue:YES]) {
        switch ([(NSEvent *)event type]) {
            case NSEventTypeKeyUp:
                NSLog(@"[CocoaApp] Key Up Event Received!");
                if ([event modifierFlags] & NSEventModifierFlagNumericPad) {
                    // arrow keys
                    NSString *theArrow = [event charactersIgnoringModifiers];
                    unichar keyChar    = 0;
                    if ([theArrow length] == 1) {
                        keyChar = [theArrow characterAtIndex:0];
                        if (keyChar == NSLeftArrowFunctionKey) {
                            g_pInputManager->LeftArrowKeyUp();
                            break;
                        }
                        if (keyChar == NSRightArrowFunctionKey) {
                            g_pInputManager->RightArrowKeyUp();
                            break;
                        }
                        if (keyChar == NSUpArrowFunctionKey) {
                            g_pInputManager->UpArrowKeyUp();
                            break;
                        }
                        if (keyChar == NSDownArrowFunctionKey) {
                            g_pInputManager->DownArrowKeyUp();
                            break;
                        }
                    }
                } else {
                    switch ([event keyCode]) {
                        case kVK_ANSI_D:  // d key
                            g_pInputManager->AsciiKeyUp('d');
                            break;
                        case kVK_ANSI_R:  // r key
                            g_pInputManager->AsciiKeyUp('r');
                            break;
                        case kVK_ANSI_U:  // u key
                            g_pInputManager->AsciiKeyUp('u');
                            break;
                    }
                }
                break;
            case NSEventTypeKeyDown:
                NSLog(@"[CocoaApp] Key Down Event Received!");
                if ([event modifierFlags] & NSEventModifierFlagNumericPad) {
                    // arrow keys
                    NSString *theArrow = [event charactersIgnoringModifiers];
                    unichar keyChar    = 0;
                    if ([theArrow length] == 1) {
                        keyChar = [theArrow characterAtIndex:0];
                        if (keyChar == NSLeftArrowFunctionKey) {
                            g_pInputManager->LeftArrowKeyDown();
                            break;
                        }
                        if (keyChar == NSRightArrowFunctionKey) {
                            g_pInputManager->RightArrowKeyDown();
                            break;
                        }
                        if (keyChar == NSUpArrowFunctionKey) {
                            g_pInputManager->UpArrowKeyDown();
                            break;
                        }
                        if (keyChar == NSDownArrowFunctionKey) {
                            g_pInputManager->DownArrowKeyDown();
                            break;
                        }
                    }
                } else {
                    switch ([event keyCode]) {
                        case kVK_ANSI_D:  // d key
                            g_pInputManager->AsciiKeyDown('d');
                            break;
                        case kVK_ANSI_R:  // r key
                            g_pInputManager->AsciiKeyDown('r');
                            break;
                        case kVK_ANSI_U:  // u key
                            g_pInputManager->AsciiKeyDown('u');
                            break;
                        case kVK_ANSI_Q:
                            m_bQuit = true;
                            break;
                    }
                }
                break;
            default:
                break;
        }
        [NSApp sendEvent:event];
        [NSApp updateWindows];
        //        [event release];
    }
}
