import SwiftUI
import SceneKit

/// Renders the earbuds as a real-time 3D scene.
///
/// Prefers a bundled `Resources/buds3fe.usdz` if present; otherwise builds a
/// procedural chrome earbud so the app always shows something in 3D.
/// Pass `interactive: true` to enable drag-to-rotate (camera control).
public struct BudsModel3DView: NSViewRepresentable {
  private let interactive: Bool

  public init(interactive: Bool = false) {
    self.interactive = interactive
  }

  public func makeNSView(context: Context) -> SCNView {
    let view = SCNView()
    view.scene = Self.makeScene()
    view.backgroundColor = .clear
    view.autoenablesDefaultLighting = true
    view.allowsCameraControl = interactive
    view.antialiasingMode = .multisampling4X
    view.rendersContinuously = true
    return view
  }

  public func updateNSView(_ nsView: SCNView, context: Context) {}

  // MARK: - Scene

  private static func makeScene() -> SCNScene {
    if let url = Bundle.module.url(
      forResource: "buds3fe", withExtension: "usdz", subdirectory: "Resources"
    ), let scene = try? SCNScene(url: url) {
      spin(scene.rootNode.childNodes.first ?? scene.rootNode)
      return scene
    }
    return proceduralScene()
  }

  private static func proceduralScene() -> SCNScene {
    let scene = SCNScene()

    let buds = SCNNode()
    let left = makeBud()
    left.position = SCNVector3(-0.75, 0, 0)
    left.eulerAngles = SCNVector3(0, 0, 0.25)
    let right = makeBud()
    right.position = SCNVector3(0.75, 0, 0)
    right.eulerAngles = SCNVector3(0, 0, -0.25)
    buds.addChildNode(left)
    buds.addChildNode(right)
    buds.eulerAngles = SCNVector3(-0.2, 0, 0)
    scene.rootNode.addChildNode(buds)
    spin(buds)

    let camera = SCNNode()
    camera.camera = SCNCamera()
    camera.position = SCNVector3(0, 0, 4.0)
    scene.rootNode.addChildNode(camera)

    let ambient = SCNNode()
    ambient.light = SCNLight()
    ambient.light?.type = .ambient
    ambient.light?.intensity = 350
    scene.rootNode.addChildNode(ambient)

    return scene
  }

  private static func makeBud() -> SCNNode {
    let material = SCNMaterial()
    material.lightingModel = .blinn
    material.diffuse.contents = NSColor(calibratedWhite: 0.72, alpha: 1)
    material.specular.contents = NSColor.white
    material.shininess = 0.6

    let housing = SCNSphere(radius: 0.5)
    housing.firstMaterial = material
    let housingNode = SCNNode(geometry: housing)
    housingNode.scale = SCNVector3(1.0, 0.9, 1.15)

    let stem = SCNCapsule(capRadius: 0.17, height: 0.95)
    stem.firstMaterial = material
    let stemNode = SCNNode(geometry: stem)
    stemNode.position = SCNVector3(0, -0.6, 0.05)
    stemNode.eulerAngles = SCNVector3(0.15, 0, 0)

    let bud = SCNNode()
    bud.addChildNode(housingNode)
    bud.addChildNode(stemNode)
    return bud
  }

  private static func spin(_ node: SCNNode) {
    node.runAction(
      .repeatForever(.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 9))
    )
  }
}
