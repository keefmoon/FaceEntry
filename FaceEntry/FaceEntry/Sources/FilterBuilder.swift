//
//  FilterBuilder.swift
//  FaceCapture
//
//  Created by Keith Moon on 12/02/2017.
//  Copyright © 2017 Keith Moon. All rights reserved.
//

import CoreImage

precedencegroup ProgressivePrecedence {
    associativity: left
    higherThan: AdditionPrecedence
    lowerThan: MultiplicationPrecedence
}

infix operator ->> : ProgressivePrecedence

extension CIFilter {
    
    static func ->> (lhs: CIImage, rhs: CIFilter) -> CIFilter? {
        rhs.setInput(lhs)
        return rhs
    }
    
    static func ->> (lhs: CIFilter, rhs: CIFilter) -> CIFilter? {
        guard let inputImage = lhs.outputImage else { return nil }
        rhs.setInput(inputImage)
        return rhs
    }
    
    static func ->> (lhs: CIFilter, rhs: CIFilter?) -> CIFilter? {
        
        guard let rhs = rhs else { return lhs }
        guard let inputImage = lhs.outputImage else { return nil }
        rhs.setInput(inputImage)
        return rhs
    }
    
    static func ->> (lhs: CIFilter?, rhs: CIFilter) -> CIFilter? {
        
        guard let lhs = lhs else { return rhs }
        guard let inputImage = lhs.outputImage else { return nil }
        rhs.setInput(inputImage)
        return rhs
    }
    
    func setInput(_ image: CIImage) {
        setValue(image, forKey: kCIInputImageKey)
    }
}

class FilterBuilder {
    
    func cropFilter(cropTo rect: CGRect) -> CIFilter {
        let vector = CIVector(cgRect: rect)
        let parameters: [String: Any] = ["inputRectangle": vector]
        return CIFilter(name: "CICrop", withInputParameters: parameters)!
    }
    
    func rotateFilter(by angle: Angle, around point: CGPoint) -> CIFilter {
        
        // Move so center point is at 0,0
        var transform = CGAffineTransform(translationX: point.x, y: point.y)
        // Perform rotation
        transform = transform.rotated(by: CGFloat(angle.toRadians))
        // Move 0,0 back to center point
        transform = transform.translatedBy(x: -point.x, y: -point.y)

        let value = NSValue(cgAffineTransform: transform)
        
        let parameters: [String: Any] = ["inputTransform": value]
        return CIFilter(name: "CIAffineTransform", withInputParameters: parameters)!
    }
    
    func convolution3x3Filter() -> CIFilter {
        
        let floatArray: [CGFloat] = [1,0,-1,2,0,-2,1,0,-1]
        let vector = CIVector(values: floatArray, count: floatArray.count)
        let parameters: [String: Any] = [kCIInputWeightsKey: vector, kCIInputBiasKey: NSNumber(value: 0.5)]
        
        return CIFilter(name: "CIConvolution3X3", withInputParameters: parameters)!
    }
    
    func overCompositingFilter() -> CIFilter {
        
        let backgroundColourImage = CIImage(color: CIColor.black())
        let parameters: [String: Any] = [kCIInputBackgroundImageKey: backgroundColourImage]
        return CIFilter(name: "CISourceOverCompositing", withInputParameters: parameters)!
    }
    
    func colourPolynomialFilter() -> CIFilter {
        
        let red = CIVector(x: 1, y: -4, z: 4, w: 0)
        let green = CIVector(x: 1, y: -4, z: 4, w: 0)
        let blue = CIVector(x: 1, y: -4, z: 4, w: 0)
        let parameters: [String: Any] = ["inputRedCoefficients": red, "inputGreenCoefficients": green, "inputBlueCoefficients": blue]
        return CIFilter(name: "CIColorPolynomial", withInputParameters: parameters)!
    }
    
}
