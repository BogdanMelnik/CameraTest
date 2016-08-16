//
//  CameraViewController.swift
//  CameraTest
//
//  Created by Admin on 8/15/16.
//  Copyright © 2016 Yohoho. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import AssetsLibrary

enum Camera {
    case front
    case back
}

enum RecordMode{
    case photo
    case video
}

class CameraViewController: UIViewController {

    
    // UI values
    @IBOutlet weak var previewLayerView: UIView!
    
    @IBOutlet weak var changeCameraButton: UIBarButtonItem!
    @IBOutlet weak var changeRecordModeButton: UIBarButtonItem!
    
    @IBOutlet weak var recordButton: UIButton!
    
    // Camera values
    let captureSession = AVCaptureSession()

    var frontCaptureDevice:AVCaptureDevice?
    var backCaptureDevice:AVCaptureDevice?
    var previewLayer:AVCaptureVideoPreviewLayer?
    var stillImageOutput: AVCaptureStillImageOutput!
    var currentCamera: Camera = .front
    var currentRecordMode: RecordMode = .photo
    
    // Video recording values
    var isVideoRecording = false
    var videoFileOutput = AVCaptureMovieFileOutput()
    
    // Blur effect values
    var blurredEffectView: UIVisualEffectView?
    
    
    // Timer values
    @IBOutlet weak var counterLabel: UILabel!
    
    var timer: NSTimer!
    var counter: Double!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Timer vaules inint
        self.timer = NSTimer.init()
        self.counter = 0
        
        // White status bar
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
        
        // Make navigation bar transparent
        let navigationBar:UINavigationBar! =  self.navigationController?.navigationBar
        navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        navigationBar.shadowImage = UIImage()
        navigationBar.alpha = 0.0
        
        self.initCaptureDevices()
        self.initOutput()
        self.beginCaptureSession()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    func initCaptureDevices() {
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        let devices = AVCaptureDevice.devices()
        for device in devices {
            if (device.hasMediaType(AVMediaTypeVideo)) {
                if(device.position == AVCaptureDevicePosition.Front) {
                    self.frontCaptureDevice = device as? AVCaptureDevice
                    if self.frontCaptureDevice != nil {
                        print("Front capture device found!")
                    }
                }
                if(device.position == AVCaptureDevicePosition.Back) {
                    self.backCaptureDevice = device as? AVCaptureDevice
                    if self.backCaptureDevice != nil {
                        print("Back capture device found!")
                    }
                }
            }
        }
    }
    
    func initOutput() {
        // Initialize output
        self.stillImageOutput = AVCaptureStillImageOutput()
        self.stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        
        if self.captureSession.canAddOutput(stillImageOutput) {
            self.captureSession.addOutput(stillImageOutput)
        }
    }
    
    func beginCaptureSession() {
        do {
            self.captureSession.addInput(try AVCaptureDeviceInput(device: self.frontCaptureDevice))
        } catch _ {
            // Handle errors here...
        }
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer?.frame = self.view.bounds;
        //self.previewLayer?.transform = CATransform3DMakeScale(1.35, 1.35, 1);
        self.previewLayerView.layer.addSublayer(self.previewLayer!)
        
        // Blured background with circle layer mask inside
        self.blurredEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
        self.blurredEffectView!.frame = self.view.bounds
        
        self.blurredEffectView!.layer.mask = updateMaskLayer()
        self.blurredEffectView!.clipsToBounds = true
        
        self.previewLayerView.addSubview(blurredEffectView!)
        self.captureSession.startRunning()
    }
    
    func updateMaskLayer() -> CAShapeLayer {
        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(rect: self.view.bounds)
        let currentDevice: UIDevice = UIDevice.currentDevice()
        let orientation: UIDeviceOrientation = currentDevice.orientation
        var radius : CGFloat = 0
        if (orientation.isLandscape) {
            radius = self.view.bounds.height/2.15
        }
        if (orientation.isPortrait){
            radius = self.view.bounds.width/2.15
        }
        path.addArcWithCenter(self.view.center, radius: radius, startAngle: 0.0, endAngle: CGFloat(2*M_PI), clockwise: true)
        maskLayer.path = path.CGPath
        maskLayer.fillRule = kCAFillRuleEvenOdd
        return maskLayer
    }
    
    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        //Turn of animations
        CATransaction.begin()
        CATransaction.setDisableActions(true)
            layer.videoOrientation = orientation
            self.previewLayer!.frame = UIScreen.mainScreen().bounds
            self.blurredEffectView!.frame = UIScreen.mainScreen().bounds
            self.blurredEffectView!.layer.mask = updateMaskLayer()
            self.blurredEffectView!.clipsToBounds = true
        CATransaction.commit()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let connection =  self.previewLayer?.connection  {
            let currentDevice: UIDevice = UIDevice.currentDevice()
            let orientation: UIDeviceOrientation = currentDevice.orientation
            let previewLayerConnection : AVCaptureConnection = connection
            if (previewLayerConnection.supportsVideoOrientation) {
                switch (orientation) {
                case .Portrait: updatePreviewLayer(previewLayerConnection, orientation: .Portrait)
                    break
                case .LandscapeRight: updatePreviewLayer(previewLayerConnection, orientation: .LandscapeLeft)
                    break
                case .LandscapeLeft: updatePreviewLayer(previewLayerConnection, orientation: .LandscapeRight)
                    break
                case .PortraitUpsideDown: updatePreviewLayer(previewLayerConnection, orientation: .Portrait)
                    break
                default: updatePreviewLayer(previewLayerConnection, orientation: .Portrait)
                    break
                }
            }
        }

    }
    
