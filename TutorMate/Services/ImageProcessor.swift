import UIKit

class ImageProcessor {
    static func resizeImage(_ image: UIImage, maxSize: CGFloat, quality: CGFloat) -> (Data?, String)? {
        var newSize = image.size
        
        if newSize.width > newSize.height {
            if newSize.width > maxSize {
                newSize.height = (newSize.height * maxSize) / newSize.width
                newSize.width = maxSize
            }
        } else {
            if newSize.height > maxSize {
                newSize.width = (newSize.width * maxSize) / newSize.height
                newSize.height = maxSize
            }
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let resized = resizedImage,
              let jpegData = resized.jpegData(compressionQuality: quality) else {
            return nil
        }
        
        let base64String = jpegData.base64EncodedString()
        return (jpegData, base64String)
    }
    
    static func createFileTypeIcon(extension ext: String) -> UIImage {
        let size = CGSize(width: 80, height: 80)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Background
            UIColor(red: 0.28, green: 0.33, blue: 0.41, alpha: 1.0).setFill()
            let roundedRect = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 8)
            roundedRect.fill()
            
            // Document shape
            UIColor(red: 0.97, green: 0.98, blue: 0.99, alpha: 1.0).setFill()
            let docPath = UIBezierPath()
            docPath.move(to: CGPoint(x: 20, y: 8))
            docPath.addLine(to: CGPoint(x: 52, y: 8))
            docPath.addLine(to: CGPoint(x: 64, y: 20))
            docPath.addLine(to: CGPoint(x: 64, y: 72))
            docPath.addLine(to: CGPoint(x: 20, y: 72))
            docPath.close()
            docPath.fill()
            
            // Extension text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor(red: 0.12, green: 0.16, blue: 0.23, alpha: 1.0)
            ]
            let text = ext as NSString
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: 50,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
}