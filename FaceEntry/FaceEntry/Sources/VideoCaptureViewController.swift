//
//  VideoCaptureViewController.swift
//  FaceEntry
//
//  Created by Keith Moon on 30/03/2017.
//  Copyright © 2017 Keith Moon. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia
import CoreImage

protocol VideoCaptureViewControllerDelegate: class {
    
    func attemptToDismiss(_ capture: VideoCaptureViewController, withCode code: String) -> Bool
}

class VideoCaptureViewController: UIViewController {
    
    // MARK: Outlets
    
    @IBOutlet var rawVideoFeedView: UIView!
    @IBOutlet var previewImageView: UIImageView!
    @IBOutlet var sobelSwitch: UISwitch!
    
    // MARK: Public Dependancies
    
    weak var delegate: VideoCaptureViewControllerDelegate?
    var faceManager: FaceManager!
    var frameExtractor: FrameExtractor! {
        didSet {
            frameExtractor.delegate = self
        }
    }
    var faceDetector: CIDetector!
    var context: CIContext!
    var group: PersonGroup!
    var person: Person!
    
    // MARK: Private Properties
    
    fileprivate var rawVideoFeedLayer: AVCaptureVideoPreviewLayer!
    fileprivate let filterBuilder = FilterBuilder()
    fileprivate var enableProcessing = true
    
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
        
        enableProcessing = false
        
        let alert = UIAlertController(title: "Access Code",
                                      message: "Please enter the access code to enter admin section",
                                      preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] action in
            self?.enableProcessing = true
        }
        let ok = UIAlertAction(title: "Verify", style: .default) { [weak self] action in
            
            guard let strongSelf = self, let delegate = strongSelf.delegate, let textField = alert.textFields?.first else { return }
            
            if !delegate.attemptToDismiss(strongSelf, withCode: textField.text ?? "") {
                
                // Tell the user they were unsuccessful
                let failedAlert = UIAlertController(title: "Access Denied",
                                                    message: "You have entered the wrong access code",
                                                    preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default) { [weak self] action in
                    self?.enableProcessing = true
                }
                failedAlert.addAction(ok)
                strongSelf.present(failedAlert, animated: true, completion: nil)
            }
        }
        
        alert.addAction(cancel)
        alert.addAction(ok)
        alert.addTextField { textField in
            textField.keyboardType = .numberPad
            textField.isSecureTextEntry = true
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func adminButtonPressed(sender: UIButton) {
        presentAlertForAccessCode()
    }
}

extension VideoCaptureViewController: FrameExtractorDelegate {
    
    func captured(sampleBuffer: CMSampleBuffer) {
        
        guard enableProcessing == true else { return }
        
        guard let image = sampleBuffer.image else { return }
        guard let features = faceDetector?.features(in: image) else { return }
        let faces = features.flatMap { $0 as? CIFaceFeature }
        guard let firstFace = faces.first, let processedImage = process(image, for: firstFace) else { return }
        let frame = cropFrame(forFaceFrame: firstFace.bounds)
        guard let processedUIImage = convert(image: processedImage, for: frame, at: CGSize(width: 160, height: 160)) else { return }
        
        showFacePreview(for: processedUIImage)
        handle(processedImage: processedUIImage)
    }
    
    func cropFrame(forFaceFrame faceFrame: CGRect) -> CGRect {
        
        let percentageMargin = faceFrame.width * 0.2
        let cropFrame = faceFrame.insetBy(dx: -percentageMargin, dy: -percentageMargin)
        return cropFrame
    }
    
    func process(_ image: CIImage, for face: CIFaceFeature) -> CIImage? {
        
        // Rotate image to straighten face
        let angle = Angle.degrees(face.faceAngle)
        let center = CGPoint(x: face.bounds.midX, y: face.bounds.midY)
        let rotate = filterBuilder.rotateFilter(by: angle, around: center)
        
        // Crop to just face + margin
        //        let frame = cropFrame(forFaceFrame: face.bounds)
        //        let crop = builder.cropFilter(cropTo: frame)
        
        // Sobel
        let convolution = filterBuilder.convolution3x3Filter()
        let overCompositing = filterBuilder.overCompositingFilter()
        let colourPolynomial = filterBuilder.colourPolynomialFilter()
        
        // Apply the filters and return image
        var lastFilter = image ->> rotate //->> crop
        
        if sobelSwitch.isOn {
            lastFilter = lastFilter ->> convolution ->> overCompositing ->> colourPolynomial
        }
        
        return lastFilter?.outputImage
    }
    
    func convert(image: CIImage, for rect: CGRect, at size: CGSize? = nil) -> UIImage? {
        guard var cgImage = context.createCGImage(image, from: rect) else { return nil }
        
        if let size = size {
            guard let resizedImage = resize(image: cgImage, to: size) else { return nil }
            cgImage = resizedImage
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    func resize(image: CGImage, to size: CGSize) -> CGImage? {
        
        let width = Int(size.width)
        let height = Int(size.height)
        let bitsPerComponent = image.bitsPerComponent
        let bytesPerRow = image.bytesPerRow
        guard let colorSpace = image.colorSpace else { return nil }
        let bitmapInfo = image.bitmapInfo
        
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else { return nil }
        
        context.interpolationQuality = CGInterpolationQuality.high
        context.draw(image, in: CGRect(origin: .zero, size: size))
        
        return context.makeImage()
    }
    
    func showFacePreview(for image: UIImage) {
        previewImageView.image = image
    }
    
    func handle(processedImage image: UIImage) {
        // Override in subclass
        fatalError("Override in subclass")
    }
}
