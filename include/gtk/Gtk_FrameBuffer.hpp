#ifndef GTK4_OCCT8_GTK_FRAMEBUFFER_H
#define GTK4_OCCT8_GTK_FRAMEBUFFER_H

#include <OpenGl_Context.hxx>
#include <OpenGl_FrameBuffer.hxx>

namespace Gtk4 {
namespace Occt8 {
/**
 * Sets the offscreen OpenGl_FrameBuffer to SRGB colourspace
 * */
class Gtk_FrameBuffer : public OpenGl_FrameBuffer {
  DEFINE_STANDARD_RTTI_INLINE(Gtk_FrameBuffer, OpenGl_FrameBuffer)
public:
  virtual void BindBuffer(const Handle(OpenGl_Context) & ctx) override {
    OpenGl_FrameBuffer::BindBuffer(ctx);
    ctx->SetFrameBufferSRGB(true, false);
  }
  virtual void BindDrawBuffer(const Handle(OpenGl_Context) & ctx) override {
    OpenGl_FrameBuffer::BindDrawBuffer(ctx);
    ctx->SetFrameBufferSRGB(true, false);
  }
  virtual void BindReadBuffer(const Handle(OpenGl_Context) & ctx) override {
    OpenGl_FrameBuffer::BindReadBuffer(ctx);
  }
};

} // namespace Occt8
} // namespace Gtk4

#endif
