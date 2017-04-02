
//
//  Angle.swift
//  FaceCapture
//
//  Created by Keith Moon on 11/02/2017.
//  Copyright © 2017 Keith Moon. All rights reserved.
//

enum Angle {
    
    case degrees(Float)
    case radians(Float)
    
    var toDegrees: Float {
        switch self {
        case .degrees(let degrees): return degrees
        case .radians(let radians): return radians * 180 / .pi
        }
    }
    
    var toRadians: Float {
        switch self {
        case .degrees(let degrees): return degrees * .pi / 180
        case .radians(let radians): return radians
        }
    }
}
