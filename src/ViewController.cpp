#include "Viewer.hpp"

using namespace Gtk4::Occt8;

void ViewController::handleViewRedraw(const IACtx &ctx, const View &view) {
  AIS_ViewController::handleViewRedraw(ctx, view);
  bool should_animate = myToAskNextFrame != (animation_cb != 0);
  if (!should_animate)
    return;

  if (myToAskNextFrame) {
    // start animation
    animation_cb = gobj_viewer.add_tick_callback(
        [this](Gtk::Widget *, Gdk::FrameClock *) -> bool {
          gobj_viewer.queue_draw();
          return true;
        });
  } else {
    // stop animation
    gobj_viewer.remove_tick_callback(animation_cb);
    animation_cb = 0;
  }
};
