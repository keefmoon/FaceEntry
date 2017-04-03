//
//  IdentifyViewController.swift
//  FaceEntry
//
//  Created by Keith Moon on 30/03/2017.
//  Copyright © 2017 Keith Moon. All rights reserved.
//

import UIKit

class IdentifyViewController: VideoCaptureViewController {
    
    enum State {
        case locked
        case unlocked
    }
    
    @IBOutlet var padlockButton: UIButton!
    @IBOutlet var spinnerView: UIView! {
        didSet {
            spinnerView.isHidden = true
        }
    }
    override var previewImageView: UIImageView! {
        didSet {
            previewImageView.layer.borderWidth = 2
        }
    }
    
    var currentState: State = .locked
    var acceptableConfidenceLevel: Float = 0.6
    var tryToUnlockEnabled = false
    
    override func handle(processedImage image: UIImage) {
        
        // If unlocked, stop checking
        guard case State.locked = currentState else { return }
        
        guard tryToUnlockEnabled == true, let imageData = UIImageJPEGRepresentation(image, 0.8) else { return }
        
        tryToUnlockEnabled = false
        
        spinnerView.isHidden = false
        faceManager.identify(imageData: imageData, in: group) { [weak self] result in
            
            defer {
                self?.spinnerView.isHidden = true
            }
            
            switch result {
                
            case .failure(let error):
                print("Identify Error: \(error)")
                
            case .success(let candidates):
                
                guard
                    let person = self?.person,
                    let candidate = candidates.filter({ $0.person.personID == person.personID }).first else {
                    
                        print("Identify Error: Candidate not found")
                        return
                }
                
                guard
                    let acceptableConfidenceLevel = self?.acceptableConfidenceLevel,
                    candidate.confidence > acceptableConfidenceLevel else {
                    
                        print("Identify Error: Under accpetable confidence level")
                        return
                }
                
                self?.update(for: .unlocked)
            }
        }
    }
    
    @IBAction func padlockButtonPressed(sender: UIButton) {
        
        if sender.isSelected {
            update(for: .locked)
        }
    }
    
    @IBAction func tryToUnlockButtonDown(sender: UIButton) {
        tryToUnlockEnabled = false
        previewImageView.layer.borderColor = UIColor.green.cgColor
    }
    
    @IBAction func tryToUnlockButtonUp(sender: UIButton) {
        tryToUnlockEnabled = true
        previewImageView.layer.borderColor = UIColor.clear.cgColor
    }
    
    func update(for state: State) {
        
        currentState = state
        
        switch state {
        case .locked: padlockButton.isSelected = false
        case .unlocked: padlockButton.isSelected = true
        }
    }
}
