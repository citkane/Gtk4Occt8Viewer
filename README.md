# Gtk Occt Viewer Widget
A drop in Gtk widget for the OpenCascade Technologies OCCT viewer.

Requirements:
- OCCT v8+
- Gtk v4.12+
- [Peel](https://gitlab.gnome.org/bugaevc/peel) (Gtk C++ wrapper)
- Mesa 25.2+ (For Wayland compatibility)

## Build
Ensure that you have Gtk and OCCT installed and on your PATH.

Install Peel using Meson.
```bash
cd ~/YourWork
git clone https://gitlab.gnome.org/bugaevc/peel
cd peel

meson setup --buildtype=plain .build .
meson compile -C .build
meson install -C .build
```


Install the viewer using CMake
```bash
cd ~/YourWork
git clone https://github.com/citkane/Gtk4Occt8Viewer
cd Gtk4Occt8Viewer

cmake -S . -B .build -G Ninja
cmake --build .build
cmake --install .build
```


## Consume
The built library is a gobject widget, so can be consumed as C or C++.

A minimal Peel C++ application example:
```cpp
#include <peel/Gtk/Gtk.h>
#include <peel/Gio/ApplicationFlags.h>

#include <AIS_AnimationCamera.hxx>
#include <AIS_InteractiveContext.hxx>
#include <AIS_ViewCube.hxx>

#include <Viewer.hpp>

using namespace peel;
using namespace Gtk4;

static void build_ui(Gio::Application *application) {
    auto app = application->cast<Gtk::Application>();
    auto window = Gtk::ApplicationWindow::create(app);
    auto viewer = Occt8::Viewer::create();
	// viewer->occ points to the OCCT viewer API's

    window->set_child(std::move(viewer));
    window->set_default_size(800, 600);
    window->present();
}

int main(int argc, char **argv) {
    auto app = Gtk::Application::create("org.Gtk4.Occt8.Viewer",
                                        Gio::Application::Flags::DEFAULT_FLAGS);
    app->connect_activate(build_ui);
    return app->run(argc, argv);
}
```

See the example application in the .example folder for more guidance.

## Quickstart
For a fully automated install of OCCT, the Viewer widget and the example application
you can use the included installer script from the repository root for
(debian, arch, Windows MSYS2 UCRT):
```bash
source installer.sh
```

This will put you into an interactive prompt:
```
installer > install dependencies
installer > install peel
installer > install occt
installer > install viewer
installer > install example
installer > run
```

All resouces will be downloaded, built and installed locally in the root's 
.clone, .build and .local folders.

The OCCT build is a development build, and should not be used for production.

## Notes on Unix like X11 / Wayland switching
### Wayland and Mesa versioning
OCCT viewer renders into an offscreen OpenGL framebuffer, but Wayland support for 
compatible buffering was only recently introduced with Mesa v25.2.
At time of writing (OCCT v8.01) Wayland rendering will fail on earlier Mesa verions.

Rolling release distros such as Arch will already include the compatible Mesa version or later, 
but other distros such as Debian may require additional repositories such as [rel]-backports.
Consult the documentation for your own Unix like distribution.

### Run-time vs Compile-time paths for X11 / Wayland switching
Most Unix like distributions come with a login option to switch between X11 or Wayland. 
When running Wayland, apps may fall back on XWayland mode for compatibility.

Gtk is in the process of deprecating X11, and related functions are already marked as such in GTK4.
It however remains desireable for apps to be compatible with both compositor paths for the forseeable future.

At time of writing (OCCT v8.01) switching between Wayland / X11 is a compile-time option baked into 
the library's `USE_XLIB` flag. It is not possible to make available both the X11 and (Wayland) EGL code paths 
to the run-time.
Modern user expectations are however that a single compiled application source will cater for both 
compositors as a run-time option.

This widget has implemented compositor switching as a runtime decision, but awaits suitable upstream development
in OCCT for it to be effective. Until then you will need to compile for both Wayland and X11, and distribute
both versions of your app - or use a XWayland fallback while GTK still supports it.




