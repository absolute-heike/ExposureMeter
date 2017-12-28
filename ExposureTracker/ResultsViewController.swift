//
//  ResultsViewController.swift
//  ExposureTracker
//
//  Created by Michael Berg on 27.12.17.
//  Copyright © 2017 Michael Berg. All rights reserved.
//

import Foundation
import UIKit

private extension TimeInterval {
    
    var milliseconds: Double {
        return self * 1000
    }
}

private extension ExposureSample {
    
    var title: String {
        return String(format: "%.1f", self.duration.milliseconds)
    }
}

class ResultsViewController: UITableViewController {
    
    var frameRate: Double?
    private var samples: [ExposureSample]?
    private var rawSamples: [RawSample]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Results"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareTapped))
        self.tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func setup(from samples: [ExposureSample], rawSamples: [RawSample]? = nil) {
        self.samples = samples
        self.rawSamples = rawSamples
        
        self.tableView.reloadData()
    }
}

extension ResultsViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.samples?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        guard let sample = self.samples?[indexPath.row] else {
            return cell
        }
        
        var resolutionString = "¯\\_(ツ)_/¯"
        if let frameRate = self.frameRate {
            resolutionString = String(format: "%.1fms", 1.0 / frameRate * 1000)
        }
        
        cell.textLabel?.text = "Exposure Duration: \(sample.title) ms (± \(resolutionString))"
        cell.detailTextLabel?.text = String(format: "Sample #%02d", indexPath.row + 1)
        
        return cell
    }
}

private extension ResultsViewController {
    
    @objc func shareTapped() {
        
        let actionController = UIAlertController(title: "Share Results", message: nil, preferredStyle: .actionSheet)
        actionController.addAction(UIAlertAction(title: "Export as Text", style: .default, handler: { [weak self] _ in
            if let string = self?.samples?.exportString {
                self?.share(string: string)
            }
        }))
        actionController.addAction(UIAlertAction(title: "CSV", style: .default, handler: { [weak self] _ in
            
            if let csv = self?.samples?.csvString {
                self?.share(csv: csv)
            }
        }))
        actionController.addAction(UIAlertAction(title: "Raw CSV", style: .default, handler: { [weak self] _ in
            
            if let csv = self?.rawSamples?.csvString {
                self?.share(csv: csv)
            }
        }))
        actionController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(actionController, animated: true, completion: nil)
    }
    
    func share(string: String) {
        let shareController = UIActivityViewController(activityItems: [string], applicationActivities: nil)
        self.present(shareController, animated: true, completion: nil)
    }
    
    func share(csv: String) {
        let fileName = "export.csv"
        let path = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        do {
            try csv.write(to: path, atomically: true, encoding: .utf8)
            
            let shareController = UIActivityViewController(activityItems: [path], applicationActivities: nil)
            self.present(shareController, animated: true, completion: nil)
        } catch {
            print("something went wrong")
        }
    }
}

extension Array where Element == RawSample {
    
    var csvString: String {
        let csv = self.map { "\($0.brightness),\($0.timestamp)" }.joined(separator: "\n")
        
        return "brightness,timestamp (in seconds)\n" + csv
    }
}

extension Array where Element == ExposureSample {
    
    var exportString: String {
        var string = "Exposure Samples\n\n"
        
        for (index, sample) in self.enumerated() {
            let indexString = String(format: "%02d", index + 1)
            string.append("(Sample #\(indexString)) Duration: \(sample.title) ms\n")
        }
        return string
    }
    
    var csvString: String {
        let csv = self.map { "\($0.duration)" }.joined(separator: "\n")
        
        return "duration (in seconds)\n" + csv
    }
}
