//
//  UIVIew+Util.swift
//  AnnotationDemo
//
//  Created by Mithilesh Kumar on 28/12/24.
//

import UIKit

extension UIView {
    /// Remove all subview
    func removeAllSubviews() {
        subviews.forEach { $0.removeFromSuperview() }
    }
    
    /// Remove all subview with specific type
    func removeAllSubviews<T: UIView>(type: T.Type) {
        subviews
            .filter { $0.isMember(of: type) }
            .forEach { $0.removeFromSuperview() }
    }
    
    func firstView<T: UIView>(type: T.Type) -> T? {
        return subviews.first { $0.isMember(of: type) } as? T
    }
}
