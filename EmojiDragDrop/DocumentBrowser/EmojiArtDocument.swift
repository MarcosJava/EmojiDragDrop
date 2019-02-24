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
    var thumbnail: UIImage?
    
    // Encode your document with an instance of NSData or NSFileWrapper
    override func contents(forType typeName: String) throws -> Any {
        return self.emojiArt?.json ?? Data()
    }
    
    // Load your document from contents
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let json = contents as? Data else { return }
        self.emojiArt = EmojiArt(json: json)
    }
    
    //Sobre escreve a imagem do documento
    override func fileAttributesToWrite(to url: URL, for saveOperation: UIDocumentSaveOperation) throws -> [AnyHashable : Any] {
        
        var attributes = try super.fileAttributesToWrite(to: url, for: saveOperation)
        if let thumbnail = self.thumbnail {
            attributes[URLResourceKey.thumbnailDictionaryKey] = [URLThumbnailDictionaryItem.NSThumbnail1024x1024SizeKey: thumbnail]
        }
        return attributes
    }
}

