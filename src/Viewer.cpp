#include "Viewer.hpp"

#include <AIS_AnimationCamera.hxx>
#include <AIS_InteractiveContext.hxx>
#include <Graphic3d_DiagnosticInfo.hxx>
#include <Message_Messenger.hxx>
#include <Quantity_NameOfColor.hxx>
#include <peel/Gdk/GLAPI.h>

#include "gtk/Gtk_FrameBuffer.hpp"
#include "gtk/input_map.hpp"

IMPLEMENT_STANDARD_RTTIEXT(Gtk4::Occt8::ViewerPrinter, Message_Printer)
PEEL_CLASS_IMPL(Gtk4::Occt8::Viewer, "Gtk4Occt8Viewer", peel::Gtk::GLArea)
using namespace Gtk4::Occt8;
using namespace peel;

void Viewer::init(Class *) {
    win_native = 0;
    prev_pix_r = 0;
    occ_pix_r = 1;
    g_message(USE_WAYLAND ? "Use Wayland" : "No use Wayland");
    g_message(USE_GLES ? "Use GLES" : "No use GLES");
    g_message(USE_X11 ? "Use X11" : "No use X11");
    set_allowed_apis(USE_GLES ? Gdk::GLAPI::GLES
                              : Gdk::GLAPI::GL); // requires GTK4 v4.12+
    set_can_focus(true);
    set_focusable(true);
    set_focus_on_click(true);

    divert_occ_printer();
    register_input();

    connect_realize([this](Gtk::Widget *) {
        make_current();
        const Gdk::GLAPI gl_api = get_context()->get_api();
        g_message(gl_api == Gdk::GLAPI::GLES ? "Using GlES"
                                             : "Using Desktop GL");
        init_driver();
        init_viewer(); // init on realise so that user defaults are prefferred
        init_ctx();

        g_message("Widget was realised");
    });

    connect_render([this](Gtk::GLArea *, Gdk::GLContext *) {
        const int gtk_w = get_width();
        const int gtk_h = get_height();
        Gdk::Surface *srfc = get_context()->get_surface();
        const double new_gtk_pix_r = srfc->get_scale();

        if (!is_realised) {
            init_window(gtk_w, gtk_h, new_gtk_pix_r);
            wrap_gl_fbo();
            is_realised = true;
            if (print_gl)
                print_gl_info(verbose_gl);

            g_message("Window was realised");
        }

        // It is expected that dpi changes if moved to different screen
        // @TODO Examine behaviour on multi-screen when available
        set_pixel_ratio(gtk_w, new_gtk_pix_r);
        occ.ctrl->FlushViewEvents(occ.ctx, occ.view, true);
        return true;
    });

    connect_resize([this](Gtk::GLArea *, int w, int h) {
        if (!is_realised)
            return;

        w = ceil(w * occ_pix_r);
        h = ceil(h * occ_pix_r);
        gl.fbo->ChangeViewport(w, h);
        occ.win->SetSize(w, h);
        occ.view->MustBeResized();
        occ.view->Invalidate();
        //@TODO familiarise and examine sub-view behaviours
        for (const occ::handle<V3d_View> &sub_view : occ.view->Subviews()) {
            sub_view->MustBeResized();
            sub_view->Invalidate();
        }
        occ.ctrl->FlushViewEvents(occ.ctx, occ.view, true);
    });

    connect_unrealize([this](Gtk::Widget *) {
        if (!occ.view.IsNull()) {
            occ.view->Remove();
            occ.view.Nullify();
            occ.viewer.Nullify();
        }
        make_current();
        gl.disp.Nullify();
    });
}

void Viewer::init_driver() {
    gl.disp = new Aspect_DisplayConnection();
    gl.driver = new OpenGl_GraphicDriver(gl.disp, false);
    // lets Gtk::GLArea to manage buffer swap
    gl.driver->ChangeOptions().buffersNoSwap = true;
    // don't write into alpha channel
    gl.driver->ChangeOptions().buffersOpaqueAlpha = true;
    // offscreen FBOs should be always used
    gl.driver->ChangeOptions().useSystemBuffer = false;
    // GTK4 creates Core Profile when possible with no option to manage this
    // behavior!
    // @TODO Line widths are important - examine how this affects GTK
    gl.driver->ChangeOptions().contextCompatible = false;
}

