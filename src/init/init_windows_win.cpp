#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#include "Viewer.hpp"

using namespace Gtk4::Occt8;
void Viewer::init_windows_win() {
    HDC wgl_ctx = wglGetCurrentDC();
    HWND wgl_win = WindowFromDC(wgl_ctx);
    win_native = (Aspect_Drawable)wgl_win;
}
