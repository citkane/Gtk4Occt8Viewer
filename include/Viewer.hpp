#ifndef GTK4_OCCT8_VIEWER_H
#define GTK4_OCCT8_VIEWER_H

#include "ViewController.hpp"

#include <AIS_ViewCube.hxx>
#include <Aspect_Drawable.hxx>
#include <Aspect_NeutralWindow.hxx>
#include <Message.hxx>
#include <OpenGl_GraphicDriver.hxx>
#include <V3d_View.hxx>
#include <V3d_Viewer.hxx>

#include <peel/GLib/ErrorType.h>
#include <peel/Gdk/GLAPI.h>
#include <peel/Gtk/Gtk.h>
#include <peel/class.h>

namespace Gtk4 {
namespace Occt8 {
using namespace peel;

using Vec2i = NCollection_Vec2<int>;
using Vec2d = NCollection_Vec2<double>;
using VKeyFlags = Aspect_VKeyFlags;
using VKeyMouse = Aspect_VKeyMouse;
using RenderingContext = Aspect_RenderingContext;

class Viewer final : public Gtk::GLArea {
    // Peel custom GObject class
    // @see
    // https://bugaevc.pages.gitlab.gnome.org/peel/custom-gobject-classes.html
    PEEL_SIMPLE_CLASS(Viewer, GLArea);
    friend class ViewController;

  public:
    /**
     * @brief Create a GObject of the Gtk4Occt8Viewer widget
     * @param print_gl Print OpenGL diagnostics to the console
     * @param verbose_gl Use verbose OpenGL diagnostics
     * */
    static FloatPtr<Viewer> create(bool print_gl = false,
                                   bool verbose_gl = false);
    void print_gl_info(bool verbose);
    void set_default_scene();

    struct OCC {
        Handle(Aspect_NeutralWindow) win;
        Handle(V3d_Viewer) viewer;
        Handle(V3d_View) view;
        Handle(AIS_InteractiveContext) ctx;
        // @TODO - how to get a Handle on ViewController?
        ViewController *ctrl;
    } occ;

  private:
    void init_driver();
    void init_viewer();
    void init_ctx();
    void wrap_gl_fbo();
    void init_window(int gtk_w, int gtk_h, float gtk_r);
    void set_pixel_ratio(int gtk_w, float gtk_r);
    void register_input();
    void init_native_win();
    void init_egl_ctx();
    void divert_occ_printer();

    struct {
        Handle(Aspect_DisplayConnection) disp;
        Handle(OpenGl_FrameBuffer) fbo;
        Handle(OpenGl_Context) ctx;
        Handle(OpenGl_GraphicDriver) driver;
    } gl;

    Aspect_Drawable win_native;
    bool is_realised;
    float prev_pix_r;
    float occ_pix_r;

    // =============================
    // peel GObject intitialiser
    // =============================
    void init(Class *);
    template <typename F> static void define_properties(F &f);
    // Members for peel GObject constructor params
    PEEL_PROPERTY(bool, print_gl, "print-gl")
    PEEL_PROPERTY(bool, verbose_gl, "verbose-gl")
    bool print_gl;
    bool verbose_gl;
    bool get_print_gl() const;
    bool get_verbose_gl() const;
    void set_print_gl(bool value);
    void set_verbose_gl(bool value);
};

// ====================================================
// Divert OCCT messages to GObject logger
// ====================================================
using AsciiString = TCollection_AsciiString;
using Gravity = Message_Gravity;
class ViewerPrinter : public Message_Printer {
    DEFINE_STANDARD_RTTIEXT(ViewerPrinter, Message_Printer)

  protected:
    void send(const AsciiString &mssg, const Gravity gravity) const override {
        const char *mssg_string = mssg.ToCString();

        switch (gravity) {
        case Message_Info:
            g_info("%s", mssg_string);
            break;
        case Message_Warning:
            g_warning("%s", mssg_string);
            break;
        case Message_Alarm:
            g_critical("%s", mssg_string);
            break;
        case Message_Fail:
            g_error("%s", mssg_string);
            break;
        case Message_Trace:
            g_debug("%s", mssg_string);
        }
    }
};
DEFINE_STANDARD_HANDLE(ViewerPrinter, Message_Printer)

} // namespace Occt8
} // namespace Gtk4

// ====================================================
// Macros to switch between Wayland / x11 contexts
// ====================================================

#define CHECK_ENV_VAL(key, val)                                                \
    ([&]() -> bool {                                                           \
        const char *result = std::getenv(key);                                 \
        return result != nullptr && std::strcmp(result, val) == 0;             \
    }())

#define RUN_X11                                                                \
    ([]() -> bool {                                                            \
        if ((!USE_MACX11 && !IS_NIX) || USE_GLES)                              \
            return 0;                                                          \
                                                                               \
        return CHECK_ENV_VAL("GDK_BACKEND", "x11") ||                          \
               CHECK_ENV_VAL("XDG_SESSION_TYPE", "x11");                       \
    }())

#define RUN_WAYLAND                                                            \
    ([]() -> bool {                                                            \
        if (!IS_NIX || RUN_X11)                                                \
            return 0;                                                          \
                                                                               \
        return CHECK_ENV_VAL("GDK_BACKEND", "wayland") ||                      \
               CHECK_ENV_VAL("XDG_SESSION_TYPE", "wayland");                   \
    }())

#endif // #ifndef GTK4_OCCT8_VIEWER_H
