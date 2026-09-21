#include "Viewer.hpp"
#include <GL/glx.h>
#include <gdk/x11/gdkx.h>

using namespace Gtk4::Occt8;

void Viewer::init_x11_win() {
    g_message("init_x11_win");
    auto surf_gdk = (GdkSurface *)get_native()->get_surface();
    // Deprecated gdk method with no alternative. GTK is phasing out X11
    win_native = gdk_x11_surface_get_xid(surf_gdk);

    GLXDrawable surf_glx = glXGetCurrentDrawable();
    Display *disp_glx = glXGetCurrentDisplay();
    GLXContext ctx_glx = glXGetCurrentContext();

    auto needs_rebind = disp_glx == nullptr || ctx_glx == 0 ||
                        surf_glx != GLXDrawable(win_native);
    g_debug("x11 window %s",
            needs_rebind ? "needs rebind" : "does not need rebind");

    auto ack = !needs_rebind ||
               glXMakeCurrent(disp_glx, (GLXDrawable)win_native, ctx_glx);
    if (win_native == 0 || !ack)
        g_error("Failed to initialise the x11 window");

    if (needs_rebind)
        make_current();
}
