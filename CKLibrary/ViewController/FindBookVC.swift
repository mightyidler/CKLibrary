//
//  FindBookVC.swift
//  CKLibrary
//
//  Created by mightyidler on 2020/07/28.
//

import UIKit
import SceneKit
import ARKit
import Alamofire
import Kingfisher

class FindBookVC: UIViewController, ARSCNViewDelegate{
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var imageShadowView: UIView!
    @IBOutlet weak var imageMaskView: UIView!
    @IBOutlet weak var bookImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var callNumberLabel: UILabel!
    @IBOutlet weak var pathFindButton: UIButton!
    
    var bookTitle: String!
    var bookAuthor: String!
    var bookPosition: String!
    var bookCallNumber: String!
    var bookCno: String!
    
    let configuratioon = ARWorldTrackingConfiguration()
    let conf = ARPositionalTrackingConfiguration()
    
    var cameraPosition: SCNVector3!
    //var cameraPosition: simd_float4x4!
    var cameraAngle: SCNVector3!
    var floorY: Float!
    var routeDirection: [String]!
    var routePosition: [[Float]]!
    var rotateY: Double!
    var rotateW: Double!
    var step: Int = 0
    var pathFindingStatus: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dismissButton.layer.cornerRadius = self.dismissButton.frame.height / 2
        
