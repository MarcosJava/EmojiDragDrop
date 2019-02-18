//
//  TextFieldCollectionViewCell.swift
//  EmojiDragDrop
//
//  Created by Marcos Felipe Souza on 16/02/19.
//  Copyright © 2019 Marcos. All rights reserved.
//

import UIKit

class TextFieldCollectionViewCell: UICollectionViewCell, UITextFieldDelegate {
    
    @IBOutlet weak var textField: UITextField! {
        didSet {
            textField.delegate = self
        }
    }
    
    var resignedHandle: (()-> Void)?
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        resignedHandle?()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("Got here")
        textField.resignFirstResponder()
        return true
    }
    
}
