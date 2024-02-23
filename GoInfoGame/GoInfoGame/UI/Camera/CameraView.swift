//
//  CameraView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 21/02/24.
//

import SwiftUI
import ARKit

struct ARMeasuringView: View {
    @Binding var measuring: Bool
    @State private var startValue = SCNVector3()
    @State private var endValue = SCNVector3()
    
    var body: some View {
        VStack {
            ARViewContainer(measuring: $measuring, startValue: $startValue, endValue: $endValue)
            Button(action: {
                self.toggleMeasuring()
            }) {
                Text(measuring ? "Stop Measuring" : "Start Measuring")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            Text("Result: \(measurementResult)")
        }
    }
    var measurementResult: String {
        let cm = startValue.distance(from: endValue) * 100.0
        let inch = cm * 0.3937007874
        return String(format: "%.2f cm / %.2f\"", cm, inch)
    }
    
    func toggleMeasuring() {
        measuring.toggle()
        if !measuring {
            resetValues()
        }
    }
    
    func resetValues() {
        startValue = SCNVector3()
        endValue = SCNVector3()
    }

}

struct ARViewContainer: UIViewRepresentable {
    @Binding var measuring: Bool
    @Binding var startValue: SCNVector3
    @Binding var endValue: SCNVector3
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        arView.delegate = context.coordinator
        let scene = SCNScene()
        arView.scene = scene
        
        let configuration = ARWorldTrackingConfiguration()
        arView.session.run(configuration)
        
        let crosshairNode = createCrosshairNode(size: arView.bounds.size)
        let skScene = SKScene(size: arView.bounds.size)
        skScene.addChild(crosshairNode)
        arView.overlaySKScene = skScene
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {

    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        var parent: ARViewContainer
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            DispatchQueue.main.async {
                if self.parent.measuring {
                    self.parent.detectObjects(in: renderer as! ARSCNView)
                }
            }
        }
    }
    
    func detectObjects(in arView: ARSCNView) {
        guard let worldPos = arView.realWorldVector(screenPos: arView.center) else { return }
        
        if startValue == SCNVector3() {
            startValue = worldPos
        } else {
            endValue = worldPos
        }
        
        updateLine(in: arView)
    }
    
    func updateLine(in arView: ARSCNView) {
        let lineNode = createLineNode(from: startValue, to: endValue)
        arView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        arView.scene.rootNode.addChildNode(lineNode)
    }
    
    func createLineNode(from startPoint: SCNVector3, to endPoint: SCNVector3) -> SCNNode {
        let vertices: [SCNVector3] = [startPoint, endPoint]
        let line = SCNGeometry.line(from: vertices)
        let lineNode = SCNNode(geometry: line)
        return lineNode
    }
    
    func createCrosshairNode(size: CGSize) -> SKNode {
        let crosshairLabel = SKLabelNode(text: "+")
        crosshairLabel.fontSize = 50
        crosshairLabel.fontColor = .white
        crosshairLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        let crosshairNode = SKNode()
        crosshairNode.addChild(crosshairLabel)
        return crosshairNode
    }
}
