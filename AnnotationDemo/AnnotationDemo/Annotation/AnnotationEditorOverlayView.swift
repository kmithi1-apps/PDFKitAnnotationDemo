//
//  AnnotationEditorOverlayView.swift
//  Easy Pdf Maker
//
//  Created by Mithilesh Kumar on 26/12/24.
//

import UIKit
import PencilKit
import PDFKit

final class AnnotationEditorOverlayView: UIView {
    private let page: PDFPage
    private let pdfView: PDFView
    var stickerView: AnnotationStickerView?
    
    init(pdfPage: PDFPage, pdfView: PDFView) {
        self.page = pdfPage
        self.pdfView = pdfView
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        setupGestures()
    }
    
    func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.addGestureRecognizer(tap)
    }
    
    func addImage(_ image: UIImage) {
        let imageSticker = AnnotationStickerView(pdfView: pdfView,
                                                 image: image,
                                                 overlay: self,
                                                 pdfPage: page)
        self.addSubview(imageSticker)
        imageSticker.isSelected = true
        stickerView = imageSticker
    }
    
    func addAnnotation() {
        guard let stickerView else { return }
        switch stickerView.contentType {
        case .image(let uIImage):
            stickerView.addImageAnnotation(image: uIImage)
        default:
            break
        }
        stickerView.removeFromSuperview()
        self.stickerView = nil
    }
    
    @objc
    func handleTap(_ gesture: UITapGestureRecognizer) {
        if let stickerView {
            addAnnotation()
            return
        }
    }
}