void Viewer::init_viewer() {
    occ.ctrl = new ViewController(*this);
    occ.viewer = new V3d_Viewer(gl.driver);
    occ.ctx = new AIS_InteractiveContext(occ.viewer);
    occ.cube = new AIS_ViewCube();
    occ.camera = new AIS_AnimationCamera("default", occ.view);

    occ.viewer->SetDefaultBackgroundColor(Quantity_NOC_DARKSLATEGRAY);
    occ.viewer->SetDefaultLights();
    occ.viewer->SetLightOn();
    occ.viewer->ActivateGrid(Aspect_GT_Rectangular, Aspect_GDM_Lines);

    occ.view = occ.viewer->CreateView();
    occ.view->SetImmediateUpdate(false);

    occ.cube->SetViewAnimation(occ.camera);
    occ.cube->SetFixedAnimationLoop(false);
    occ.cube->SetAutoStartAnimation(true);

    occ.ctx->Display(occ.cube, 0, 0, false);
    if (show_stats)
        render_stats();
}

void Viewer::render_stats() {
    occ.view->ChangeRenderingParams().ToShowStats = true;
    occ.view->ChangeRenderingParams().CollectedStats =
        (Graphic3d_RenderingParams::
             PerfCounters)(Graphic3d_RenderingParams::PerfCounters_FrameRate |
                           Graphic3d_RenderingParams::PerfCounters_Triangles);
}

void Viewer::init_ctx() {
    const bool ctx_compat = gl.driver->Options().contextCompatible;

    if (USE_X11 && !USE_GLES)
        init_x11_win();

    gl.ctx = new OpenGl_Context();
    if (!gl.ctx->Init(!ctx_compat))
        g_error("Failed to initialise gl context");

    if (USE_WAYLAND || USE_GLES)
        init_egl_ctx();
}

void Viewer::init_window(int gtk_x, int gtk_y, float gtk_r) {
    const int occ_x = ceil(gtk_x * gtk_r);
    const int occ_y = ceil(gtk_y * gtk_r);
    const RenderingContext ctx_gl = gl.ctx->RenderingContext();

    g_debug("def occt resltn: %u",
            occ.view->RenderingParams().Resolution); // 72
    occ.win = new Aspect_NeutralWindow();
    occ.win->SetVirtual(true);
    occ.win->SetNativeHandle(win_native);
    occ.win->SetSize(occ_x, occ_y);
    // @TODO why 96 and not the default 72
    occ.view->ChangeRenderingParams().Resolution = 96.0;
    g_debug("init occt resltn: %u", occ.view->RenderingParams().Resolution);
    occ.view->SetWindow(occ.win, ctx_gl);
    occ.view->MustBeResized();
    occ.view->Invalidate();
    // @TODO We are at init - can there be subviews yet?
    for (const occ::handle<V3d_View> &sub_view : occ.view->Subviews()) {
        sub_view->MustBeResized();
        sub_view->Invalidate();
    }
}

void Viewer::wrap_gl_fbo() {
    attach_buffers();
    gl.fbo = new Gtk_FrameBuffer();
    gl.driver->GetSharedContext()->SetDefaultFrameBuffer(gl.fbo);
    if (!gl.fbo->InitWrapper(gl.ctx))
        g_error("Could not wrap the gl framebuffer");
};

