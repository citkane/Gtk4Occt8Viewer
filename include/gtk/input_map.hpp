#ifndef GTK4_OCCT8_INPUTS_H
#define GTK4_OCCT8_INPUTS_H

#include <Aspect_VKeyFlags.hxx>
#include <Aspect_Window.hxx>
#include <NCollection_Vec2.hxx>
// #include <glib.h>
#include <peel/Gdk/Gdk.h>

namespace Gtk4 {
namespace Occt8 {
using namespace peel;

static inline Aspect_VKeyMouse to_v_mouse_bttn(guint bttn) {
  switch (bttn) {
  case 1:
    return Aspect_VKeyMouse_LeftButton;
  case 2:
    return Aspect_VKeyMouse_MiddleButton;
  case 3:
    return Aspect_VKeyMouse_RightButton;
  }
  return Aspect_VKeyMouse_NONE;
};

static inline Aspect_VKeyFlags to_v_key_mod(Gdk::ModifierType type) {
  Aspect_VKeyFlags aFlags = Aspect_VKeyFlags_NONE;
  if (int(type & Gdk::ModifierType::SHIFT_MASK) != 0)
    aFlags |= Aspect_VKeyFlags_SHIFT;

  if (int(type & Gdk::ModifierType::CONTROL_MASK) != 0)
    aFlags |= Aspect_VKeyFlags_CTRL;

  if (int(type & Gdk::ModifierType::META_MASK) != 0)
    aFlags |= Aspect_VKeyFlags_META;

  if (int(type & Gdk::ModifierType::ALT_MASK) != 0)
    aFlags |= Aspect_VKeyFlags_ALT;

  return aFlags;
}

static inline NCollection_Vec2<int> to_int_point(Handle(Aspect_Window) win,
                                                 double x, double y) {
  auto p = win->ConvertPointToBacking(NCollection_Vec2(x, y));
  return NCollection_Vec2<int>(ceil(p.x()), ceil(p.y()));
};

} // namespace Occt8
} // namespace Gtk4

#endif
