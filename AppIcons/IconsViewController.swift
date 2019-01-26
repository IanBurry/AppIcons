//
//  ViewController.swift
//  Images
//
//  Created by Iain Burry on 11/25/18.
//  Copyright © 2018 Ian Burry. All rights reserved.
//

import Cocoa
import os.log
import SwiftyJSON

class IconsViewController: NSViewController {
    @IBOutlet weak var loadedImageView: NSImageView!
    @IBOutlet weak var scaleButton: NSButtonCell!
    @IBOutlet weak var infoView: NSView!
    @IBOutlet weak var filenameLabel: NSTextField!
    @IBOutlet weak var fileFormatLabel: NSTextField!
    @IBOutlet weak var imageSizeLabel: NSTextField!

    var appInfo = ["name": "", "version": ""]
    var openFileLastPath: URL?
    var saveFilesLastPath: URL?
    var sourceImageFilename = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        appInfo["name"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        appInfo["version"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String

        infoView.wantsLayer = true
        infoView.layer?.backgroundColor = CGColor(gray: 0.2, alpha: 0.65)
    }

    /**
     Load image from file and display

     Acquire file path from fileDialog and load image file. Show image file info view.
     Enable 'create and install icons'
     */
    func loadImageFile() {
        view.window?.title = "Select Source Image File (JPEG or PNG)"
        let fileDialog = NSOpenPanel()
        fileDialog.allowedFileTypes = ["png", "jpg"]
        fileDialog.directoryURL = openFileLastPath
        fileDialog.beginSheetModal(for: view.window!, completionHandler: { (response: NSApplication.ModalResponse) in
             if response == .OK {
                if let url = fileDialog.url, let image = NSImage(contentsOf: url) {
                    self.sourceImageFilename = url.lastPathComponent
                    self.checkImage(image)
                } else {
                    self.showWarning(
                        message: "Unrecognized image file format",
                        info: "Image file not found, or is an unacceptable format. Allow formats are: PNG or JPEG"
                    )
                }
            }
            
            self.view.window?.title = self.appInfo["name"]!
        })

        openFileLastPath = fileDialog.directoryURL // is this needed anymore?
    }

    /**
     Check loaded image is square (height == width)

     Given a loaded image, checks dimensions for equality, and prompts to crop if unequal.
     Sets the source image view's image property regardless, but will not enable the
     'Install' button if image remains unsquare

     - Parameter image: NSImage from image source file
     */
    func checkImage(_ image: NSImage?) {
        guard let theImage = image else {
            os_log("checkImage: No valid NSImage param")
            return
        }

        loadedImageView.image = theImage
        let imageSize = theImage.size
        if imageSize.width != imageSize.height {
            let cropAlert = NSAlert()
            cropAlert.messageText = "Crop Source Image?"
            cropAlert.informativeText = "Source image is not square. \(appInfo["name"]!) can crop it for you"
            cropAlert.addButton(withTitle: "Crop Image")
            cropAlert.addButton(withTitle: "Cancel")
            cropAlert.beginSheetModal(for: view.window!) { (response: NSApplication.ModalResponse) in
                if response == .alertFirstButtonReturn {
                    self.loadedImageView.image = Scaler.imageCICrop(theImage)
                    self.scaleButton.isEnabled = true
                } else {
                    self.scaleButton.isEnabled = false
                }

                self.setupInfoView()
            }
        } else {
            self.setupInfoView()
            self.scaleButton.isEnabled = true
        }
    }

    /**
     Set up and display image information view
     */
    func setupInfoView() {
        if let theSize = loadedImageView.image?.size {
            filenameLabel.stringValue = sourceImageFilename
            fileFormatLabel.stringValue = sourceImageFilename.components(separatedBy: ".").last?.uppercased() ?? "N/A"
            imageSizeLabel.stringValue = String(format: "%.0f x %.0f", theSize.width, theSize.height)
        }

        if let delegate = getAppDelegate() {
            if infoView.isHidden {
                delegate.toggleInfoView(self)
            }
        }
    }

    /**
     Create and install icon images in target project

     Using the project or workspace path, create all icon image files from the information
     provided in the Contents.json file. Update Contents.json with icon image file names
     NOTE: This is doing too much. There should be two dialogs anyway. One for the target
     project, and one to save the files. That should take care of the complaints raised
     by the OS, and may make the project workable sandboxed
     */
    func saveIconFiles() {
        view.window?.title = "Select Target Project for Install"
        let saveDialog = NSOpenPanel()
        saveDialog.prompt = "Select Project"
        saveDialog.allowedFileTypes = ["xcodeproj", "xcworkspace"]
        saveDialog.beginSheetModal(for: view.window!) { (response: NSApplication.ModalResponse) in
            if response == .OK {
                guard let projectFileURL = saveDialog.url,
                    let json = self.getContentsJsonFromProject(projURL: projectFileURL)
                else {
                    self.showWarning(
                        message: "Could not open Contents.json",
                        info: "Contents.json does not exist or could not be opened for project at path: \(saveDialog.url?.path ?? "N/A")"
                    )
                    return
                }

                let imagesAllJson = json["images"].array

                var imageNames : [String]
                if let sizesJson = imagesAllJson {
                    let projectBaseURL = projectFileURL.deletingPathExtension()
                    imageNames = self.makeScaledImages(sizesJson, projectPath: projectBaseURL)
                    self.buildContentsJsonFile(fileNames: imageNames, contentsJson: json, projectPath: projectBaseURL)
                } else {
                    self.showWarning(message: "No image metadata in JSON", info: "Contents.json does not contain any image metadata")
                }
            }

            self.view.window?.title = self.appInfo["name"]!
        }
    }

    /**
     Read in the Contents.json file

     From the project path, read the appiconset contents.json file and return
     it as a JSON object
 
     - Parameter projURL: The file URL of the target project, or workspace
     - Returns: a JSON object optional
     */
    func getContentsJsonFromProject(projURL: URL) -> JSON? {
        let urlBase = projURL.deletingPathExtension() // needed?

        let components = kAIIconAssetsPathComponents
        let contentsPath = components["directory"]! + components["file"]!
        let contentsJsonURL = urlBase.appendingPathComponent(contentsPath)

        guard FileManager.default.fileExists(atPath: contentsJsonURL.path),
            let fileContents = try? String(contentsOf: contentsJsonURL)
        else {
            os_log("Contents.json file does not exist at that path, or is unreadable")
            return nil
        }

        return JSON(parseJSON: fileContents)
    }

    /**
     Add icon image data and write Contents.json

     Add the icon image filenames to the images section of contents.json
     and write to disk

     - Parameter fileNames: Array of image file names
     - Parameter contentsJson: the full contents.json as JSON object
     - Parameter projectPath: the URL of the target project
     */
    func buildContentsJsonFile(fileNames: [String], contentsJson: JSON, projectPath: URL) {
        if var imagesJson = contentsJson["images"].array {
            for (index, _) in imagesJson.enumerated() {
                imagesJson[index]["filename"].stringValue = fileNames[index]
            }

            var theJson = contentsJson
            theJson["info"]["author"].stringValue = appInfo["name"] ?? "AppIcon"
            theJson["info"]["version"].stringValue = appInfo["version"] ?? "N/A"
            theJson["images"].arrayObject = imagesJson

            let components = kAIIconAssetsPathComponents
            let contentsPath = components["directory"]! + components["file"]!
            let contentsJsonURL = projectPath.appendingPathComponent(contentsPath)

            do {
                try theJson.rawString()?.write(to: contentsJsonURL, atomically: true, encoding: .utf8)
            } catch {
                NSAlert(error: error).beginSheetModal(for: self.view.window!, completionHandler: nil)
            }
        }
    }

    /**
     Create all Icon images

     Create all app icon images specified in the Contents.json file

     - Parameter imagesJson: Array of JSON image specifications
     - Parameter projectPath: URL of the target project or workspace
     - Returns: Array of String image file names
     */
    func makeScaledImages(_ imagesJson: [JSON], projectPath: URL) -> [String] {
        guard let sourceImage = loadedImageView.image else {
            showWarning(message: "No Source Image", info: "There is no valid source image. Please select a valid image file (PNG, JPG).")
            return []
        }

        var imageNames = [String]()
        let savePath = projectPath.appendingPathComponent(kAIIconAssetsPathComponents["directory"]!)
        for image in imagesJson {
            if let theSize = Scaler.dimensionsFromWxHString(image["size"].stringValue, scale: image["scale"].doubleValue) {
                let scaledImage = Scaler.imageCIScale(sourceImage, dimension: theSize.height)
                let imageName = String(format: "AppIcon%@-%@.png", image["size"].stringValue, image["scale"].stringValue)
                self.saveAsPNG(scaledImage, name: savePath.appendingPathComponent(imageName))
                imageNames.append(imageName)
            }
        }

        return imageNames
    }

    /**
     Save image as a PNG file
     
     - Parameter image: NSImage to be saved
     - Parameter name: New image file name
     */
    func saveAsPNG(_ image: NSImage?, name: URL) {
        guard let theImage = image, let data = theImage.tiffRepresentation, let rep = NSBitmapImageRep(data: data) else {
            os_log("No tiff representation, or no bitmap image representation. Function: %@ line: %@", #function, #line)
            return
        }
        
        if let imageData = rep.representation(using: .png, properties: [.compressionFactor : NSNumber(floatLiteral: 1.0)]) {
            do {
                try imageData.write(to: name)
            } catch {
                print(error)
            }
        }
    }

    func showWarning(message: String, info: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = info
        alert.alertStyle = .warning

        alert.beginSheetModal(for: view.window!, completionHandler: nil)
    }

    func getAppDelegate() -> AppDelegate? {
        return NSApplication.shared.delegate as? AppDelegate
    }

    @IBAction func saveButtonClicked(_ sender: Any) {
        saveIconFiles()
    }

    // This only runs for DnD
    @IBAction func loadedImageViewAction(_ sender: DragNDropImageView) {
        guard let theImage = sender.image else {
            showWarning(message: "Not an Image", info: "Dropped file does not appear to be an acceptable image format (PNG, JPG)")
            loadedImageView.image = NSImage(named: "Large")
            os_log("Drag and Drop operation failed. No accessible image in ImageView")
            return
        }

        checkImage(theImage)
        sourceImageFilename = sender.imageFileName
        setupInfoView()
    }
    
    @IBAction func closeInfoViewClicked(_ sender: Any) {
        infoView.isHidden = true
    }
}

