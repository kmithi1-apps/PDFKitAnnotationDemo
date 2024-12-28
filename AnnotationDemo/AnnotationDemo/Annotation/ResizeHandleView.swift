//
//  ResizeHandleView.swift
//  Easy Pdf Maker
//
//  Created by Mithilesh Kumar on 08/12/24.
//


import UIKit
enum ResizeHandleType {
    // Corners
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    // Edges
    case topEdge
    case bottomEdge
    case leftEdge
    case rightEdge
}

class ResizeHandleView: UIView {
    weak var parentStickerView: AnnotationStickerView?
    var handleType: ResizeHandleType = .topLeft
    private var panGesture: UIPanGestureRecognizer!
    private var initialScaleFactor: CGFloat = 1.0
    private var initialBounds: CGRect = .zero
    private var initialHandlePosition: CGPoint = .zero
    private var annotationCenter: CGPoint = .zero
    private var initialCenter: CGPoint = .zero
    private var initialTouchPoint: CGPoint = .zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.blue
        self.layer.borderColor = UIColor.blue.cgColor
        self.layer.borderWidth = 2
        self.isUserInteractionEnabled = true
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.addGestureRecognizer(panGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let parent = parentStickerView,
              let superview = parent.superview else { return }
        
        let location = gesture.location(in: superview)
        
        switch gesture.state {
        case .began:
            parent.initialSize = parent.bounds.size
            parent.superview?.bringSubviewToFront(parent)
            initialScaleFactor = parent.scaleFactor
            initialBounds = parent.bounds
            annotationCenter = parent.center
            initialHandlePosition = convert(self.bounds.center, to: superview)

            initialCenter = parent.center
            initialTouchPoint = location
            
            superview.bringSubviewToFront(parent)
            
        case .changed:
            // Delta from the original touch
            let deltaX = location.x - initialTouchPoint.x
            let deltaY = location.y - initialTouchPoint.y
            
            switch handleType {
                
            case .topLeft, .topRight, .bottomLeft, .bottomRight:
                let currentDistance = distance(from: annotationCenter, to: location)
                let initialDistance = distance(from: annotationCenter, to: initialHandlePosition)
                let scaleChange = currentDistance / initialDistance

                let newScale = initialScaleFactor * scaleChange
                parent.updateSizeForScale(newScale)
                
            case .topEdge:
                let newHeight = initialBounds.height - deltaY
                if newHeight > 20 {
                    parent.bounds.size.height = newHeight
                    parent.center.y = initialCenter.y + (deltaY / 2)
                }
                parent.updateAnnotationBound()
                
            case .bottomEdge:
                let newHeight = initialBounds.height + deltaY
                if newHeight > 20 {
                    parent.bounds.size.height = newHeight
                    parent.center.y = initialCenter.y + (deltaY / 2)
                }
                parent.updateAnnotationBound()
                
            case .leftEdge:
                let newWidth = initialBounds.width - deltaX
                if newWidth > 20 {
                    parent.bounds.size.width = newWidth
                    parent.center.x = initialCenter.x + (deltaX / 2)
                }
                parent.updateAnnotationBound()
                
            case .rightEdge:
                let newWidth = initialBounds.width + deltaX
                if newWidth > 20 {
                    parent.bounds.size.width = newWidth
                    parent.center.x = initialCenter.x + (deltaX / 2)
                }
                parent.updateAnnotationBound()
            }
            
        default:
            break
        }
    }
    
    private func distance(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(dx * dx + dy * dy)
    }
}

private extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}
