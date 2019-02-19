//
//  Document.swift
//  EmojiDragDropFile
//
//  Created by Marcos Felipe Souza on 19/02/19.
//  Copyright © 2019 Marcos. All rights reserved.
//

import UIKit

class Document: UIDocument {
    
    override func contents(forType typeName: String) throws -> Any {
        // Encode your document with an instance of NSData or NSFileWrapper
        return Data()
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // Load your document from contents
    }
}

