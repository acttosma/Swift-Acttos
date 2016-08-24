//
//  ViewController.swift
//  DeviceAuth
//
//  Created by Actto on 23/8/2016.
//  Copyright © 2016 Personal. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation

class ViewController: UIViewController, UIAlertViewDelegate {

    typealias AuthorizeResultBlock = @convention(block) (succeed:Bool) -> Void;
    
    var settingsItemURL: NSURL?;
    
    @IBOutlet weak var cameraContainerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad();
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func audioRequestAction(sender: AnyObject) {
        self._requestForMediaAuthorization(AVMediaTypeAudio, callback: { (result:Bool) in
            NSLog("result is:\(result)");
            if (!result) {
                self._showAuthorizationFailureNotice(AVMediaTypeAudio);
            }
        });
    }
    
    @IBAction func videoRequestAction(sender: AnyObject) {
        self._requestForMediaAuthorization(AVMediaTypeVideo, callback: { (result:Bool) in
            NSLog("result is:\(result)");
            if (!result) {
                self._showAuthorizationFailureNotice(AVMediaTypeVideo);
            }
        });
    }
    
    @IBAction func startButtonAction(sender: AnyObject) {
        let captureSession:AVCaptureSession = AVCaptureSession();
        captureSession.sessionPreset = AVCaptureSessionPreset640x480;
        let deviceList:[AVCaptureDevice] = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as! [AVCaptureDevice];
        var targetDevice:AVCaptureDevice? = nil;
        for device:AVCaptureDevice in deviceList {
            if (device.position == AVCaptureDevicePosition.Front) {
                targetDevice = device;
                break;
            }
        }
        
        let deviceInput:AVCaptureDeviceInput?;
        do {
            deviceInput = try AVCaptureDeviceInput.init(device: targetDevice);
            captureSession.addInput(deviceInput);
            
            let previewLayer:AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession);
            previewLayer.backgroundColor = UIColor.whiteColor().CGColor;
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            previewLayer.frame = self.cameraContainerView.bounds;
            self.cameraContainerView.layer.addSublayer(previewLayer);
            
            captureSession.startRunning();
        } catch _ {
            NSLog("ERROR:We can't get an input device");
        }
    }
    
    func _requestForMediaAuthorization(type: String, callback:AuthorizeResultBlock) -> Void {
        AVCaptureDevice.requestAccessForMediaType(type) { (grant) in
            if (grant) {
                NSLog("Authorize sucessfully with type:\(type)");
                callback(succeed: true);
            } else {
                NSLog("Failed to get authorization with type:\(type)");
                callback(succeed: false);
            }
        }
    }
    
    func _showAuthorizationFailureNotice(type: String) -> Void {
        dispatch_async(dispatch_get_main_queue()) { 
            var tips: String?;
            let privacyItem: String = type == AVMediaTypeAudio ? "MICROPHONE" : type == AVMediaTypeVideo ? "CAMERA" : "";
            
            self.settingsItemURL = NSURL(string: "prefs:root=Privacy&path=\(privacyItem)");
            
            if (type == AVMediaTypeAudio) {
                tips = "Please allow us to use your Microphone to capture audio by opening 'Settings -> Privacy -> Microphone' to grant.";
            } else if (type == AVMediaTypeVideo) {
                tips = "Please allow us to use your Camera to capture video by opening 'Settings -> Privacy -> Camera' to grant.";
            } else {
                tips = "Please allow us to use your device by opening 'Settings -> Privacy' to grant certain authorization.";
            }
            
            let compareResult:NSComparisonResult = UIDevice.currentDevice().systemVersion.compare("8.0");
            
            if (compareResult == NSComparisonResult.OrderedSame || compareResult == NSComparisonResult.OrderedDescending) {
                let alertController: UIAlertController = UIAlertController(title: "Authorization Request", message: tips, preferredStyle: UIAlertControllerStyle.Alert);
                let confirmAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) in
                    if(UIApplication.sharedApplication().canOpenURL(self.settingsItemURL!)) {
                        UIApplication.sharedApplication().openURL(self.settingsItemURL!);
                    }
                });
                
                let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil);
                
                alertController.addAction(confirmAction);
                alertController.addAction(cancelAction);
                self.presentViewController(alertController, animated: true, completion: {
                    
                });
            } else {
                let alertView: UIAlertView = UIAlertView(title: "Authorization Request", message: tips!, delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "OK");
                alertView.show();
            }
        };
    }
    
    //MARK: - UIAlertView Delegate Methods
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if (buttonIndex == 1) {
            if(UIApplication.sharedApplication().canOpenURL(settingsItemURL!)) {
                UIApplication.sharedApplication().openURL(settingsItemURL!);
            }
        }
    }
}

