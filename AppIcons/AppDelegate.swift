//
//  AppDelegate.swift
//  Images
//
//  Created by Iain Burry on 11/25/18.
//  Copyright © 2018 Ian Burry. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {
    @IBOutlet weak var showInfoViewMenuItem: NSMenuItem!
    var iconsVC : IconsViewController!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        iconsVC = NSApplication.shared.windows.first?.contentViewController as? IconsViewController
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        var result = true
        if menuItem.action == #selector(toggleInfoView) && iconsVC.loadedImageView.image == nil {
            result = false
        }
        
        return result
    }
    
    @IBAction func openImageFile(_ sender: Any) {
        iconsVC.loadImageFile()
    }
    
    @IBAction func toggleInfoView(_ sender: Any) {
        if iconsVC.loadedImageView.image != nil {
            iconsVC.infoView.isHidden = !iconsVC.infoView.isHidden
            showInfoViewMenuItem.title = iconsVC.infoView.isHidden ? "Show Info View" : "Hide Info View"
        }
    }
}