void Viewer::set_pixel_ratio(int gtk_x, float gtk_r) {
    if (gtk_r == prev_pix_r)
        return;

    prev_pix_r = gtk_r;
    Vec2i const fbo_sz = gl.fbo->GetVPSize();
    Vec2i const occ_sz = occ.win->Dimensions();
    if (occ_sz != fbo_sz) {
        g_debug("occt and fbo size different: %ux%u,%ux%u", occ_sz.x(),
                occ_sz.y(), fbo_sz.x(), fbo_sz.y());
        occ.win->SetSize(fbo_sz.x(), fbo_sz.y());
        occ.view->MustBeResized();
        occ.view->Invalidate();
        for (const occ::handle<V3d_View> &sub_view : occ.view->Subviews()) {
            sub_view->MustBeResized();
            sub_view->Invalidate();
            // @TODO Examine subview behaviours
            gl.fbo->SetupViewport(gl.ctx);
        }
    }
    const float buffer_p_r = float(fbo_sz.x()) / float(gtk_x);
    if (buffer_p_r != gtk_r) {
        occ_pix_r = buffer_p_r;
        occ.ctrl->SetTouchToleranceScale(occ_pix_r);
        // @TODO why 96 and not the default 72?
        occ.view->ChangeRenderingParams().Resolution = ceil(96.0 * occ_pix_r);
        g_debug("calc occt resltn: %u", occ.view->RenderingParams().Resolution);
    }
}

void Viewer::register_input() {
    const auto v_scroll_flag = Gtk::EventControllerScroll::Flags::VERTICAL;
    const auto ctrl_scroll = Gtk::EventControllerScroll::create(v_scroll_flag);
    const auto ctrl_motion = Gtk::EventControllerMotion::create();
    const auto ctrl_click = Gtk::GestureClick::create();
    const auto ctrl_mod = Gtk::EventControllerKey::create();

    ctrl_motion->connect_motion(
        [this](Gtk::EventControllerMotion *ctrl, double gtk_x, double gtk_y) {
            const VKeyFlags mod = to_v_key_mod(ctrl->get_current_event_state());
            const Vec2i point = to_int_point(occ.win, gtk_x, gtk_y);
            const VKeyMouse buttons = occ.ctrl->PressedMouseButtons();

            if (occ.ctrl->UpdateMousePosition(point, buttons, mod, false))
                queue_draw();
        },
        false);

    ctrl_scroll->connect_scroll(
        [this](Gtk::EventControllerScroll *ctrl, double gtk_x,
               double gtk_y) -> bool {
            Vec2d delta = NCollection_Vec2(gtk_x, gtk_y);
            const VKeyFlags mod = to_v_key_mod(ctrl->get_current_event_state());
            const VKeyMouse buttons = occ.ctrl->PressedMouseButtons();
            const Vec2i point = to_int_point(occ.win, gtk_x, gtk_y);
            const Vec2i &p = occ.ctrl->LastMousePosition();

            // 123 logical pixels from GTK documentation
            // @TODO Scrolling is sluggish on Wayland vs x11 - examine
            if (ctrl->get_unit() == Gdk::ScrollUnit::SURFACE)
                delta = (delta * get_scale_factor()) / 123.0;

            if (occ.ctrl->UpdateMouseButtons(point, buttons, mod, false) ||
                occ.ctrl->UpdateMouseScroll(Aspect_ScrollDelta(p, -delta.y())))
                queue_draw();

            return true;
        },
        false);

    ctrl_click->set_button(0);
    ctrl_click->connect_pressed(
        [this](Gtk::GestureClick *ctrl, guint bttn, double gtk_x,
               double gtk_y) {
            const VKeyMouse v_bttn = to_v_mouse_bttn(bttn);
            const Vec2i point = to_int_point(occ.win, gtk_x, gtk_y);
            const VKeyFlags mod = to_v_key_mod(ctrl->get_current_event_state());

            if (get_focus_on_click())
                grab_focus();

            if (v_bttn == Aspect_VKeyMouse_NONE)
                return;

            occ.ctrl->PressMouseButton(point, v_bttn, mod, false);
            queue_draw();
        },
        false);

    ctrl_click->connect_released(
        [this](Gtk::GestureClick *ctrl, guint bttn, double gtk_x,
               double gtk_y) {
            const VKeyMouse v_bttn = to_v_mouse_bttn(bttn);
            const Vec2i point = to_int_point(occ.win, gtk_x, gtk_y);
            const VKeyFlags mod = to_v_key_mod(ctrl->get_current_event_state());

            if (get_focus_on_click())
                grab_focus();

            if (v_bttn == Aspect_VKeyMouse_NONE)
                return;

            occ.ctrl->ReleaseMouseButton(point, v_bttn, mod, false);
            queue_draw();
        },
        false);

    ctrl_click->connect_cancel(
        [this, ctrl_click](Gtk::Gesture *ctrl, const Gdk::EventSequence *) {
            const VKeyFlags mod = to_v_key_mod(ctrl->get_current_event_state());
            const unsigned int curr_bttn = ctrl_click->get_current_button();
            const VKeyMouse v_bttn = to_v_mouse_bttn(curr_bttn);
            const Vec2i last_m_pos = occ.ctrl->LastMousePosition();

            if (occ.ctrl->ReleaseMouseButton(last_m_pos, v_bttn, mod, false))
                queue_draw();
        },
        false);

    // @TODO get_current_view_state seems to handle modifiers, but confirm that
    // this listener override is not required.
    //
    // ctrl_mod->connect_modifiers(
    //     [this](Gtk::EventControllerKey *ctrl_key,
    //            Gdk::ModifierType type) -> bool {
    //       auto pressed = ctrl_key->get_current_event_state();
    //       logger::info("pressed:", std::to_string((int)pressed),
    //                    "state:", std::to_string((int)type));
    //       // key_mods = to_v_key_mod(type);
    //       // return key_mods != 0;
    //       return false;
    //     },
    //     false);

    add_controller(ctrl_motion);
    add_controller(ctrl_scroll);
    add_controller(ctrl_click);
    add_controller(ctrl_mod);
}

