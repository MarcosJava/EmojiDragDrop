//
//  EmojiArtview.swift
//  EmojiDragDrop
//
//  Created by Marcos Felipe Souza on 11/02/19.
//  Copyright © 2019 Marcos. All rights reserved.
//

import UIKit

class EmojiArtview: UIView {
    
    var backgroundImage: UIImage? {
        didSet {
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        backgroundImage?.draw(in: bounds)
    }

}
