when defined(useTrayDll):
  const trayLib* {.strdefine.} = 
    when defined(windows):
      "libtray.dll"
    elif defined(macosx):
      "libtray.dylib"
    else:
      "libtray.so(|.0)"

  {.pragma: trayproc, dynlib: trayLib.}

elif defined(useTrayStaticLib):
  const trayLib* {.strdefine.} = 
    when defined(vcc): #? Y windows
      "libtray.lib"
    else:
      "libtray.a"

  {.passL: trayLib.}
  {.pragma: trayproc.}

else:
  when defined(windows) or defined(trayWinapi):
    {.passC: "-DTRAY_WINAPI -DWIN32_LEAN_AND_MEAN -DNOMINMAX".}
    {.compile: "./trayc/tray_windows.c".}

  elif defined(linux) or defined(trayQt):
    {.passC: "-DQT_CORE_LIB  -DQT_GUI_LIB -DQT_NO_DEBUG -DQT_WIDGETS_LIB -DTRAY_EXPORTS -DTRAY_qt6=1 -Dtray_EXPORTS -isystem /usr/include/x86_64-linux-gnu/qt6/QtWidgets -isystem /usr/include/x86_64-linux-gnu/qt6 -isystem /usr/include/x86_64-linux-gnu/qt6/QtCore -isystem /usr/lib/x86_64-linux-gnu/qt6/mkspecs/linux-g++ -isystem /usr/include/x86_64-linux-gnu/qt6/QtGui -fPIC -fPIC".}
    {.passL: "-lQt6Widgets -lQt6Gui -lQt6Core -lGLX -lOpenGL".}
    {.compile: "./trayc/tray_linux.cpp".}
    {.compile: "./trayc/QtTrayMenu.cpp".}

  elif defined(macos) or defined(trayAppkit):
    {.passC: "-DTRAY_APPKIT".}
    {.compile: "./trayc/tray_darwin.m".}

  {.pragma: trayproc.}

type
  Tray* {.bycopy.} = object
    iconFilepath*: cstring
    tooltip*: cstring
    cb*: proc (tray: ptr Tray) {.cdecl.}
    menu*: ptr UncheckedArray[TrayMenuItem] # array

  TrayMenuItem* {.bycopy.} = object
    text*: cstring
    disabled*: cint
    checked*: cint
    cb*: proc (item: ptr TrayMenuItem) {.cdecl.}
    submenu*: ptr UncheckedArray[TrayMenuItem] # array

proc setMenus*(tray: var Tray, menus: openArray[TrayMenuItem]) =
  ## Safely set the menus of a tray. This proc adds the terminating NULL
  ## object at the end for you.
  
  if tray.menu != nil:
    dealloc(addr tray.menu)

  tray.menu = cast[ptr UncheckedArray[TrayMenuItem]](alloc0(sizeof(TrayMenuItem) * (menus.len + 1)))

  for idx, i in menus:
    tray.menu[idx] = i

  # tray.menu[menus.len] = TrayMenuItem()

proc setSubMenus*(trayItem: var TrayMenuItem, menus: openArray[TrayMenuItem]) =
  ## Safely set the submenus of a tray menu item. This proc adds the terminating
  ## NULL object at the end for you.

  if trayItem.submenu != nil:
    dealloc(addr trayItem.submenu)

  trayItem.submenu = cast[ptr UncheckedArray[TrayMenuItem]](alloc0(sizeof(TrayMenuItem) * (menus.len + 1)))
    
  for idx, i in menus:
    trayItem.submenu[idx] = i
  
  # trayItem.submenu[menus.len] = TrayMenuItem()

proc initTray*(
  iconFilepath: string = "",
  tooltip: string = "",
  cb: proc (tray: ptr Tray) {.cdecl.} = nil,
  menus: openArray[TrayMenuItem] = []
): Tray =
  ## Create new `Tray` object

  result = Tray(
    iconFilepath: cstring iconFilepath,
    tooltip: cstring tooltip,
    cb: cb
  )

  if menus.len > 0:
    result.setMenus(menus)

proc initTrayMenuItem*(
  text: string = "",
  disabled: bool = false,
  checked: bool = false,
  cb: proc (item: ptr TrayMenuItem) {.cdecl.} = nil,
  submenus: openArray[TrayMenuItem] = []
): TrayMenuItem =
  ## Create new `TrayMenuItem` object

  result = TrayMenuItem(
    text: cstring text,
    disabled: cint disabled,
    checked: cint checked,
    cb: cb
  )

  if submenus.len > 0:
    result.setSubMenus(submenus)

proc trayGetInstance*(): ptr Tray {.cdecl, importc: "tray_get_instance", trayproc.}
  ## Returns the tray instance.
proc trayInit*(tray: ptr Tray): cint {.cdecl, importc: "tray_init", trayproc.}
  ## Creates tray icon. Returns `-1` if tray icon/menu can't be created.
proc trayLoop*(blocking: cint): cint {.cdecl, importc: "tray_loop", trayproc.}
  ## Runs one iteration of the UI loop. Returns `-1` if `trayExit()`_ has been called.
proc trayUpdate*(tray: ptr Tray) {.cdecl, importc: "tray_update", trayproc.}
  ## Updates tray icon and menu.
proc trayExit*() {.cdecl, importc: "tray_exit", trayproc.}
  ## Terminates UI loop.
