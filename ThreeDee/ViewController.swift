import Cocoa

class ViewController: NSViewController {

  // We'll render the 3D scene into this view's layer.
  @IBOutlet weak var renderView: NSView!

  override func viewDidLoad() {
    super.viewDidLoad()

    let layer = CALayer()
    layer.frame = CGRect(x: 0, y: 0, width: 800, height: 600)
    layer.backgroundColor = NSColor.red.cgColor
    renderView.layer = layer

    // Draw the scene in its initial state.
    redraw()

    // Set up a timer to drive the animations. In a real app you would use a
    // CA/CVDisplayLink, but for this demo app a simple Timer will do. We add 
    // the timer for .commonModes so that the animation keeps playing when you
    // drag the slider.
    let timer = Timer(timeInterval: 0.02,
                      target: self, selector: #selector(handleTimer),
                      userInfo: nil, repeats: true)
    RunLoop.current.add(timer, forMode: .commonModes)
  }

  @IBAction func sliderMoved(_ sender: NSSlider) {
    // Dragging the slider moves the camera to the left or right.
    cameraX = Float(sender.doubleValue) * 40
    redraw()
  }

  private func redraw() {
    render()
    presentRenderBuffer(layer: renderView.layer!)
  }

  private dynamic func handleTimer(_ timer: Timer) {
    animate()
  }

  // MARK: - Animations

  private var previousTime: CFTimeInterval = 0

  private var bounceSpeed: Float = 60
  private let bounceAccel: Float = -60

  private func animate() {
    // Figure out how much time has elapsed since last time we were called.
    // This lets us know by how much to move the animation forward.
    let now = CACurrentMediaTime()
    var deltaTime = Float(now - previousTime)
    previousTime = now
    guard deltaTime > 0 else { return }    // delta time too small
    if deltaTime > 1 { deltaTime = 0.1 }   // delta time too large

    // Bounce the cube up and down.
    bounceSpeed += bounceAccel * deltaTime
    modelY += bounceSpeed * deltaTime
    if modelY < 0 {
      modelY = 0
      bounceSpeed = -bounceSpeed
    }

    // Change the scaling of the cube based on the bounce position.
    modelScaleY = (modelY + 30) / 50
    modelScaleX = 1.5 - modelScaleY/2
    modelScaleZ = modelScaleX

    // Add some rotations, just for the fun of it.
    //modelRotateX += 1 * deltaTime
    modelRotateY += 1.5 * deltaTime
    //modelRotateZ += 1 * deltaTime

    redraw()
  }
}