//    //Turn off all animations
//    override func viewWillTransitionToSize(size:CGSize,
//                                           withTransitionCoordinator coordinator:UIViewControllerTransitionCoordinator)
//    {
//        coordinator.animateAlongsideTransition(nil, completion:
//            {_ in
//                UIView.setAnimationsEnabled(true)
//        })
//        UIView.setAnimationsEnabled(false)
//        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator);
//    }
    
    
    @IBAction func changeCamera(sender: AnyObject) {
        // Delete old input
        for input in self.captureSession.inputs {
            self.captureSession.removeInput(input as! AVCaptureInput)
        }
        
        // Add new input
        if (self.currentCamera == Camera.front) {
            self.currentCamera = Camera.back
            self.changeCameraButton.image = UIImage(named: "ic_camera_front_white")
            do {
                self.captureSession.addInput(try AVCaptureDeviceInput(device: self.backCaptureDevice))
            } catch _ {
                // Handnle errors here...
            }
            print("Current camera changed to: \(currentCamera)")
            return
        }
        if (self.currentCamera == Camera.back) {
            self.currentCamera = Camera.front
            self.changeCameraButton.image = UIImage(named: "ic_camera_rear_white")
            do {
                self.captureSession.addInput(try AVCaptureDeviceInput(device: self.frontCaptureDevice))
            } catch _ {
                // Handle errors here...
            }
            print("Current camera changed to: \(currentCamera)")
            return
        }
    }
    
    @IBAction func changeRecordMode(sender: AnyObject) {
        if(self.currentRecordMode==RecordMode.photo) {
            self.currentRecordMode = RecordMode.video
            self.changeRecordModeButton.image = UIImage(named: "photo_camera_white")
            print("Current record mode changed to: \(currentRecordMode)")
            return
        }
        if(self.currentRecordMode==RecordMode.video){
            self.currentRecordMode = RecordMode.photo
            self.changeRecordModeButton.image = UIImage(named: "video_camera_white")
            print("Current record mode changed to: \(currentRecordMode)")
            return
        }
    }
    
    @IBAction func recordButtonPressed(sender: UIButton) {
        if (self.currentRecordMode == RecordMode.photo){
            self.takePhoto()
            return
        }
        if (self.currentRecordMode == RecordMode.video){
            self.recordVideo()
            return
        }

    }
    
    func takePhoto() {
        if let stillOutput = self.stillImageOutput {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                // Find the video connection
                var videoConnection : AVCaptureConnection?
                for connecton in stillOutput.connections {
                    // Find a matching input port
                    for port in connecton.inputPorts!{
                        if port.mediaType == AVMediaTypeVideo {
                            videoConnection = connecton as? AVCaptureConnection
                            break // For port
                        }
                    }
                    
                    if videoConnection  != nil {
                        break // For connections
                    }
                }
                if videoConnection  != nil {
                    stillOutput.captureStillImageAsynchronouslyFromConnection(videoConnection){
                        (imageSampleBuffer : CMSampleBuffer!, _) in
                        
                        let imageDataJpeg = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer)
                        
                        let landscapeImage = UIImage(data: imageDataJpeg, scale: 1.0)!
                        let portraitImage = self.removeRotationForImage(landscapeImage)
                        print("Photo taked!")
                        ()
                        let currentDevice: UIDevice = UIDevice.currentDevice()
                        let orientation: UIDeviceOrientation = currentDevice.orientation
                        if (orientation.isLandscape) {
                            UIImageWriteToSavedPhotosAlbum(landscapeImage, nil, nil, nil)
                            return
                        }
                        if (orientation.isPortrait) {
                            UIImageWriteToSavedPhotosAlbum(portraitImage, nil, nil, nil)
                            return
                        }
                    }
                }
            }
        }
    }
    
    func removeRotationForImage(image: UIImage)-> UIImage{
        if (image.imageOrientation == UIImageOrientation.Up) {
            return image
        }
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.drawInRect(CGRectMake(0, 0, image.size.width, image.size.height))
        let normalizedImage:UIImage =  UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage;
    }
    
    func recordVideo() {
        // Recording video
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        let outputPath = "\(documentsPath)/Output.mov"
        let outputFileUrl = NSURL(fileURLWithPath: outputPath)
        
        if(self.isVideoRecording==false){
            self.isVideoRecording=true
            let videoDelegate = VideoDelegate()
            self.videoFileOutput = AVCaptureMovieFileOutput()
            self.captureSession.addOutput(self.videoFileOutput)

            self.videoFileOutput.startRecordingToOutputFileURL(outputFileUrl, recordingDelegate: videoDelegate)
            print("Video recording started!")
            print("Path: \(outputFileUrl)")
            // Start timer
            self.counterLabel.hidden = false
            self.counterLabel.textColor = UIColor.redColor()
            self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(CameraViewController.updateCounter), userInfo: nil, repeats: true)
            return
        }
        
        if(self.isVideoRecording==true){
            self.videoFileOutput.stopRecording()
            
            // Stop timer
            self.timer?.invalidate()
            UIView.animateWithDuration(2.0, animations: {
                self.counterLabel.alpha = 0.0
                self.counterLabel.textColor = UIColor.whiteColor()
                }, completion: { (bool) -> () in
                    self.counterLabel.hidden = true
                    self.counter = 0.0
                    self.counterLabel.text = self.getNormalizedString(self.counter)
            })
            
            for output in self.captureSession.outputs {
                self.captureSession.removeOutput(output as! AVCaptureOutput)
            }
            self.isVideoRecording=false
            print("Video recording stoped!")
            
            let completion:ALAssetsLibraryWriteVideoCompletionBlock = {url,error in
                
                let fileManager = NSFileManager.defaultManager()
                do {
                    try fileManager.removeItemAtPath(outputPath)
                    print("Temp video deleted!")
                }
                catch let error as NSError {
                    print("File deleting error: \(error)")
                }
            }
            
            ALAssetsLibrary().writeVideoAtPathToSavedPhotosAlbum(outputFileUrl, completionBlock: completion)
    
            return
        }
    }
    
    func updateCounter() {
        //self.counter = self.counter!+0.01
        self.counter = self.counter!+1
        self.counterLabel.text = self.getNormalizedString(self.counter)
        if(Int(self.counter % 2) == 0) {
            UIView.animateWithDuration(1.0, animations: {
                self.counterLabel.alpha = 1.0
            })
        } else {
            UIView.animateWithDuration(1.0, animations: {
                self.counterLabel.alpha = 0.5
            })
        }
    }
    
    func getNormalizedString(counter: Double) -> String {
        let interval = NSTimeInterval.init(counter)
        return interval.hoursMinutesSeconds

    }
}

