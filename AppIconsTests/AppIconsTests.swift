//
//  ImagesTests.swift
//  ImagesTests
//
//  Created by Iain Burry on 12/3/18.
//  Copyright © 2018 Ian Burry. All rights reserved.
//

import XCTest
@testable import AppIcons

class AppIconsTests: XCTestCase {
    var bundle : Bundle!
    var image : NSImage!
    
    override func setUp() {
        if bundle == nil || image == nil {
            bundle = Bundle(for: type(of: self))
            image = bundle.image(forResource: "TestImage")!
        }
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /**
     test_cgSizeFromWxHStringReturnsCGSize
     
     Test that a correctly configured CGSize object is returned when a
     valid dimension string is provided
    */
    func test_cgSizeFromWxHStringReturnsCGSize() {
        let testStr = "16x16"
        let expected = CGSize(width: 16, height: 16)
        let result = Scaler.cgSizeFromWxHString(testStr)
        
        XCTAssertEqual(expected, result)
    }

    /**
     test_cgSizeFromWxHStringReturnsNil
     
     Test that nil is returned for an invalid dimension string
    */
    func test_cgSizeFromWxHStringReturnsNil() {
        let testStr = "16y16"
        let result = Scaler.cgSizeFromWxHString(testStr)
        
        XCTAssert(result == nil, "Result must be nil for invalid string size: \(testStr)")
    }
    
    /**
     test_dimensionsFromWxHStringReturnsDimensions
     
     Test that a tuple with the correct height and width dimension values is
     returned for a valid dimension string
    */
    func test_dimensionsFromWxHStringReturnsDimensions() {
        let testStr = "32x32"
        let expected = (width: 32, height: 32)
        let result = Scaler.dimensionsFromWxHString(testStr)
        
        XCTAssert(expected == result!)
    }
    
    func test_dimensionsFromWxHStringReturnsScaledDimensions() {
        let testStr = "32x32"
        let scaleFactor = 2
        let expected = (width: 64, height: 64)
        let result = Scaler.dimensionsFromWxHString(testStr, scale: scaleFactor)
        
        XCTAssert(expected == result!)
    }
    
    /**
     test_dimensionsFromWxHStringReturnsNil
     
     Test that nil is returned for an invalid dimension string
    */
    func test_dimensionsFromWxHStringReturnsNil() {
        let testStr = "32y32"
        let result = Scaler.dimensionsFromWxHString(testStr)
        
        XCTAssertNil(result)
    }
    
    /**
     test_imageCGScaleReturnsScaledImage
     
     Test that a correctly scaled image is returned using Core Graphics
    */
    func test_imageCGScaleReturnsScaledImage() {
        let w = 256, h = 256
        let result = Scaler.imageCGScale(image, width: w, height: h)
        let resultSize = result?.size
        
        XCTAssert(resultSize == NSSize(width: w, height: h))
    }
    
    /**
     test_imageCIScaleReturnsScaledImage
     
     Test that a correctly scaled image is returned using Core Image
     */
    func test_imageCIScaleReturnsScaledImage() {
        let w = 1200, h = 1200
        let result = Scaler.imageCIScale(image, dimension: h)
        let resultSize = result?.size
        
        XCTAssert(resultSize == NSSize(width: w, height: h))
    }
    
    /**
     test_imageIOScaleReturnsScaledImage
     
     Test that a correctly scaled image is returned using Image I/O
     */
    func test_imageIOScaleReturnsScaledImage() {
        let w = 250, h = 250
        let result = Scaler.imageIOScale(image, dimension: w)
        let resultSize = result?.size
        
        XCTAssert(resultSize == NSSize(width: w, height: h))
    }
    
    func test_imageIOScaleReturnsEnlargedImage() {
        let w = 1200, h = 1200
        let result = Scaler.imageIOScale(image, dimension: w)
        let resultSize = result?.size
        
        XCTAssert(resultSize == NSSize(width: w, height: h))
    }

}
