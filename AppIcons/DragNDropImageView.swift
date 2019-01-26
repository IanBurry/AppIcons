//
//  DragNDropImageView.swift
//  Images
//
//  Created by Iain Burry on 12/26/18.
//  Copyright © 2018 Ian Burry. All rights reserved.
//

import Cocoa

class DragNDropImageView: NSImageView {
    let fileFilterOptions = [NSPasteboard.ReadingOptionKey.urlReadingContentsConformToTypes : ["public.png", "public.jpeg"]]
    var dragValidationColor : NSColor!
    var imageFileName = ""
    var isDragging = false {
        didSet {
            needsDisplay = true
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if dragValidationColor != nil {
            dragValidationColor.set()
            let path = NSBezierPath(rect: bounds)
            path.lineWidth = 10.0
            path.stroke()
        }
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let pasteBoard = sender.draggingPasteboard

        if pasteBoard.canReadObject(forClasses: [NSURL.self], options: fileFilterOptions) {
            isDragging = true
            dragValidationColor = NSColor.selectedControlColor
        } else {
            isDragging = false
            dragValidationColor = NSColor.systemRed
        }
        
        return .generic
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return isDragging
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteBoard = sender.draggingPasteboard
        let urls = pasteBoard.readObjects(forClasses: [NSURL.self], options: fileFilterOptions) as? [URL]
    
        if let url = urls?.first {
            imageFileName = url.lastPathComponent
            return true
        }
        
        return false
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        dragValidationColor = NSColor.clear
        isDragging = false
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        dragValidationColor = NSColor.clear
        isDragging = false
    }

}
