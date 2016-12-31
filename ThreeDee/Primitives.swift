import Foundation
import QuartzCore

/*
  The only primitive drawing operation we use is writing pixel RGB values into
  a CGBitmapContext. This bitmap context gets converted into a CGImage that we
  directly assign to a CALayer in order to display it.

  NOTE: (0, 0) is the bottom-left corner. Pixels are stored as 0xABGR.
*/

let context = CGContext(data: nil, width: 800, height: 600,
                        bitsPerComponent: 8, bytesPerRow: 800*4,
                        space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)

func clearRenderBuffer(color: UInt32 = 0xff000000) {
  if let context = context, let pixels = context.data {
    let size = context.width * context.height * 4
    for i in stride(from: 0, to: size, by: 4) {
      pixels.storeBytes(of: color, toByteOffset: i, as: UInt32.self)
    }
  }
}

func setPixel(x: Int, y: Int, r: Float, g: Float, b: Float, a: Float) {
  if let context = context, let pixels = context.data {
    let width = Int(context.width)
    let height = Int(context.height)

    // Is the pixel actually visible? We don't want to write outside our memory.
    if x >= 0 && x < width && y >= 0 && y < height {

      let offset = (x + ((height - 1) - y) * width) * 4

      // (Use this to make the origin top-left instead of bottom-right.)
      // let offset = (x + y * Int(context.width)) * 4

      let color: UInt32 = (UInt32(a * 255) << 24) | (UInt32(b * 255) << 16)
                        | (UInt32(g * 255) <<  8) | (UInt32(r * 255))

      pixels.storeBytes(of: color, toByteOffset: offset, as: UInt32.self)
    }
  }
}

func presentRenderBuffer(layer: CALayer) {
  if let image = context?.makeImage() {
    layer.contents = image
  }
}
