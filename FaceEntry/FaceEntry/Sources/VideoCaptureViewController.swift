//
//  VideoCaptureViewController.swift
//  FaceEntry
//
//  Created by Keith Moon on 30/03/2017.
//  Copyright © 2017 Keith Moon. All rights reserved.
//

import UIKit
import AVFoundation

protocol VideoCaptureViewControllerDelegate: class {
    
    func attemptToDismiss(_ capture: VideoCaptureViewController, withCode code: String) -> Bool
}

class VideoCaptureViewController: UIViewController {
    
    @IBOutlet var rawVideoFeedView: UIView!
    
    weak var delegate: VideoCaptureViewControllerDelegate?
    var frameExtractor: FrameExtractor!
    fileprivate var rawVideoFeedLayer: AVCaptureVideoPreviewLayer!
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rawVideoFeedLayer = AVCaptureVideoPreviewLayer(session: frameExtractor.captureSession)!
        rawVideoFeedLayer.backgroundColor = UIColor.black.cgColor
        rawVideoFeedLayer.videoGravity = AVLayerVideoGravityResizeAspect
        
        rawVideoFeedView.layer.masksToBounds = true
        rawVideoFeedView.layer.addSublayer(rawVideoFeedLayer)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        rawVideoFeedLayer.frame = rawVideoFeedView.layer.bounds
    }
    
    // MARK: Actions
    
    func presentAlertForAccessCode() {
        
        let alert = UIAlertController(title: "Access Code",
                                      message: "Please enter the access code to enter admin section",
                                      preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let ok = UIAlertAction(title: "Verify", style: .default) { [weak self] action in
            
            guard let strongSelf = self, let delegate = strongSelf.delegate, let textField = alert.textFields?.first else { return }
            
            if !delegate.attemptToDismiss(strongSelf, withCode: textField.text ?? "") {
                
                // Tell the user they were unsuccessful
                let failedAlert = UIAlertController(title: "Access Denied",
                                                    message: "You have entered the wrong access code",
                                                    preferredStyle: .alert)
                failedAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                strongSelf.present(failedAlert, animated: true, completion: nil)
            }
        }
        
        alert.addAction(cancel)
        alert.addAction(ok)
        alert.addTextField { textField in
            textField.keyboardType = .numberPad
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func adminButtonPressed(sender: UIButton) {
        presentAlertForAccessCode()
    }
}