void Viewer::print_gl_info(bool verbose) {
    if (!is_realised) {
        g_warning(
            "GL diagnotics can only be printed after the window is realised");
        return;
    }

    using Str = TCollection_AsciiString;
    using Data = NCollection_IndexedDataMap<Str, Str>;
    auto verbosity = verbose ? Graphic3d_DiagnosticInfo_Complete
                             : Graphic3d_DiagnosticInfo_Basic;
    Str info;
    Data dict;

    occ.view->DiagnosticInformation(dict, verbosity);
    for (Data::Iterator val(dict); val.More(); val.Next()) {
        if (val.Value().IsEmpty())
            break;

        auto line = val.Key() + ": " + val.Value();
        info += info.IsEmpty() ? line : (Str) "\n" + line;
    }
    g_message("\n%s", info.ToCString());
}

void Viewer::divert_occ_printer() {
    occ::handle<ViewerPrinter> printer = new ViewerPrinter;
    occ::handle<Message_Messenger> messenger = Message::DefaultMessenger();
    messenger->ChangePrinters().Clear();
    messenger->AddPrinter(printer);
}

// =============================
// peel GObject intitialiser
// =============================
inline void Viewer::Class::init() {}
FloatPtr<Viewer> Viewer::create(bool show_stats, bool print_gl,
                                bool verbose_gl) {
    auto viewer = Object::create<Viewer>();
    viewer->set_show_stats(show_stats);
    viewer->set_print_gl(print_gl);
    viewer->set_verbose_gl(verbose_gl);
    return viewer;
}

template <typename F> void Viewer::define_properties(F &f) {
    f.prop(prop_print_gl(), false)
        .get(&Viewer::get_print_gl)
        .set(&Viewer::set_print_gl)
        .flags(peel::GObject::ParamFlags::READWRITE);

    f.prop(prop_show_stats(), false)
        .get(&Viewer::get_show_stats)
        .set(&Viewer::set_show_stats)
        .flags(peel::GObject::ParamFlags::READWRITE);
}

bool Viewer::get_show_stats() const { return show_stats; }
bool Viewer::get_print_gl() const { return print_gl; }
bool Viewer::get_verbose_gl() const { return print_gl; }
void Viewer::set_show_stats(bool value) { show_stats = value; }
void Viewer::set_print_gl(bool value) { print_gl = value; }
void Viewer::set_verbose_gl(bool value) { verbose_gl = value; }
