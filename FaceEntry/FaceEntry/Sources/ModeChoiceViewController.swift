//
//  ModeChoiceViewController.swift
//  FaceEntry
//
//  Created by Keith Moon on 30/03/2017.
//  Copyright © 2017 Keith Moon. All rights reserved.
//

import UIKit
import CoreImage

let accessCode = "123456"

class ModeChoiceViewController: UIViewController {
    
    enum State {
        case initial
        case preparing
        case ready(PersonGroup, Person)
        case failed
    }
    
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var trainingButton: UIButton!
    @IBOutlet var identifyButton: UIButton!
    
    let frameExtractor = FrameExtractor()
    let faceManager = FaceManager()
    
    let faceDetector = CIDetector(ofType: CIDetectorTypeFace,
                                  context: CIContext(),
                                  options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
    var context: CIContext!
    var currentState: State = .initial
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let openGLContext = EAGLContext(api: .openGLES2)!
        context = CIContext(eaglContext: openGLContext, options: [kCIContextWorkingColorSpace: NSNull()])
        prepareData()
    }
    
    func prepareData() {
        
        update(for: .preparing)
        
        faceManager.getAuthorisedFaceGroup { [weak self] result in
            
            switch result {
                
            case .success(let group):
                
                self?.faceManager.getDefaultPerson(in: group) { result in
                    
                    switch result {
                    case .success(let person):
                        self?.update(for: .ready(group, person))
                        
                    case .failure(let error):
                        print("Failed to prepare: \(error)")
                        self?.update(for: .failed)
                    }
                }
                
            case .failure(let error):
                print("Failed to prepare: \(error)")
                self?.update(for: .failed)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let videoCaptureVC = segue.destination as? VideoCaptureViewController {
            videoCaptureVC.frameExtractor = frameExtractor
            videoCaptureVC.faceManager = faceManager
            videoCaptureVC.delegate = self
            videoCaptureVC.faceDetector = faceDetector
            videoCaptureVC.context = context
            
            switch currentState {
            case .ready(let group, let person):
                videoCaptureVC.group = group
                videoCaptureVC.person = person
                
            default: break
            }
        }
    }
    
    func update(for state: State) {
        
        currentState = state
        
        switch state {
        case .initial:
            statusLabel.text = "Not ready"
            statusLabel.textColor = .gray
            trainingButton.isEnabled = false
            identifyButton.isEnabled = false
            
        case .preparing:
            statusLabel.text = "Preparing..."
            statusLabel.textColor = .orange
            trainingButton.isEnabled = false
            identifyButton.isEnabled = false
            
        case .ready:
            statusLabel.text = "Ready"
            statusLabel.textColor = .green
            trainingButton.isEnabled = true
            identifyButton.isEnabled = true
            
        case .failed:
            statusLabel.text = "Failed to prepare"
            statusLabel.textColor = .red
            trainingButton.isEnabled = false
            identifyButton.isEnabled = false
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
