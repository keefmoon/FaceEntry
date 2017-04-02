//
//  CMSampleBuffer+CIImage.swift
//  FaceCapture
//
//  Created by Keith Moon on 13/02/2017.
//  Copyright © 2017 Keith Moon. All rights reserved.
//

import CoreMedia
import CoreImage

extension CMSampleBuffer {
    
    var image: CIImage? {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(self) else { return nil }
        
        guard let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, self, kCMAttachmentMode_ShouldPropagate) as? [String: Any] else { return nil }
        
        var options = attachments
        options[kCIImageColorSpace] = NSNull()
        
        return CIImage(cvImageBuffer: pixelBuffer, options: options)
    }
}
