//
//  TrainViewController.swift
//  FaceEntry
//
//  Created by Keith Moon on 29/03/2017.
//  Copyright © 2017 Keith Moon. All rights reserved.
//

import UIKit

class TrainViewController: VideoCaptureViewController {

    enum State {
        case notTrained
        case trainingInProgress
        case trainingFailed
        case trained
    }
    
    private var trainingEnabled = false
    private var currentState: State = .notTrained
    
    @IBOutlet var trainButton: UIButton! {
        didSet {
            update(for: currentState)
        }
    }
    
    override var previewImageView: UIImageView! {
        didSet {
            previewImageView.layer.borderWidth = 2
        }
    }
    
    @IBAction func triggerButtonDown(sender: UIButton) {
        trainingEnabled = false
        previewImageView.layer.borderColor = UIColor.green.cgColor
    }
    
    @IBAction func triggerButtonUp(sender: UIButton) {
        trainingEnabled = true
        previewImageView.layer.borderColor = UIColor.clear.cgColor
    }
    
    @IBAction func trainButtonPressed(sender: UIButton) {
        
        update(for: .trainingInProgress)
        
        faceManager.train(group) { [weak self] result in
            
            switch result {
                
            case .success():
                self?.update(for: .trained)
                
            case .failure(let error):
                print("Failed to train: \(error)")
                self?.update(for: .trainingFailed)
            }
        }
    }
    
    override func handle(processedImage image: UIImage) {
        
        guard trainingEnabled == true, let imageData = UIImageJPEGRepresentation(image, 0.8) else { return }
        
        trainingEnabled = false
        
        faceManager.addTrainingImageData(imageData, for: person, in: group) { result in
            
            switch result {
                
            case .success(let face):
                print("Added training face: \(face.faceID)")
                
            case .failure(let error):
                print("Failed adding training image: \(error)")
            }
        }
    }
    
    func update(for state: State) {
        
        currentState = state
        
        switch state {
        case .notTrained:
            trainButton.setTitle("Train", for: .normal)
            trainButton.backgroundColor = .blue
            trainButton.isEnabled = true
            
        case .trainingInProgress:
            trainButton.setTitle("Training", for: .normal)
            trainButton.backgroundColor = .orange
            trainButton.isEnabled = false
            
        case .trainingFailed:
            trainButton.setTitle("Failed", for: .normal)
            trainButton.backgroundColor = .red
            trainButton.isEnabled = true
            
        case .trained:
            trainButton.setTitle("Trained", for: .normal)
            trainButton.backgroundColor = .green
            trainButton.isEnabled = false
        }
    }
}

