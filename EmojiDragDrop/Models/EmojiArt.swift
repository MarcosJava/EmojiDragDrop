//
//  EmojiArt.swift
//  EmojiDragDrop
//
//  Created by Marcos Felipe Souza on 17/02/19.
//  Copyright © 2019 Marcos. All rights reserved.
//

import UIKit

struct EmojiArt: Codable {
    
    var url: URL
    var emojis = [EmojiInfo]()
    
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }
    
    struct EmojiInfo: Codable {
        let x: Int
        let y: Int
        let text: String
        let size: Int
    }
    init(url: URL, emojis: [EmojiInfo]) {
        self.url = url
        self.emojis = emojis
    }
    
    init?(json: Data) {
        guard let newValue = try? JSONDecoder().decode(EmojiArt.self, from: json) else { return nil }
        self = newValue
    }
    
}

extension EmojiArt.EmojiInfo {
    init?(label: UILabel) {
        if let attributedText = label.attributedText, let font = attributedText.font {
            x = Int(label.center.x)
            y = Int(label.center.y)
            text = attributedText.string
            size = Int(font.pointSize)
        } else {
            return nil
        }
    }
}
