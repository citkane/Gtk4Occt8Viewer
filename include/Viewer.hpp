#ifndef GTK4_OCCT8_VIEWER_H
#define GTK4_OCCT8_VIEWER_H

#include "ViewController.hpp"
#include <AIS_ViewCube.hxx>
#include <Aspect_Drawable.hxx>
#include <Aspect_NeutralWindow.hxx>
#include <Message.hxx>
#include <Message_Gravity.hxx>
#include <OpenGl_GraphicDriver.hxx>
#include <V3d_View.hxx>
#include <V3d_Viewer.hxx>
#include <cstdlib>
#include <cstring>
#include <glib.h>
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
     * @param show_stats Show live rendering stats in the Viewer window
     * @param print_gl Print OpenGL diagnostics to the console
     * @param verbose_gl Use verbose OpenGL diagnostics
     * */
    static FloatPtr<Viewer> create(bool show_stats = false,
                                   bool print_gl = false,
                                   bool verbose_gl = false);
    void print_gl_info(bool verbose);

    struct {
        occ::handle<Aspect_NeutralWindow> win;
        occ::handle<V3d_Viewer> viewer;
        occ::handle<V3d_View> view;
        occ::handle<AIS_InteractiveContext> ctx;
        occ::handle<AIS_ViewCube> cube;
        occ::handle<AIS_AnimationCamera> camera;
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
    void init_x11_win();
    void init_egl_ctx();
    void render_stats();
    void divert_occ_printer();

    struct {
        occ::handle<Aspect_DisplayConnection> disp;
        occ::handle<OpenGl_FrameBuffer> fbo;
        occ::handle<OpenGl_Context> ctx;
        occ::handle<OpenGl_GraphicDriver> driver;
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
    PEEL_PROPERTY(bool, show_stats, "show-stats")
    PEEL_PROPERTY(bool, print_gl, "print-gl")
    PEEL_PROPERTY(bool, verbose_gl, "verbose-gl")
    bool show_stats;
    bool print_gl;
    bool verbose_gl;
    bool get_show_stats() const;
    bool get_print_gl() const;
    bool get_verbose_gl() const;
    void set_show_stats(bool value);
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
#endif // #ifndef GTK4_OCCT8_VIEWER_H

// ====================================================
// Macros to switch between Wayland / x11 contexts
// ====================================================
#if not defined(__ANDROID__) && defined(__linux__)
#define IS_LINUX 1
#else
#define IS_LINUX 0
#endif

#if defined(__FreeBSD__) || defined(__OpenBSD__) || defined(__NetBSD__) ||     \
    defined(__DragonFly__)
#define IS_BSD 1
#else
#define IS_BSD 0
#endif

#if defined(__APPLE__) && defined(__MACH__)
#define IS_MAC 1
#else
#define IS_MAC 0
#endif

#define IS_NIX (IS_LINUX || IS_BSD)

#define CHECK_ENV(key)                                                         \
    ([&]() -> bool {                                                           \
        const char *result = std::getenv(key);                                 \
        return result != nullptr;                                              \
    }())

#define CHECK_ENV_VAL(key, val)                                                \
    ([&]() -> bool {                                                           \
        const char *result = std::getenv(key);                                 \
        return result != nullptr && std::strcmp(result, val) == 0;             \
    }())

#define USE_X11                                                                \
    ([]() -> bool {                                                            \
        if (!IS_MAC && !IS_NIX)                                                \
            return 0;                                                          \
                                                                               \
        return CHECK_ENV_VAL("GDK_BACKEND", "x11") ||                          \
               CHECK_ENV_VAL("XDG_SESSION_TYPE", "x11");                       \
    }())

#define USE_WAYLAND                                                            \
    ([]() -> bool {                                                            \
        if (!IS_NIX || USE_X11)                                                \
            return 0;                                                          \
                                                                               \
        return CHECK_ENV_VAL("GDK_BACKEND", "wayland") ||                      \
               CHECK_ENV_VAL("XDG_SESSION_TYPE", "wayland");                   \
    }())

#define USE_GLES ([]() -> bool { return CHECK_ENV("USE_GLES"); }())
