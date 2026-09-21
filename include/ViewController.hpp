#ifndef GTK4_OCCT8_VIEWCONTROLLER_H
#define GTK4_OCCT8_VIEWCONTROLLER_H

#include <AIS_ViewController.hxx>
#include <glib.h>

namespace Gtk4 {
namespace Occt8 {
using IACtx = Handle(AIS_InteractiveContext);
using View = Handle(V3d_View);

// GObject classes are not ideal for multiple inheritence,
// so we create a seperate AIS_ViewController class and give it the Viewer
// GObject widget as it's owner.
class Viewer;
class ViewController final : public AIS_ViewController {

public:
  explicit ViewController(Viewer &owner) : gobj_viewer(owner) {};
  virtual void handleViewRedraw(const IACtx &ctx, const View &view) override;

protected:
  Viewer &gobj_viewer;
  guint animation_cb = 0;
};

} // namespace Occt8
} // namespace Gtk4

#endif
