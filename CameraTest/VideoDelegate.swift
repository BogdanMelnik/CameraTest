//
//  VideoDelegate.swift
//  CameraTest
//
//  Created by Admin on 8/15/16.
//  Copyright © 2016 Yohoho. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

// Video Delegate
class VideoDelegate : NSObject, AVCaptureFileOutputRecordingDelegate
{
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        print("Capture output : finish recording to \(outputFileURL)")
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        print("Capture output: started recording to \(fileURL)")
    }
    
}