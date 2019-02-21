//
//  Document.swift
//  EmojiDragDropFile
//
//  Created by Marcos Felipe Souza on 19/02/19.
//  Copyright © 2019 Marcos. All rights reserved.
//

import UIKit

class EmojiArtDocument: UIDocument {
    
    var emojiArt: EmojiArt?
    
    // Encode your document with an instance of NSData or NSFileWrapper
    override func contents(forType typeName: String) throws -> Any {
        return self.emojiArt?.json ?? Data()
    }
    
    // Load your document from contents
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let json = contents as? Data else { return }
        self.emojiArt = EmojiArt(json: json)
    }
}