        sceneView.delegate = self
        self.sceneView.session.run(configuratioon)
        routePosition = [[0.0,-0.3], [1.0,-0.3], [2.0,-0.3], [3.0,-0.3],
                         [3.9,-0.3], [3.9,-1.3], [3.9,-2.3], [3.9,-2.7],
                         [4.9,-2.7], [5.9,-2.7] ,[6.9,-2.7], [7.9,-2.7],[8.3,-2.7]]
        routeDirection = ["right", "right", "right", "right",
                          "forward", "forward", "forward", "right",
                          "right", "right", "right", "right", "backward"]
        uiInit()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        sceneView.session.delegate = self
        self.step = 0
    }
    
    func uiInit() {
        self.bottomView.layer.cornerRadius = 8
        self.imageShadowView.layer.cornerRadius = 4
        self.imageMaskView.layer.cornerRadius = 4
        self.pathFindButton.layer.cornerRadius = self.pathFindButton.frame.height / 2
        self.bottomView.layer.applySketchShadow(
            color: UIColor.black,
            alpha: 0.5,
            x: 0,
            y: 3,
            blur: 10,
            spread: 0)
        self.imageShadowView.layer.applySketchShadow(
            color: UIColor.black,
            alpha: 0.5,
            x: 0,
            y: 3,
            blur: 10,
            spread: 0)
        
        if let title = self.bookTitle {
            titleLabel.text = title
        }
        if let position = self.bookPosition {
            positionLabel.text = position
        }
        if let callNumber = self.bookCallNumber {
            callNumberLabel.text = callNumber
        }
        if let cno = self.bookCno {
            let url = URL(string: "http://library.ck.ac.kr/Cheetah/Shared/CoverImage?Cno=\(cno)")
            let processor = DownsamplingImageProcessor(size: self.bookImage.bounds.size)
                |> ResizingImageProcessor(referenceSize: CGSize(width: 68.0, height: 98.0), mode: .aspectFill)
            self.bookImage.kf.setImage(
                with: url,
                placeholder: UIImage(named: "placeholderImage"),
                options: [
                    .processor(processor),
                    .transition(.fade(0.1)),
                    .scaleFactor(UIScreen.main.scale),
                    .cacheOriginalImage
                    
                ])
        }
    }
    
    
    @IBAction func dismissButtonAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func pathFindButtonAction(_ sender: Any) {
        findPath()
    }
    
    
    func findPath() {
        let alert = UIAlertController(title: "경로 검색중", message: nil, preferredStyle: .alert)
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.isUserInteractionEnabled = false
        activityIndicator.startAnimating()
        alert.view.addSubview(activityIndicator)
        alert.view.heightAnchor.constraint(equalToConstant: 95).isActive = true
        activityIndicator.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor, constant: 0).isActive = true
        activityIndicator.bottomAnchor.constraint(equalTo: alert.view.bottomAnchor, constant: -20).isActive = true
        present(alert, animated: true)
        self.step = 0
        let when = DispatchTime.now() + 1
        self.resetSettionView()
        DispatchQueue.main.asyncAfter(deadline: when){
            alert.dismiss(animated: true, completion: nil)
            self.addNode(x: self.routePosition[0][0], z: self.routePosition[0][1], nodeDirection: self.routeDirection[0])
            self.pathFindingStatus = true
        }
    }
    
    func pointInFrontOfPoint(point: SCNVector3, direction: SCNVector3, distance: Float) -> SCNVector3 {
        var x = Float()
        var y = Float()
        var z = Float()
        
        x = point.x + distance * direction.x
        y = point.y + distance * direction.y
        z = point.z + distance * direction.z
        
        let result = SCNVector3Make(x, y, z)
        return result
    }
    
    func calculateCameraDirection(cameraNode: SCNNode) -> SCNVector3 {
        let x = -cameraNode.rotation.x
        let y = -cameraNode.rotation.y
        let z = -cameraNode.rotation.z
        let w = cameraNode.rotation.w
        let cameraRotationMatrix = GLKMatrix3Make(cos(w) + pow(x, 2) * (1 - cos(w)),
                                                  x * y * (1 - cos(w)) - z * sin(w),
                                                  x * z * (1 - cos(w)) + y*sin(w),
                                                  
                                                  y*x*(1-cos(w)) + z*sin(w),
                                                  cos(w) + pow(y, 2) * (1 - cos(w)),
                                                  y*z*(1-cos(w)) - x*sin(w),
                                                  
                                                  z*x*(1 - cos(w)) - y*sin(w),
                                                  z*y*(1 - cos(w)) + x*sin(w),
                                                  cos(w) + pow(z, 2) * ( 1 - cos(w)))
        
        let cameraDirection = GLKMatrix3MultiplyVector3(cameraRotationMatrix, GLKVector3Make(0.0, 0.0, -1.0))
        return SCNVector3FromGLKVector3(cameraDirection)
    }
    func addNode(x: Float, z: Float , nodeDirection: String) {
        let vertcount = 48;
        let verts: [Float] = [ -1.4923, 1.1824, 2.5000, -6.4923, 0.000, 0.000, -1.4923, -1.1824, 2.5000, 4.6077, -0.5812, 1.6800, 4.6077, -0.5812, -1.6800, 4.6077, 0.5812, -1.6800, 4.6077, 0.5812, 1.6800, -1.4923, -1.1824, -2.5000, -1.4923, 1.1824, -2.5000, -1.4923, 0.4974, -0.9969, -1.4923, 0.4974, 0.9969, -1.4923, -0.4974, 0.9969, -1.4923, -0.4974, -0.9969 ];
        
        let facecount = 13;
        let faces: [CInt] = [  3, 4, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 0, 1, 2, 3, 4, 5, 6, 7, 1, 8, 8, 1, 0, 2, 1, 7, 9, 8, 0, 10, 10, 0, 2, 11, 11, 2, 7, 12, 12, 7, 8, 9, 9, 5, 4, 12, 10, 6, 5, 9, 11, 3, 6, 10, 12, 4, 3, 11 ];
        
        let vertsData  = NSData(
            bytes: verts,
            length: MemoryLayout<Float>.size * vertcount
        )
        
        let vertexSource = SCNGeometrySource(data: vertsData as Data,
                                             semantic: .vertex,
                                             vectorCount: vertcount,
                                             usesFloatComponents: true,
                                             componentsPerVector: 3,
                                             bytesPerComponent: MemoryLayout<Float>.size,
                                             dataOffset: 0,
                                             dataStride: MemoryLayout<Float>.size * 3)
        
        let polyIndexCount = 61;
        let indexPolyData  = NSData( bytes: faces, length: MemoryLayout<CInt>.size * polyIndexCount )
        
        let element1 = SCNGeometryElement(data: indexPolyData as Data,
                                          primitiveType: .polygon,
                                          primitiveCount: facecount,
                                          bytesPerIndex: MemoryLayout<CInt>.size)
        
        let geometry1 = SCNGeometry(sources: [vertexSource], elements: [element1])
        
        let material1 = geometry1.firstMaterial!
        
        material1.diffuse.contents = UIColor(red: 0.16, green: 0.69, blue: 0.69, alpha: 1.0)
        //material1.lightingModel = .lambert
        material1.transparency = 0.80
        //material1.transparencyMode = .dualLayer
        material1.fresnelExponent = 1.00
        //material1.reflective.contents = UIColor(white:0.00, alpha:1.0)
        //material1.specular.contents = UIColor(white:0.00, alpha:1.0)
        material1.shininess = 1.00
        let aNode = SCNNode()
        aNode.geometry = geometry1
        
        /*
         rotateY, rotateW
         forward -1, Double.pi/2
         backward 1, Double.pi/2
         left 0 , Double.pi
         right 1, Double.pi
         */
        
        switch nodeDirection {
        case "forward":
            rotateY = -1
            rotateW = Double.pi/2
            break
        case "backward":
            rotateY = 1
            rotateW = Double.pi/2
            break
        case "left":
            rotateY = 0
            rotateW = Double.pi
            break
        case "right":
            rotateY = 1
            rotateW = Double.pi
            break
        default:
            return
        }
        
        aNode.rotation = SCNVector4(0.0, rotateY, 0.0, rotateW)
        aNode.scale = SCNVector3(0.03, 0.03, 0.03)
        //aNode.position = SCNVector3(cameraPosition.x-x, cameraPosition.y-0.5, cameraPosition.z-z)
        aNode.position = SCNVector3(x, -0.1, z)
        //aNode.renderingOrder = -1
        //cubeNode.simdTransform = cameraPosition
        sceneView.scene.rootNode.addChildNode(aNode)
        
    }
    func resetSettionView() {
        self.sceneView.session.pause()
        self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        self.sceneView.session.run(configuratioon, options: [.resetTracking, .removeExistingAnchors])
    }
}
extension FindBookVC: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let transform = frame.camera.transform
        let angle = frame.camera.eulerAngles
        //cameraPosition = transform
        cameraPosition = transform.position()
        cameraAngle = SCNVector3Make(angle.x, angle.y, angle.z)
        //guard step > routePosition.count else { return }
        guard self.pathFindingStatus else {
            return
        }
        let cameraX = transform.position().x + 100
        let cameraZ = transform.position().z + 100
        let nextX = routePosition[step][0] + 100
        let nextZ = routePosition[step][1] + 100
        print("\(cameraX) \(cameraZ) \(nextX) \(nextZ) step: \(step)")
        if cameraX >= nextX - 0.5 && cameraX <= nextX + 0.5 && cameraZ >= nextZ - 0.5 && cameraZ <= nextZ + 0.5 {
            if step == routePosition.count-1 {
                //도착
                self.pathFindingStatus = false
                self.step = 0
                let alert = UIAlertController(title: "도착했습니다.", message: "탐색을 종료합니다.", preferredStyle: .alert)
                present(alert, animated: true)
                let when = DispatchTime.now() + 1
                DispatchQueue.main.asyncAfter(deadline: when){
                    alert.dismiss(animated: true, completion: nil)
                    self.resetSettionView()
                }
            } else {
                print(step)
                addNode(x: routePosition[step+1][0], z: routePosition[step+1][1], nodeDirection: routeDirection[step+1])
                step += 1
            }
        }
        
    }
}

extension matrix_float4x4 {
    func position() -> SCNVector3 {
        return SCNVector3(columns.3.x, columns.3.y, columns.3.z)
    }
}


//extension matrix_float4x4 {
//    func position() -> SCNVector3 {
//        return SCNVector3(columns.3.x, columns.3.y, columns.3.z)
//    }
//}
