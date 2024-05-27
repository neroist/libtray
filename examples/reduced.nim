# easier to read than example.nim

import std/os

import libtray

setCurrentDir(currentSourcePath().parentDir())

const
  icon1 = 
    when defined(windows):
      "./icons/icon.ico"
    elif defined(linux):
      "./icons/icon-24px.png"
    else:
      "./icons/icon.png"

  icon2 =
    when defined(windows):
      "./icons/icon2.ico"
    elif defined(linux):
      "./icons/icon2-24px.png"
    else:
      "./icons/icon2.png"

proc window_cb(_: ptr Tray) {.cdecl.} =
  echo "window cb: this is where you would make a window visible."

proc toggle_cb(item: ptr TrayMenuItem) {.cdecl.} =
  echo "toggle cb"

  item.checked = cint(not bool(item.checked))

  let tray = trayGetInstance()
  if not tray.isNil(): trayUpdate(tray)

proc hello_cb(item: ptr TrayMenuItem) {.cdecl.} =
  echo "hello cb: changing icon"

  let tray = trayGetInstance()

  if tray.isNil(): return

  if tray.iconFilepath == icon1:
    tray.iconFilepath = icon2
  else:
    tray.iconFilepath = icon1

  trayUpdate(tray)

proc quit_cb(_: ptr TrayMenuItem) {.cdecl.} =
  echo "quit cb"

  trayExit()

proc submenu_cb(item: ptr TrayMenuItem) {.cdecl.} =
  echo "submenu: clicked on ", item.text

let tray = initTray(
  iconFilepath = icon1,
  tooltip = "Tray",
  cb = window_cb,
  menus = [
    initTrayMenuItem(text = "Change Icon", cb = hello_cb),
    initTrayMenuItem(text = "Checked", checked = true, cb = toggle_cb),
    initTrayMenuItem(text = "Disabled", disabled = true),
    initTrayMenuItem(text = "-"),
    initTrayMenuItem(
      text = "Submenu",
      submenus = [
        initTrayMenuItem(text = "FIRST", cb = submenu_cb),
        initTrayMenuItem(text = "SECOND", cb = submenu_cb),
        initTrayMenuItem(text = "THIRD", cb = submenu_cb),
        initTrayMenuItem(text = "FOURTH", cb = submenu_cb)
      ]
    ),
    initTrayMenuItem(text = "-"),
    initTrayMenuItem(text = "Quit", cb = quit_cb)
  ]
)

if trayInit(addr tray) != 0:
  echo "Could not init libtray"
  quit 1

const blocking = 1

while trayLoop(blocking) == 0:
  if blocking != 1:
    sleep 100

  echo "iteration"
