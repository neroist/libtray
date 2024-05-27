#include <Cocoa/Cocoa.h>
#include "tray.h"

static int loop_status = 0;
static struct tray *tray_instance;
static NSApplication* app;
static NSStatusBar* statusBar;
static NSStatusItem* statusItem;

@interface MenuDelegate: NSObject <NSMenuDelegate>
- (void)menuWillOpen:(NSMenu *)menu;
@end
@implementation MenuDelegate{}
    - (void)menuWillOpen:(NSMenu *)menu
    {
        if (menu == [statusItem menu] && (int)[[NSApp currentEvent] buttonNumber] == 0) {
            if (tray_instance->cb != NULL) {
                [menu cancelTracking];
                tray_instance->cb(tray_instance);
            }
        }
    }
    - (void)menuDidClose:(NSMenu *)menu
    {
        id representedObject = menu.highlightedItem.representedObject;
        struct tray_menu_item *pTrayMenu = [representedObject pointerValue];
        if (pTrayMenu != NULL && pTrayMenu->cb != NULL) {
            pTrayMenu->cb(pTrayMenu);
        }
    }
@end

static MenuDelegate* menuDelegate;

static NSMenu* nativeMenu(struct tray_menu_item *m) {
    NSMenu* menu = [[NSMenu alloc] init];
    [menu setAutoenablesItems:FALSE];
    [menu setDelegate:menuDelegate];

    for (; m != NULL && m->text != NULL; m++) {
        if (strcmp(m->text, "-") == 0) {
            [menu addItem:[NSMenuItem separatorItem]];
        } else {
            NSMenuItem* menuItem = [[NSMenuItem alloc]
                initWithTitle:[NSString stringWithUTF8String:m->text]
                action:nil
                keyEquivalent:@""];
            [menuItem setEnabled:m->disabled == 0 ? TRUE : FALSE];
            [menuItem setState:m->checked == 1 ? TRUE : FALSE];
            [menuItem setRepresentedObject:[NSValue valueWithPointer:m]];
            [menu addItem:menuItem];
            if (m->submenu != NULL) {
                [menu setSubmenu:nativeMenu(m->submenu) forItem:menuItem];
            }
        }
    }
    return menu;
}

struct tray * tray_get_instance() {
  return tray_instance;
}

int tray_init(struct tray *tray) {
    menuDelegate = [[MenuDelegate alloc] init];
    app = [NSApplication sharedApplication];
    statusBar = [NSStatusBar systemStatusBar];
    statusItem = [statusBar statusItemWithLength:NSVariableStatusItemLength];
    tray_update(tray);
    return 0;
}

int tray_loop(int blocking) {
    NSDate* until = (blocking ? [NSDate distantFuture] : [NSDate distantPast]);
    NSEvent* event = [app nextEventMatchingMask:ULONG_MAX untilDate:until
                                         inMode:[NSString stringWithUTF8String:"kCFRunLoopDefaultMode"] dequeue:TRUE];
    if (event) {
        [app sendEvent:event];
    }
    return loop_status;
}

void tray_update(struct tray *tray) {
    tray_instance = tray;
    double iconHeight = [[NSStatusBar systemStatusBar] thickness];
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithUTF8String:tray_instance->icon_filepath]];
    double width = image.size.width * (iconHeight / image.size.height);
    [image setSize:NSMakeSize(width, iconHeight)];
    statusItem.button.image = image;
    if (tray->tooltip != NULL) {
        statusItem.button.toolTip = [NSString stringWithUTF8String:tray->tooltip];
    }
    [statusItem setMenu:nativeMenu(tray->menu)];
}

void tray_exit(void) { loop_status = -1; }
