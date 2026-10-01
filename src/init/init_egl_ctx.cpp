#include "Viewer.hpp"
#include <EGL/egl.h>

using namespace Gtk4::Occt8;
void Viewer::init_egl_ctx() {

    EGLSurface surface_egl = eglGetCurrentSurface(EGL_DRAW);
    EGLDisplay display_egl = eglGetCurrentDisplay();
    EGLContext ctx_egl = eglGetCurrentContext();

    if (display_egl == EGL_NO_DISPLAY)
        g_error("The GtkGLArea context is not an EGL context");

    g_print("EGL vendor:     %s\n", eglQueryString(display_egl, EGL_VENDOR));
    g_print("EGL version:    %s\n", eglQueryString(display_egl, EGL_VERSION));
    g_print("EGL client APIs: %s\n",
            eglQueryString(display_egl, EGL_CLIENT_APIS));
    g_print("EGL extensions:  %s\n",
            eglQueryString(display_egl, EGL_EXTENSIONS));
    g_print("EGL context: %p\n", (void *)ctx_egl);

    void *cfg_egl = nullptr;
    EGLint cfgid_egl = 0, no_configs = 0;
    const EGLint aConfigAttribs[] = {EGL_CONFIG_ID, cfgid_egl, EGL_NONE};

    eglQuerySurface(display_egl, surface_egl, EGL_CONFIG_ID, &cfgid_egl);
    eglChooseConfig(display_egl, aConfigAttribs, &cfg_egl, 1, &no_configs);

    if (!gl.driver->InitEglContext(display_egl, ctx_egl, cfg_egl))
        g_error("Failed to initialise EGL context");

    g_print("Initialised EGL context\n");
}
