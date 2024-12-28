//
//  AnnotationStickerView.swift
//  Easy Pdf Maker
//
//  Created by Mithilesh Kumar on 08/12/24.
//


import UIKit
import PDFKit

class AnnotationStickerView: UIView {
    enum ContentType {
        case image(UIImage)
        case text(String, UIFont)
        case shape(path: UIBezierPath, color: UIColor)
        case line(start: CGPoint, end: CGPoint, color: UIColor, width: CGFloat)
    }
    
    let overlayView: UIView
    let pdfPage: PDFPage
    let pdfView: PDFView
    let originalAnnotation: PDFAnnotation?
    
    var contentType: ContentType?
    
    private let selectionBorder = UIView()
    private var cornerHandles: [ResizeHandleView] = []
    private var edgeHandles: [ResizeHandleView] = []
    public var isSelected: Bool = false {
        didSet { updateSelectionUI() }
    }
    
    private var panGesture: UIPanGestureRecognizer!
    private var pinchGesture: UIPinchGestureRecognizer!
    private var rotationGesture: UIRotationGestureRecognizer!
    
    var rotationAngle: CGFloat = 0
    var scaleFactor: CGFloat = 1.0
    private var initialPinchScale: CGFloat = 1.0
    private var initialRotationAngle: CGFloat = 0.0
    var initialSize: CGSize = .zero
    var selectedAnnotation: PDFAnnotation?
    var textView: UITextView?
    
    init(pdfView: PDFView, image: UIImage, overlay: UIView, pdfPage: PDFPage) {
        self.pdfView = pdfView
        self.overlayView = overlay
        self.pdfPage = pdfPage
        self.originalAnnotation = nil
        super.init(frame: .zero)
        
        addGestureRecognizers()
        createSelectionUI()
        contentType = .image(image)
        addImage(image)
//        addImageAnnotation(image: image)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addImageAnnotation(image: UIImage) {
        guard let imageView = firstView(type: UIImageView.self) else {
            return
        }
        let frameAfterMargin = CGRect(x: center.x - imageView.bounds.width / 2,
                                      y: center.y - imageView.bounds.height / 2,
                                      width: imageView.bounds.width,
                                      height: imageView.bounds.height)
        let viewFrame = overlayView.convert(frameAfterMargin, to: pdfView)
        let annotationBounds = pdfView.convert(viewFrame, to: pdfPage)
        let annotation = ImageAnnotation(bounds: annotationBounds, image: image)
        annotation.currentRotationAngle = rotationAngle
        pdfPage.addAnnotation(annotation)
    }
    
