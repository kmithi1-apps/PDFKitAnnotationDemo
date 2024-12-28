//
//  ViewController.swift
//  AnnotationDemo
//
//  Created by Mithilesh Kumar on 28/12/24.
//

import UIKit
import PDFKit

class ViewController: UIViewController {
    var pdf: PDFDocument = PDFDocument()
    var page: PDFPage = PDFPage()
    
    private lazy var overlay: AnnotationEditorOverlayView = {
        let view = AnnotationEditorOverlayView(pdfPage: page, pdfView: pdfView)
        return view
    }()
    
    private lazy var pdfView: PDFView = {
        let view = PDFView()
        view.autoScales = true
        view.isInMarkupMode = true
        view.displayDirection = .vertical
        view.displayMode = .singlePage
        view.displaysPageBreaks = false
        view.pageOverlayViewProvider = self
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Annotation Demo"
        view.addSubview(pdfView)
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])
        
        guard let url = Bundle.main.url(forResource: "testFile", withExtension: "pdf"),
        let data = try? Data(contentsOf: url),
            let document = PDFDocument(data: data) else {
                return
            }
        self.pdf = document
        self.page = document.page(at: 0)!
        pdfView.document = document
        
        disableBounceAndScroll()
    }
    
    func disableBounceAndScroll() {
        // Disable scrolling completely to ensure no movement
        if let scrollView = pdfView.subviews.compactMap({ $0 as? UIScrollView }).first {
            scrollView.isScrollEnabled = false
            scrollView.bounces = false
            scrollView.alwaysBounceVertical = false
            scrollView.alwaysBounceHorizontal = false
        }
    }
}

extension ViewController: PDFPageOverlayViewProvider {
    func pdfView(_ view: PDFView, overlayViewFor page: PDFPage) -> UIView? {
        return overlay
    }
}

extension ViewController {
    @IBAction func addImageButtonTapped() {
        overlay.addImage(UIImage(resource: ImageResource.annotationImg))
    }
}
