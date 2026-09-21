#include "Viewer.hpp"
#include <OSD.hxx>
#include <peel/Gio/ApplicationFlags.h>
#include <peel/Gtk/Gtk.h>

using namespace peel;
using namespace Gtk4::Occt8;

static void build_ui(Gio::Application *application) {
    auto app = application->cast<Gtk::Application>();
    auto window = Gtk::ApplicationWindow::create(app);
    auto viewer = Viewer::create(false, true);

    // viewer->print_gl_info(true);

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
