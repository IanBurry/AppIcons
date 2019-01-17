//
//  Scaler.swift
//  Images
//
//  Created by Iain Burry on 11/26/18.
//  Copyright © 2018 Ian Burry. All rights reserved.
//

import Cocoa
import os.log

class Scaler {

    /**
     Create as CGSize object from dimensions string

     - Parameter sizeString: dimensions string like '32x32'
     - Returns: CGSize object with width and height
     */
    class func cgSizeFromWxHString(_ sizeString: String) -> CGSize? {
        let dimensions = sizeString.split(separator: Character("x")).map { Int($0) }
        guard let w = dimensions.first!, let h = dimensions.last! else {
            return nil
        }
        
        return CGSize(width: w, height: h)
    }
    
    /**
     dimensionsFromWxHString

     Given a valid dimension string and scale factor, returns a tuple containing
     integer width and height
     
     - Parameter sizeString: dimensions as a String. Like '32x32'
     - Parameter scale: Integer scaling factor. Defaults to 1
     - Returns: Tuple of integer width and height
    */
    class func dimensionsFromWxHString(_ sizeString: String, scale: Double = 1.0) -> (width: Double , height: Double)? {
        let dimensions = sizeString.split(separator: Character("x")).map { Double($0) }
        guard let w = dimensions.first!, let h = dimensions.last! else {
            os_log("Cannot extract dimensions from string: %@", sizeString)
            return nil
        }
        
        return (width: w * scale, height: h * scale)
    }
    
    /**
      imageCIScale
 
      Uses Core Image to perform scaling. Does not scale directly to height
      or width, but determines a scaling factor from a provided numeric dimension.
      Easily embiggens as well as ensmallens.
     */
    class func imageCIScale(_ image: NSImage, dimension: Double) -> NSImage? {
        guard let data = image.tiffRepresentation,
            let filter = CIFilter(name: "CILanczosScaleTransform"),
            let ciImage = CIImage(data: data)
        else {
            os_log("Could not set up Core Image with provided data at: %@ line: %@", #function, #line)
            return nil
        }
        
        let scaleFactor = CGFloat(dimension) / image.size.height
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(scaleFactor, forKey: kCIInputScaleKey)
        filter.setValue(1.0, forKey: kCIInputAspectRatioKey)
        
        let context = CIContext()
        guard let outputImage = filter.outputImage,
              let scaledImage = context.createCGImage(outputImage, from: outputImage.extent)
        else {
            os_log("Could not create scaled CG Image at: %@ line: %@", #function, #line)
            return nil
        }
        
        return NSImage(cgImage: scaledImage, size: NSZeroSize)
    }
    
    
    /**
      imageCGScale

      Scales image using Core Graphics. Scales to provided height and width.
      Does not handle enlarging images
     */
    class func imageCGScale(_ image: NSImage, width: Int, height: Int) -> NSImage? {
        var imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        
        if let imageCG = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil) {
            if let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: imageCG.bitsPerComponent, bytesPerRow: imageCG.bytesPerRow, space: imageCG.colorSpace!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) {
                
                context.interpolationQuality = .high
                context.draw(imageCG, in: CGRect(origin: .zero, size: CGSize(width: context.width, height: context.height)))
                
                let cgScaledImage = context.makeImage()
                
                let nsScaledImage = cgScaledImage.flatMap {
                    NSImage(cgImage: $0, size: NSSize(width: context.width, height: context.height))
                }
                
                return nsScaledImage
            }
        }
        
        return nil
    }
    
    /**
      imageIOScale

      Performs scaling using Image I/O. This is pretty simple to implement.
      Needs to be made fully functional
     */
    class func imageIOScale(_ image: NSImage, dimension: Int) -> NSImage? {
        let data = image.tiffRepresentation // don't want to do this more than once. TIFF large
        let imageSrc = CGImageSourceCreateWithData(data! as CFData, nil)
        
        let options = [
            kCGImageSourceThumbnailMaxPixelSize: dimension,
            kCGImageSourceCreateThumbnailFromImageAlways: true
            ] as CFDictionary
        
        let scaledImage = CGImageSourceCreateThumbnailAtIndex(imageSrc!, 0, options).flatMap {
            NSImage(cgImage: $0, size: NSSize(width: dimension, height: dimension))
        }
        
        return scaledImage
    }
}
