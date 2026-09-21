#include "Viewer.hpp"
#include <EGL/egl.h>

using namespace Gtk4::Occt8;
void Viewer::init_egl_ctx() {

  EGLSurface surface_egl = eglGetCurrentSurface(EGL_DRAW);
  EGLDisplay display_egl = eglGetCurrentDisplay();
  EGLContext ctx_egl = eglGetCurrentContext();

  void *cfg_egl = nullptr;
  EGLint cfgid_egl = 0, no_configs = 0;
  const EGLint aConfigAttribs[] = {EGL_CONFIG_ID, cfgid_egl, EGL_NONE};

  eglQuerySurface(display_egl, surface_egl, EGL_CONFIG_ID, &cfgid_egl);
  eglChooseConfig(display_egl, aConfigAttribs, &cfg_egl, 1, &no_configs);

  if (!gl.driver->InitEglContext(display_egl, ctx_egl, cfg_egl))
    g_error("Failed to initialise EGL context");
}
