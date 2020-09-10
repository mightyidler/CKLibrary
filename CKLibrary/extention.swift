//
//  extention.swift
//  CKLibrary
//
//  Created by mightyidler on 2020/07/25.
//

import UIKit

// UICOLOR RGB EXTENTION
extension UIColor {
    class func UIColorRGB (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

//SKETCH SHADOW EXTENTION
extension CALayer {
    func applySketchShadow(
        color: UIColor = .black,
        alpha: Float = 0.5,
        x: CGFloat = 0,
        y: CGFloat = 2,
        blur: CGFloat = 4,
        spread: CGFloat = 0)
    {
        shadowColor = color.cgColor
        shadowOpacity = alpha
        shadowOffset = CGSize(width: x, height: y)
        shadowRadius = blur / 2.0
        if spread == 0 {
            shadowPath = nil
        } else {
            let dx = -spread
            let rect = bounds.insetBy(dx: dx, dy: dx)
            shadowPath = UIBezierPath(rect: rect).cgPath
        }
    }
}

//UIBUTTON STATE COLOR CHANGE EXTENTION
extension UIButton {
    func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        UIGraphicsBeginImageContext(CGSize(width: 1.0, height: 1.0))
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setFillColor(color.cgColor)
        context.fill(CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0))
        
        let backgroundImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.setBackgroundImage(backgroundImage, for: state)
    }
    
    
}

extension UIView {
    func shake() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 3
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x:self.center.x - 10, y:self.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x:self.center.x + 10, y:self.center.y))
        self.layer.add(animation, forKey: "position")
    }
}

extension UserDefaults {
    
    static func exists(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }

}

extension UIViewController {
    func trimBlankChar(string: String) -> String {
        return string.trimmingCharacters(in: [" "])
    }
    
    func removeSpecialChar(string: String) -> String {
        return string.components(separatedBy: ["=", "+", "/", ":", ",", ".", ";", "(", ")"]).joined()
    }
}


extension UIView {
    func addTopBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: width)
        self.layer.addSublayer(border)
    }

    func addRightBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: self.frame.size.width - width, y: 0, width: width, height: self.frame.size.height)
        self.layer.addSublayer(border)
    }

    func addBottomBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 0, y: self.frame.size.height - width, width: self.frame.size.width, height: width)
        self.layer.addSublayer(border)
    }

    func addLeftBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 0, y: 0, width: width, height: self.frame.size.height)
        self.layer.addSublayer(border)
    }
    
}


extension URL {
        var attributes: [FileAttributeKey : Any]? {
            do {
                return try FileManager.default.attributesOfItem(atPath: path)
            } catch let error as NSError {
                print("FileAttribute error: \(error)")
            }
            return nil
        }

        var fileSize: UInt64 {
            return attributes?[.size] as? UInt64 ?? UInt64(0)
        }

        var fileSizeString: String {
            return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
        }

        var creationDate: Date? {
            return attributes?[.creationDate] as? Date
        }
}


extension UIImageView {
    func isNoImage(url: URL) -> Bool {
        let source = CGImageSourceCreateWithURL(url as CFURL, nil)
        let imageHeader = CGImageSourceCopyPropertiesAtIndex(source!, 0, nil)! as NSDictionary;
        if imageHeader.value(forKey: "PixelHeight") as! Int == 91
            && imageHeader.value(forKey: "PixelWidth") as! Int == 61 {
            return true
        } else {
            return false
        }
    }
}
