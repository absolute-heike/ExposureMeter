//
//  ExposureTracker.swift
//  ExposureTracker
//
//  Created by Michael Berg on 27.12.17.
//  Copyright © 2017 Michael Berg. All rights reserved.
//

import Foundation
import AVFoundation

struct RawSample {
    let brightness: Float
    let timestamp: Double
}

struct ExposureSample {
    
    let startSample: RawSample
    let endSample: RawSample
    
    var duration: TimeInterval {
        return endSample.timestamp - startSample.timestamp
    }
}

class ExposureTracker: NSObject {
    
    private var camera: AVCaptureDevice?
    
    private(set) var rawSamples = [RawSample]()
    private var exposureSamples = [ExposureSample]()
    private(set) var record = false
    
    private var lastOnSample: RawSample?
    
    private(set) var previewLayer: CALayer?
    
    private(set) var frameRate: Double = 0.0
    
    override init() {
        super.init()
        
        guard
            let camera = AVCaptureDevice.default(for: .video)
        else {
            return
        }
        
        self.camera = camera
        
        guard let input = try? AVCaptureDeviceInput(device: camera) else { return }
        
        let session = AVCaptureSession()
        session.addInput(input)
        
        self.frameRate = camera.configureForHighestFrameRate()
        
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        self.previewLayer = preview
        
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = false
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "output queue"))
        session.addOutput(output)
        
        session.startRunning()
    }
}

extension ExposureTracker {
    
    func startTracking() {
        self.lastOnSample = nil
        self.rawSamples.removeAll()
        self.exposureSamples.removeAll()
        
        self.record = true
    }
    
    func stopTracking() -> [ExposureSample] {
        self.record = false
        
        return self.exposureSamples
    }
}

extension ExposureTracker: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard self.record else { return }
        
        // frame was generated
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let sample = RawSample(brightness: sampleBuffer.brightness, timestamp: timestamp.seconds)
        
        guard let lastSample = self.rawSamples.last else {
            self.rawSamples.append(sample)
            return
        }
        
        let delta = sample.brightness - lastSample.brightness
        if delta > 0.5 {
            self.lastOnSample = sample
        } else if delta < -0.5, let lastOnSample = self.lastOnSample {
            self.exposureSamples.append(ExposureSample(startSample: lastOnSample, endSample: sample))
            
            self.lastOnSample = nil
        }
        
        self.rawSamples.append(sample)
    }
}

private extension CMSampleBuffer {
    
    var brightness: Float {
        guard
            let metadataDict = CMCopyDictionaryOfAttachments(nil, self, kCMAttachmentMode_ShouldPropagate) as? [String: Any],
            let exifMetadata = metadataDict[String(kCGImagePropertyExifDictionary)] as? [String: Any],
            let brightnessValue = exifMetadata[String(kCGImagePropertyExifBrightnessValue)] as? Float
        else { return 0.0 }
        
        return brightnessValue
    }
}

private extension AVCaptureDevice {
    
    func configureForHighestFrameRate() -> Double {
        
        var bestFormat: Format?
        var bestRange: AVFrameRateRange?
        var frameRate: Double = 0.0
        
        for format in self.formats {
            for range in format.videoSupportedFrameRateRanges {
                // sort by highest framerate, choose the lowest resolution
                if range.maxFrameRate >= (bestRange?.maxFrameRate ?? 0.0) {
                    bestFormat = format
                    bestRange = range
                    frameRate = range.maxFrameRate
                }
            }
        }
        
        guard
            let format = bestFormat,
            let range = bestRange
        else { return frameRate }
        
        do {
            try self.lockForConfiguration()
            self.activeFormat = format
            self.activeVideoMinFrameDuration = range.minFrameDuration
            self.activeVideoMaxFrameDuration = range.minFrameDuration
            self.setFocusModeLocked(lensPosition: 0.0, completionHandler: nil)
            self.setExposureModeCustom(duration: AVCaptureDevice.currentExposureDuration, iso: format.maxISO, completionHandler: nil)
            self.unlockForConfiguration()
        } catch {
            assertionFailure("could not set the highest supported framerate")
        }
        
        return frameRate
    }
}
