# Gtk Occt Viewer Widget
A drop in Gtk widget for the OpenCascade Technologies [OCCT](https://github.com/Open-Cascade-SAS/OCCT) viewer.

<img width="600"  alt="GTK OCCT Viewer Widget" src="https://github.com/user-attachments/assets/6edfad45-5d77-4489-bf21-e449007e4bc1" />

Requirements:
- OCCT v8+
- Gtk v4.12+
- [Peel](https://gitlab.gnome.org/bugaevc/peel) (Gtk C++ wrapper)
- Mesa 25.2+ (For Wayland compatibility)

## Building the widget
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


## Consuming the widget
The built library is a gobject widget, so it can be consumed as C or C++.

A minimal Peel C++ application example:
```cpp
#include <peel/Gio/ApplicationFlags.h>
#include <peel/Gtk/Gtk.h>

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
	// viewer->occ points to the OCCT API's:
	// {
    //     occ::handle<Aspect_NeutralWindow> win;
    //     occ::handle<V3d_Viewer> viewer;
    //     occ::handle<V3d_View> view;
    //     occ::handle<AIS_InteractiveContext> ctx;
    //     ViewController *ctrl;
    // }

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

## Quickstart development
For an automated development install of: 
- OS dependencies,
- OCCT, 
- the Viewer widget and 
- the example application

you can use the included installer script from the repository root
(for debian, arch and Windows MSYS2 UCRT):
```bash
source installer.sh
```

This will put you into an interactive installer prompt:
```
installer > install dependencies
installer > install peel
installer > install occt
installer > install viewer
installer > install example
installer > run
```

All resouces will be downloaded, built and installed locally in the project root's 
.clone, .build and .local folders.

These are development builds, and should not be used for production.

## Notes on X11 / Wayland contexts
### Wayland and Mesa versioning
OCCT viewer renders into an offscreen OpenGL framebuffer, but Wayland support for compatible 
buffering was only recently introduced with Mesa v25.2.
At time of writing (OCCT v8.01) Wayland rendering will fail on earlier Mesa verions.

Rolling release distros such as Arch Linux should already include the compatible Mesa version or later, 
but other distros may require additional repository sources such as `[release]-backports` on Debian.
Consult the documentation for your own Unix-like distribution.

### Run-time vs Compile-time paths for X11 / Wayland contexts
Most Unix-like distributions have a login option to switch between X11 or Wayland. 
When using Wayland, apps may fall back on XWayland mode for X11 compatibility.

Gtk is in the process of deprecating X11, and related functions are already marked as such in version 4.
It however remains desireable for apps to be compatible with both compositor paths for the forseeable future.

At the time of writing, switching between Wayland and X11 for OCCT is a compile-time option via it's 
`USE_XLIB` flag. It is not possible to make both code paths available to it's run-time.
Modern user expectations are however that applications will switch compositor contexts seamlessly,
which implies allowing both compositor paths from a single binary.

This widget has implemented compositor switching as a run-time option, but it awaits suitable upstream development
in OCCT to be practically usable in this way. Until then you will need to: 
- compile both Wayland and X11 OCCT libraries and distribute two versions of your app with desired links, or
- compile OCCT for X11 and use a XWayland fallback (while GTK still supports it).

