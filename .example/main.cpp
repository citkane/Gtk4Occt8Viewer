#include "Viewer.hpp"
#include <AIS_AnimationCamera.hxx>
#include <AIS_InteractiveContext.hxx>
#include <AIS_ViewCube.hxx>
#include <Quantity_NameOfColor.hxx>
#include <Quantity_TypeOfColor.hxx>
#include <Standard_Version.hxx>

#include <peel/FloatPtr.h>
#include <peel/Gdk/Gdk.h>
#include <peel/Gio/ApplicationFlags.h>
#include <peel/Gtk/Adjustment.h>
#include <peel/Gtk/Gtk.h>
#include <peel/Gtk/Orientation.h>

using namespace peel;
using namespace Gtk4::Occt8;
using namespace Gtk;

// ============================================================
// Consumer application entry point
// ============================================================
static void build_ui(Gio::Application *application);
int main(int argc, char **argv) {
    auto app = Gtk::Application::create("org.Gtk4.Occt8.Viewer",
                                        Gio::Application::Flags::DEFAULT_FLAGS);
    app->connect_activate(build_ui);
    return app->run(argc, argv);
}

// ============================================================
// Assemble the Gtk UI
// ============================================================
static void append_ui_buttons(Box *app_box, Viewer *viewer);
static void append_ui_viewer(Box *app_box, Viewer *viewer);
static void append_ui_controller(Box *app_box, Viewer *viewer);
static void build_ui(Gio::Application *application) {
    auto app = application->cast<Application>();
    auto app_box = Box::create(Orientation::VERTICAL, 6);
    auto window = ApplicationWindow::create(app);
    auto viewer = Viewer::create();

    append_ui_buttons(app_box, viewer);
    append_ui_viewer(app_box, viewer);
    append_ui_controller(app_box, viewer);

    window->set_title("Gtk4::Occt8::Viewer example application");
    window->set_child(std::move(app_box));
    window->set_default_size(800, 600);
    window->present();
}

static void on_about_clicked(Button *bttn, Viewer *viewer);
static void on_quit_clicked(Gtk::Button *bttn);
static void toggle_scene_stats(Viewer *viewer);
static void append_ui_buttons(Box *app_box, Viewer *viewer) {
    auto about_bttn = Button::create_with_label("About");
    auto stats_bttn = Button::create_with_label("Stats");
    auto quit_bttn = Button::create_with_label("Quit");
    auto buttons = Box::create(Orientation::HORIZONTAL, 6);

    quit_bttn->connect_clicked(on_quit_clicked, false);
    stats_bttn->connect_clicked(
        [viewer](Button *) { toggle_scene_stats(viewer); }, false);
    about_bttn->connect_clicked(
        [viewer](Button *bttn) { on_about_clicked(bttn, viewer); }, false);

    buttons->set_hexpand(true);
    buttons->append(std::move(about_bttn));
    buttons->append(std::move(stats_bttn));
    buttons->append(std::move(quit_bttn));
    app_box->append(std::move(buttons));
}

static void append_ui_viewer(Box *app_box, Viewer *viewer) {
    viewer->set_hexpand(true);
    viewer->set_vexpand(true);
    viewer->set_default_scene();
    viewer->occ.view->SetBackgroundColor((Quantity_NameOfColor)0);
    app_box->append(viewer);
}

static void append_ui_controller(Box *app_box, Viewer *viewer) {
    auto adjustment = Adjustment::create(0.0, 0.0, 508.0, 1.0, 0.0, 0.0);
    auto slider = Scale::create(Orientation::HORIZONTAL, adjustment);
    slider->set_hexpand(true);
    slider->connect_change_value([viewer](Range *, ScrollType, double val) {
        if (val < 0 || val > 508)
            return false;

        auto occ = viewer->occ;
        auto colour = (Quantity_NameOfColor)val;
        occ.view->SetBackgroundColor(colour);
        occ.view->Invalidate();
        viewer->queue_render();
        return false;
    });

    app_box->append(std::move(slider));
}

// ============================================================
// Button click actions
// ============================================================
static void on_quit_clicked(Gtk::Button *bttn) {
    auto window = (Gtk::ApplicationWindow *)bttn->get_root();
    window->close();
}

static void toggle_scene_stats(Viewer *viewer) {
    using RP = Graphic3d_RenderingParams;
    using PC = RP::PerfCounters;
    auto occ = viewer->occ;
    auto stats = (PC)(RP::PerfCounters_FrameRate | RP::PerfCounters_Triangles);
    auto stats_shown = occ.view->RenderingParams().ToShowStats;
    if (!stats_shown) {
        occ.view->ChangeRenderingParams().ToShowStats = true;
        occ.view->ChangeRenderingParams().CollectedStats = stats;
    } else {
        occ.view->ChangeRenderingParams().ToShowStats = false;
    }
    occ.view->Invalidate();
    viewer->queue_render();
}

static void on_about_clicked(Button *bttn, Viewer *viewer) {
    auto window = (Gtk::ApplicationWindow *)bttn->get_root();
    auto ctx = viewer->get_context();

    auto flags = Gtk::Dialog::Flags::MODAL;
    auto type = Gtk::MessageType::INFO;
    auto bttn_type = Gtk::ButtonsType::CLOSE;
    auto v_maj = Gtk::get_major_version();
    auto v_min = Gtk::get_minor_version();
    auto v_mic = Gtk::get_micro_version();
    auto display = ctx->get_display()->get_type_name();
    auto colour = viewer->occ.view->BackgroundColor().Name();
    auto colour_name = Quantity_Color::StringName(colour);
    int gl_v_maj, gl_v_min;
    ctx->get_version(&gl_v_maj, &gl_v_min);
    auto api =
        ctx->get_api() == Gdk::GLAPI::GL ? "OpenGL Desktop" : "OpenGL ES";

    std::stringstream markup;
    markup << "<span font_family=\"monospace\">"
           << "OCCT 3d Viewer example embedded into GTK4 Widget.\n\n"
           << "OCCT:       v." OCC_VERSION_STRING_EXT "\n"
           << "GTK:        v." << v_maj << "." << v_min << "." << v_mic << "\n"
           << "GL:         v." << gl_v_maj << "." << gl_v_min << "\n"
           << "GL API:     " << api << "\n"
           << "Display:    " << display << "\n"
           << "Background: " << colour << " " << colour_name << "\n"
           << "</span>";

    auto dialog = MessageDialog::create(window, flags, type, bttn_type, "");
    dialog->set_title("About");
    dialog->set_markup(markup.str().c_str());
    dialog->connect_response([](Dialog *dialog, int) { dialog->close(); });
    dialog->show();
}
