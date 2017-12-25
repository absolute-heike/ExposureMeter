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
    
    struct CaptureSample {
        let brightness: Float
        let timeInterval: Double
    }
    
    var camera: AVCaptureDevice?
    
    var lastSecondSamples = [CaptureSample]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard
            let camera = AVCaptureDevice.default(for: .video)
        else {
            return
        }
        
        self.camera = camera
        
        guard let input = try? AVCaptureDeviceInput(device: camera) else { return }
        
        let session = AVCaptureSession()
        session.addInput(input)
        
        camera.configureCameraForHighestFrameRate()
        
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = self.view.bounds
        self.view.layer.addSublayer(preview)
        
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = false
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "output queue"))
        session.addOutput(output)
        
        session.startRunning()
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // frame was generated
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let sample = CaptureSample(brightness: sampleBuffer.brightness, timeInterval: timestamp.seconds)
        
        self.lastSecondSamples.append(sample)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // frame was dropped
        print("FRAME WAS DROPPED")
    }
}

extension CMSampleBuffer {
    
    var brightness: Float {
        guard
            let metadataDict = CMCopyDictionaryOfAttachments(nil, self, kCMAttachmentMode_ShouldPropagate) as? [String: Any],
            let exifMetadata = metadataDict[String(kCGImagePropertyExifDictionary)] as? [String: Any],
            let brightnessValue = exifMetadata[String(kCGImagePropertyExifBrightnessValue)] as? Float
        else { return 0.0 }
        
        return brightnessValue
    }
}

extension AVCaptureDevice {
    
    func configureCameraForHighestFrameRate() {
        
        var bestFormat: Format?
        var bestRange: AVFrameRateRange?
        
        for format in self.formats {
            for range in format.videoSupportedFrameRateRanges {
                // sort by highest framerate, choose the lowest resolution
                if range.maxFrameRate >= (bestRange?.maxFrameRate ?? 0.0) {
                    bestFormat = format
                    bestRange = range
                }
            }
        }
        
        guard
            let format = bestFormat,
            let range = bestRange
        else { return }
        
        do {
            try self.lockForConfiguration()
            self.activeFormat = format
            self.focusMode = .autoFocus
            self.exposureMode = .autoExpose
            self.activeVideoMinFrameDuration = range.minFrameDuration
            self.activeVideoMaxFrameDuration = range.minFrameDuration
            self.unlockForConfiguration()
        } catch {
            assertionFailure("could not set the highest supported framerate")
        }
    }
}
