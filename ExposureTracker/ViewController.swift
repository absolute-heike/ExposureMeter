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
    
    @IBOutlet private weak var recordButton: RecordButton!
    
    let tracker = ExposureTracker()
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        if let layer = self.tracker.previewLayer {
            layer.frame = self.view.layer.bounds
            self.view.layer.insertSublayer(layer, at: 0)
        }
        
        self.recordButton.layer.cornerRadius = self.recordButton.frame.size.width * 0.5
        self.recordButton.layer.borderColor = UIColor.white.cgColor
        self.recordButton.layer.borderWidth = 4
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
}

extension ViewController {
    
    @IBAction func tappedRecordButton(_ sender: Any) {
        
        if self.tracker.record {
            self.recordButton.set(status: .record, animated: true)
            
            let samples = self.tracker.stopTracking()
            
            let controller = ResultsViewController(style: .grouped)
            controller.frameRate = self.tracker.frameRate
            controller.setup(from: samples, rawSamples: self.tracker.rawSamples)
            self.navigationController?.pushViewController(controller, animated: true)
        } else {
            self.recordButton.set(status: .stop, animated: true)
            self.tracker.startTracking()
        }
    }
}
