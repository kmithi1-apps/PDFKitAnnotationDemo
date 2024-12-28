//
//  ImageAnnotation.swift
//  Easy Pdf Maker
//
//  Created by Mithilesh Kumar on 24/12/24.
//

import PDFKit
import UIKit

final class ImageAnnotation: PDFAnnotation {
    var image: UIImage
    var currentRotationAngle: CGFloat = 0.0
    
    init(bounds: CGRect, image: UIImage) {
        self.image = image
        super.init(bounds: bounds, forType: .stamp, withProperties: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        context.saveGState()
        let midX = bounds.midX
        let midY = bounds.midY
        context.translateBy(x: midX, y: midY)
        context.rotate(by: -currentRotationAngle)
        context.translateBy(x: -midX, y: -midY)
        
        guard let cgImage = image.cgImage else { return }
        context.draw(cgImage, in: bounds)
        context.restoreGState()
    }
}
