//
//  ModeChoiceViewController.swift
//  FaceEntry
//
//  Created by Keith Moon on 30/03/2017.
//  Copyright © 2017 Keith Moon. All rights reserved.
//

import UIKit

let accessCode = "123456"

class ModeChoiceViewController: UIViewController {
    
    let frameExtractor = FrameExtractor()
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let videoCaptureVC = segue.destination as? VideoCaptureViewController {
            videoCaptureVC.frameExtractor = frameExtractor
            videoCaptureVC.delegate = self
        }
    }
}

extension ModeChoiceViewController: VideoCaptureViewControllerDelegate {
    
    func attemptToDismiss(_ capture: VideoCaptureViewController, withCode code: String) -> Bool {
        
        if code == accessCode {
            dismiss(animated: true, completion: nil)
            return true
        } else {
            return false
        }
    }
}
