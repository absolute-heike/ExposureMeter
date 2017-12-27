//
//  RecordButton.swift
//  ExposureTracker
//
//  Created by Michael Berg on 27.12.17.
//  Copyright © 2017 Michael Berg. All rights reserved.
//

import Foundation
import UIKit

class RecordButton: UIButton {
    
    enum Status {
        case record
        case stop
    }
    
    var status: Status = .record {
        didSet {
            switch self.status {
            case .record:
                self.backgroundColor = .red
            case .stop:
                self.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
            }
            
            // update cornerRadius
            self.setNeedsLayout()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 4
    }
    
    func set(status: Status, animated: Bool = false) {
        
        guard animated else {
            self.status = status
            return
        }
        
        let duration = 0.2
        
        let cornerAnimation = CABasicAnimation(keyPath: "cornerRadius")
        cornerAnimation.fromValue = self.status == .record ? self.frame.width * 0.5 : 0.0
        cornerAnimation.toValue = status == .record ? self.frame.width * 0.5 : 0.0
        cornerAnimation.duration = duration
        self.layer.add(cornerAnimation, forKey: "cornerRadius")
        
        // animate backgroundColor
        UIView.animate(withDuration: duration) {
            self.status = status
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = self.status == .record ? self.frame.width * 0.5 : 0.0
    }
}
