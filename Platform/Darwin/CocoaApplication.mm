#ifdef __OBJC__
#import "AppDelegate.h"
#import "WindowDelegate.h"

#import <Carbon/Carbon.h>
#endif

#include <string.h>
#include "CocoaApplication.h"
#include "InputManager.hpp"

using namespace newbieGE;

#ifdef __OBJC__
NSWindow *CocoaApplication::GetWindowRef() {
    return (__bridge NSWindow *)m_pWindow;
}

NSWindow *CocoaApplication::GetWindow() {
    return (__bridge_transfer NSWindow *)m_pWindow;
}

void CocoaApplication::SetWindow(NSWindow *wind) {
    m_pWindow = (__bridge_retained void *)wind;
}
#endif

void *CocoaApplication::GetMainWindowHandler() {
    return m_pWindow;
}

void CocoaApplication::CreateMainWindow() {
#ifdef __OBJC__
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

    NSWindow *m_pWindowTmp = [[NSWindow alloc] initWithContentRect:CGRectMake(0, 0, m_Config.screenWidth, m_Config.screenHeight)
                                                         styleMask:style
                                                           backing:NSBackingStoreBuffered
                                                             defer:NO];
    [m_pWindowTmp setTitle:appName];
    [m_pWindowTmp makeKeyAndOrderFront:nil];
    id winDelegate = [WindowDelegate new];
    [m_pWindowTmp setDelegate:winDelegate];

    SetWindow(m_pWindowTmp);
#endif
}

void CocoaApplication::Finalize() {
#ifdef __OBJC__
    // [m_pWindow release];
    // m_pWindow = nil;
    NSWindow *m_pWindowTmp = GetWindow();
    m_pWindowTmp           = nil;
#endif
    BaseApplication::Finalize();
}

void CocoaApplication::Tick() {
#ifdef __OBJC__
    // Process all pending events or return immidiately if no event
    if (NSEvent *event = [NSApp nextEventMatchingMask:NSEventMaskAny
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
                        case kVK_ANSI_W:  // w key
                            g_pInputManager->AsciiKeyUp('w');
                            break;
                        case kVK_ANSI_S:  // s key
                            g_pInputManager->AsciiKeyUp('s');
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
                        case kVK_ANSI_W:  // w key
                            g_pInputManager->AsciiKeyDown('w');
                            break;
                        case kVK_ANSI_S:  // s key
                            g_pInputManager->AsciiKeyDown('s');
                            break;
                        case kVK_ANSI_Q:
                            RequestQuit();
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
#endif
}
