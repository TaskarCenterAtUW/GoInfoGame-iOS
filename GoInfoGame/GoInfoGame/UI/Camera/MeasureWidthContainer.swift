//
//  CameraView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 21/02/24.
//

import SwiftUI
import ARKit

struct MeasureWidthContainer: UIViewRepresentable {
    
    @Binding var aimLabelHidden: Bool
    @Binding var notReadyLabelHidden: Bool
    @Binding var startMeasuring: Bool
    @Binding var resultLabelText: String
    
    let sceneView = ARSCNView()
    let session = ARSession()
    let sessionConfig = ARWorldTrackingConfiguration()
    
    let vectorZero = SCNVector3()
    var startValue = SCNVector3()
    var endValue = SCNVector3()
    
    var startPointNode: SCNNode?
    var endPointNode: SCNNode?
    var lineNode: SCNNode?
    
    @State private var isMeasuring = false

    
     func makeUIView(context: Context) -> ARSCNView {
        sceneView.delegate = context.coordinator
        sceneView.session = session
        session.run(sessionConfig, options: [.resetTracking, .removeExistingAnchors])
       
        return sceneView
    }
        
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        if startMeasuring {
            context.coordinator.startMeasuring()
        } else {
            if isMeasuring {
                context.coordinator.stopMeasuring()
                isMeasuring = false
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        var parent: MeasureWidthContainer
        
        init(_ parent: MeasureWidthContainer) {
            self.parent = parent
        }
        
        @objc func measuringChanged() {
            if parent.startMeasuring {
                startMeasuring()
            } else {
                stopMeasuring()
            }
        }
        
        func startMeasuring() {
            parent.resetValues()
            parent.startMeasuring = true
            
        }
        
        func stopMeasuring() {
            parent.startMeasuring = false
            parent.endPointNode = parent.createPointNode(at: parent.endValue, color: .red)
            parent.sceneView.scene.rootNode.addChildNode(parent.endPointNode!)
            parent.updateResultLabel(parent.startValue.distance(from: parent.endValue))
        }
        
        
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            DispatchQueue.main.async {
                self.parent.detectObjects()
            }
        }
    }
    
    mutating func detectObjects() {
        if let worldPos = sceneView.realWorldVector(screenPos: sceneView.center) {
            aimLabelHidden = false
            notReadyLabelHidden = true
            if startMeasuring {
                if startValue == vectorZero {
                    startValue = worldPos
                    startPointNode = createPointNode(at: worldPos, color: .green)
                    sceneView.scene.rootNode.addChildNode(startPointNode!)
                    isMeasuring = true
                }
                
                endValue = worldPos
                
                if let line = lineNode {
                    line.removeFromParentNode()
                }
                lineNode = createLineNode(from: startValue, to: endValue)
                sceneView.scene.rootNode.addChildNode(lineNode!)
            }
        }
    }
    
    mutating func resetValues() {
        startMeasuring = false
        startValue = SCNVector3()
        endValue = SCNVector3()
        
        startPointNode?.removeFromParentNode()
        endPointNode?.removeFromParentNode()
        lineNode?.removeFromParentNode()
        
        updateResultLabel(0.0)
        
    }
    
    func updateResultLabel(_ value: Float) {
        let cm = value * 100.0
        let inch = cm*0.3937007874
        DispatchQueue.main.async {
            self.resultLabelText = String(format: "%.2f cm / %.2f\"", cm, inch)
        }
    }
    
    func createPointNode(at position: SCNVector3, color: UIColor) -> SCNNode {
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = color
        let node = SCNNode(geometry: sphere)
        node.position = position
        return node
    }
    
    func createLineNode(from startPoint: SCNVector3, to endPoint: SCNVector3) -> SCNNode {
        let vertices: [SCNVector3] = [startPoint, endPoint]
        let line = SCNGeometry.line(from: vertices)
        let lineNode = SCNNode(geometry: line)
        return lineNode
    }
}
