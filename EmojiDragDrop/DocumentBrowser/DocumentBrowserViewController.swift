//
//  DocumentBrowserViewController.swift
//  EmojiDragDropFile
//
//  Created by Marcos Felipe Souza on 19/02/19.
//  Copyright © 2019 Marcos. All rights reserved.
//

import UIKit


class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        allowsDocumentCreation = false
        allowsPickingMultipleItems = false
        
        
        //browserUserInterfaceStyle = .light
        
        // Update the style of the UIDocumentBrowserViewController
        // view.tintColor = .white
        // Specify the allowed content types of your application via the Info.plist.
        // Do any additional setup after loading the view, typically from a nib.
        
        if UIDevice.current.userInterfaceIdiom == .pad { //So pode criar image via iPad
            template = try? FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("Untitled.json")
            
            if template != nil {
                allowsDocumentCreation = FileManager.default.createFile(atPath: template!.path, contents: Data())
            }
        }
        
    }
    
    
    // MARK: UIDocumentBrowserViewControllerDelegate
    var template: URL?
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        
        importHandler(template, .copy)
        
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
        guard let sourceURL = documentURLs.first else { return }
        
        // Present the Document View Controller for the first document that was picked.
        // If you support picking multiple items, make sure you handle them all.
        presentDocument(at: sourceURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        // Present the Document View Controller for the new newly created document
        presentDocument(at: destinationURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
    }
    
    // MARK: Document Presentation
    
    func presentDocument(at documentURL: URL) {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        guard let splitView = storyBoard.instantiateViewController(withIdentifier: "splitMVC") as? UISplitViewController else { return }
        
        guard let navView = splitView.viewControllers[1] as? UINavigationController else { return }
        
        
        if let emojiArtViewController = navView.viewControllers.first as? EmojiArtViewController {
            emojiArtViewController.document = EmojiArtDocument(fileURL: documentURL)
        }
        present(splitView, animated: true)
    }
}