    func addImage(_ image: UIImage) {
        var rect = frameForImage(image, within: overlayView)
        rect.origin.x = overlayView.center.x - rect.width / 2
        rect.origin.y = overlayView.center.y - rect.height / 2
        self.frame = rect
        
        let imageView = UIImageView(image: image)
        imageView.isUserInteractionEnabled = true
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: imageView.superview!.topAnchor, constant: 24),
            imageView.leadingAnchor.constraint(equalTo: imageView.superview!.leadingAnchor, constant: 24),
            imageView.trailingAnchor.constraint(equalTo: imageView.superview!.trailingAnchor, constant: -24),
            imageView.bottomAnchor.constraint(equalTo: imageView.superview!.bottomAnchor, constant: -24)
        ])
    }
    
    func addGestureRecognizers() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.addGestureRecognizer(tap)
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        panGesture.maximumNumberOfTouches = 1
        self.addGestureRecognizer(panGesture)
        
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinchGesture.delegate = self
        self.addGestureRecognizer(pinchGesture)
        
        rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        rotationGesture.delegate = self
        self.addGestureRecognizer(rotationGesture)
    }
    
    @objc
    func handleTap(_ gesture: UITapGestureRecognizer) {
        isSelected.toggle()
    }
    
    @objc
    func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let superview = self.superview, isSelected else { return }
        
        let translation = gesture.translation(in: superview)
        if gesture.state == .changed {
            var proposedCenter = CGPoint(x: self.center.x + translation.x,
                                         y: self.center.y + translation.y)
            gesture.setTranslation(.zero, in: superview)
            
            let w = self.bounds.width
            let h = self.bounds.height
            let sw = superview.bounds.width
            let sh = superview.bounds.height
            // minimum 30% of sticker should be in bound
            let minX = -0.3 * w
            let maxX = sw + 0.3 * w
            proposedCenter.x = max(minX, min(proposedCenter.x, maxX))
            // minimum 30% of sticker should be in bound
            let minY = -0.3 * h
            let maxY = sh + 0.3 * h
            proposedCenter.y = max(minY, min(proposedCenter.y, maxY))
            
            self.center = proposedCenter
            updateAnnotationBound()
        }
    }
    
    func createSelectionUI() {
        selectionBorder.layer.borderColor = UIColor.blue.cgColor
        selectionBorder.layer.borderWidth = 2.0
        selectionBorder.isHidden = true
        selectionBorder.isUserInteractionEnabled = false
        addSubview(selectionBorder)
        
        let corners: [ResizeHandleType] = [.topLeft, .topRight, .bottomLeft, .bottomRight]
        for corner in corners {
            let handle = ResizeHandleView()
            handle.handleType = corner
            handle.parentStickerView = self
            handle.isHidden = true
            addSubview(handle)
            cornerHandles.append(handle)
        }
        
        let edges: [ResizeHandleType] = [.topEdge, .bottomEdge, .leftEdge, .rightEdge]
        for edge in edges {
            let handle = ResizeHandleView()
            handle.handleType = edge
            handle.parentStickerView = self
            handle.isHidden = true
            addSubview(handle)
            edgeHandles.append(handle)
        }
    }
    
    func updateSelectionUI() {
        selectionBorder.isHidden = !isSelected
        for handle in cornerHandles + edgeHandles {
            handle.isHidden = !isSelected
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        selectionBorder.frame = self.bounds
        
        // Corner handles
        let cornerSize: CGFloat = 40
        cornerHandles[0].frame = CGRect(x: -cornerSize/2,
                                        y: -cornerSize/2,
                                        width: cornerSize,
                                        height: cornerSize) // top-left
        cornerHandles[1].frame = CGRect(x: bounds.width - cornerSize/2,
                                        y: -cornerSize/2,
                                        width: cornerSize,
                                        height: cornerSize) // top-right
        cornerHandles[2].frame = CGRect(x: -cornerSize/2,
                                        y: bounds.height - cornerSize/2,
                                        width: cornerSize,
                                        height: cornerSize) // bottom-left
        cornerHandles[3].frame = CGRect(x: bounds.width - cornerSize/2,
                                        y: bounds.height - cornerSize/2,
                                        width: cornerSize,
                                        height: cornerSize) // bottom-right
        
        let edgeWidthHorizontal: CGFloat = 32
        let edgeHeightHorizontal: CGFloat = 16
        
        let edgeWidthVertical: CGFloat = 16
        let edgeHeightVertical: CGFloat = 32
        
        // topEdge
        edgeHandles.first(where: { $0.handleType == .topEdge })?.frame = CGRect(
            x: (bounds.width - edgeWidthHorizontal)/2,
            y: -(edgeHeightHorizontal - selectionBorder.layer.borderWidth)/2,
            width: edgeWidthHorizontal,
            height: edgeHeightHorizontal
        )
        // bottomEdge
        edgeHandles.first(where: { $0.handleType == .bottomEdge })?.frame = CGRect(
            x: (bounds.width - edgeWidthHorizontal)/2,
            y: bounds.height - (edgeHeightHorizontal + selectionBorder.layer.borderWidth)/2,
            width: edgeWidthHorizontal,
            height: edgeHeightHorizontal
        )
        // leftEdge
        edgeHandles.first(where: { $0.handleType == .leftEdge })?.frame = CGRect(
            x: -(edgeWidthVertical - selectionBorder.layer.borderWidth) / 2,
            y: (bounds.height - edgeHeightVertical)/2,
            width: edgeWidthVertical,
            height: edgeHeightVertical
        )
        // rightEdge
        edgeHandles.first(where: { $0.handleType == .rightEdge })?.frame = CGRect(
            x: bounds.width - (edgeWidthVertical + selectionBorder.layer.borderWidth)/2,
            y: (bounds.height - edgeHeightVertical)/2,
            width: edgeWidthVertical,
            height: edgeHeightVertical
        )
        
        cornerHandles.forEach { view in
            view.layer.cornerRadius = cornerSize/2
            view.clipsToBounds = true
        }
        edgeHandles.forEach { view in
            view.layer.cornerRadius = 5
            view.clipsToBounds = true
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for handle in cornerHandles {
            let handlePoint = handle.convert(point, from: self)
            if handle.bounds.contains(handlePoint) {
                return handle
            }
        }
        for handle in edgeHandles {
            let handlePoint = handle.convert(point, from: self)
            if handle.bounds.contains(handlePoint) {
                return handle
            }
        }
        
        return super.hitTest(point, with: event)
    }
    
    private func frameForImage(_ image: UIImage?, within containerView: UIView) -> CGRect {
        guard let image = image else {
            return .zero
        }
        let imageAspect = image.size.width / image.size.height
        let viewAspect = containerView.bounds.width / containerView.bounds.height
        var frame: CGRect = .zero
        
        if viewAspect > imageAspect {
            let height = containerView.bounds.height
            let width = height * imageAspect
            let x = (containerView.bounds.width - width) / 2
            frame = CGRect(x: x, y: 0, width: width, height: height)
        } else {
            let width = containerView.bounds.width
            let height = width / imageAspect
            let y = (containerView.bounds.height - height) / 2
            frame = CGRect(x: 0, y: y, width: width, height: height)
        }
        let size = CGSize(width: frame.size.width * 0.4,
                          height: frame.size.height * 0.4)
        
        return CGRect(origin: frame.origin,
                      size: size)
    }
    
    @objc
    func handlePinch(_ gesture: UIPinchGestureRecognizer) {
//        switch gesture.state {
//        case .began:
//            initialPinchScale = scaleFactor
//            initialSize = bounds.size
//        case .changed:
//            let newScale = initialPinchScale * gesture.scale
//            scaleFactor = newScale
//            updateSizeForScale(newScale)
//        default:
//            break
//        }
    }
    
    @objc
    func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        switch gesture.state {
        case .began:
            initialRotationAngle = rotationAngle
        case .changed:
            let newRotation = initialRotationAngle + gesture.rotation
            applyTransforms(rotation: newRotation)
        default:
            break
        }
    }
    
    func updateSizeForScale(_ scale: CGFloat) {
        let newWidth = initialSize.width * scale
        let newHeight = initialSize.height * scale
        if let textView {
            let maxWidth = newWidth
            let fittingSize = CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude)
            let measuredSize = textView.sizeThatFits(fittingSize)
            self.bounds = CGRect(x: 0, y: 0, width: newWidth, height: measuredSize.height)
        } else {
            self.bounds = CGRect(x: 0, y: 0, width: newWidth, height: newHeight)
            updateAnnotationBound()
        }
    }
    
    func updateAnnotationBound() {
        if let annotation = self.selectedAnnotation {
            let viewFrame = overlayView.convert(self.frame, to: pdfView)
            annotation.bounds = pdfView.convert(viewFrame, to: pdfPage)
        }
    }
    
    func applyTransforms(rotation: CGFloat) {
        self.rotationAngle = rotation
        let transform = CGAffineTransform(rotationAngle: rotationAngle)
        self.transform = transform
        if let imgAnnotation = self.selectedAnnotation as? ImageAnnotation {
            imgAnnotation.currentRotationAngle = rotation
            updateAnnotationBound()
        }
    }
}

extension AnnotationStickerView: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if (gestureRecognizer is UIRotationGestureRecognizer && otherGestureRecognizer is UIPinchGestureRecognizer) ||
            (gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIRotationGestureRecognizer) {
            return true
        }
        return false
    }
}
