//
//  ViewController.swift
//  ExposureTracker
//
//  Created by Michael Berg on 24.12.17.
//  Copyright © 2017 Michael Berg. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet private weak var recordButton: UIButton!
    
    let tracker = ExposureTracker()
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        if let layer = self.tracker.previewLayer {
            layer.frame = self.view.layer.bounds
            self.view.layer.addSublayer(layer)
        }
        
        self.recordButton.layer.cornerRadius = self.recordButton.frame.size.width * 0.5
        self.recordButton.layer.borderColor = UIColor.white.cgColor
        self.recordButton.layer.borderWidth = 4
    }
}

extension ViewController {
    
    @IBAction func tappedRecordButton(_ sender: Any) {
        
        let recordSamples = true
        
        if recordSamples {
//            self.samples.removeAll()
        }
        
        self.recordButton.layer.cornerRadius = recordSamples ? 0.0 : (self.recordButton.frame.size.width * 0.5)
    }
}