// Image flipping
extension UIImage {
    public func imageRotatedByDegrees(degrees: CGFloat) -> UIImage {
        let radiansToDegrees: (CGFloat) -> CGFloat = {
            return $0 * (180.0 / CGFloat(M_PI))
        }
        let degreesToRadians: (CGFloat) -> CGFloat = {
            return $0 / (180.0 * CGFloat(M_PI))
        }
        
        // Calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(origin: CGPointZero, size: size))
        let t = CGAffineTransformMakeRotation(degreesToRadians(degrees));
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap = UIGraphicsGetCurrentContext()
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        CGContextTranslateCTM(bitmap, rotatedSize.width / 2.0, rotatedSize.height / 2.0);
        
        // Rotate the image context
        CGContextRotateCTM(bitmap, degreesToRadians(degrees));
        
        // Now, draw the rotated/scaled image into the context
        CGContextScaleCTM(bitmap, 1.0, -1.0)
        CGContextDrawImage(bitmap, CGRectMake(-size.width / 2, -size.height / 2, size.width, size.height), CGImage)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

// Working wiht time representation
extension NSTimeInterval {
    
    var minuteSecondMS: String {
        return String(format:"%02d:%02d:%02d", self.minute, self.second, self.millisecond)
    }
    
    var hoursMinutesSeconds: String {
        return String(format:"%02d:%02d:%02d", self.hour, self.minute, self.second)
    }
    
    var hour: Int {
        return Int (self/3600)
    }
    
    var minute: Int {
        return Int(self/60.0 % 60)
    }
    var second: Int {
        return Int(self % 60)
    }
    var millisecond: Int {
        //return Int(self*1000 % 1000)
        return Int(self*1000 % 100)
    }
}

// Working wiht time representation
extension Int {
    var msToSeconds: Double {
        return Double(self) / 1000
    }
}