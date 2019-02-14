//
//  ViewController.swift
//  EmojiDragDrop
//
//  Created by Marcos Felipe Souza on 11/02/19.
//  Copyright © 2019 Marcos. All rights reserved.
//

import UIKit

class EmojiArtViewController: UIViewController, UIDropInteractionDelegate, UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    

    @IBOutlet weak var dropZoneView: UIView! {
        didSet {
            dropZoneView.addInteraction(UIDropInteraction(delegate: self))
        }
    }
    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
    @IBOutlet weak var scrollViewWidth: NSLayoutConstraint!
    
    var emojiArtView = EmojiArtview()
    var imageFetcher: ImageFetcher!
    
    
    @IBOutlet weak var emojiCollectionView: UICollectionView! {
        didSet {
            emojiCollectionView.delegate = self
            emojiCollectionView.dataSource = self
            emojiCollectionView.dragDelegate = self
            emojiCollectionView.dropDelegate = self
        }
    }
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.minimumZoomScale = 0.1
            scrollView.maximumZoomScale = 5.0
            scrollView.delegate = self
            scrollView.addSubview(emojiArtView)
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return emojiArtView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.scrollViewWidth.constant = scrollView.contentSize.width
        self.scrollViewHeight.constant = scrollView.contentSize.height
    }
    
    
    var emojiArtBackgroundImage: UIImage? {
        get {
            return emojiArtView.backgroundImage
        }
        set {
            scrollView?.zoomScale = 1.0
            emojiArtView.backgroundImage = newValue
            let size = newValue?.size ?? CGSize.zero
            emojiArtView.frame = CGRect(origin: CGPoint.zero, size: size)
            scrollView?.contentSize = size
            scrollViewHeight?.constant = size.height
            scrollViewWidth?.constant = size.width
            guard let dropZone = self.dropZoneView, size.width > 0, size.height > 0 else {
                return
            }
            
            scrollView?.zoomScale = max(dropZone.bounds.size.width / size.width, dropZone.bounds.size.height / size.height)
        }
    }
    
    //Apenas pode fazer drag and drop NSURL e UIImage
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
    }
    
    //Copia o drag and drop de um app de fora pra dentro do dropZone
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        
        self.imageFetcher = ImageFetcher() { (url, image) in
            DispatchQueue.main.async {
                self.emojiArtBackgroundImage = image
            }
        }
        
        session.loadObjects(ofClass: NSURL.self) { urls in
            guard let url = urls.first as? URL else { return }
            self.imageFetcher.fetch(url)
        }
        session.loadObjects(ofClass: UIImage.self) { images in
            guard let image = images.first as? UIImage else { return }
            self.imageFetcher.backup = image
        }
    }
    
    var emojis = "🐒🐥🐘🦍🦢🦜🐶".map {String($0)}
    private var font: UIFont {
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(64.0))
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emojis.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath) as? EmojiCollectionViewCell else { return UICollectionViewCell() }
        let text = NSAttributedString(string: emojis[indexPath.item], attributes: [.font: font])
        cell.label.attributedText = text
        return cell
    }
    
    //mark: - Drag Delegate.
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        print("itemsForBeginning")
        return dragItem(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        print("itemsForAddingTo")
        return dragItem(at: indexPath)
    }
    
    private func dragItem(at index: IndexPath) -> [UIDragItem]{
        guard let attributeString = emoji(at: index) else { return [] }
        let dragItem = UIDragItem(itemProvider: NSItemProvider(object: attributeString))
        dragItem.localObject = attributeString
        return [dragItem]
    }
    
    private func emoji(at index: IndexPath) -> NSAttributedString? {
        guard let emojiCell: EmojiCollectionViewCell =
            self.emojiCollectionView.cellForItem(at: index) as? EmojiCollectionViewCell,
            let emojiText = emojiCell.label.attributedText else { return nil }
        return emojiText
    }
    
    // MARk: - Drop Delegate.
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        //qndo dragdrop mais de 1
        for item in coordinator.items {
            
            if let sourceIndexPath = item.sourceIndexPath { //drag dentro do app
                
                guard let attributedString = item.dragItem.localObject as? NSAttributedString else { continue }
            
                //animation da CollectionView.
                collectionView.performBatchUpdates({
                    emojis.remove(at: sourceIndexPath.item)
                    emojis.insert(attributedString.string, at: destinationIndexPath.item)
                    collectionView.deleteItems(at: [sourceIndexPath])
                    collectionView.insertItems(at: [destinationIndexPath])
                })
                //animation do drop
                coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
            
            } else { //drag fora do app
                
            }
        }
    }
    // primeiro passo, serve para pegar o elemento... so pegaremos o objeto do tipo NSAttributedString
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSAttributedString.self)
    }
    
    //Altera a sessao quando navega com o drag, para soltar.
    func collectionView(_ collectionView: UICollectionView,
                        dropSessionDidUpdate session: UIDropSession,
                        withDestinationIndexPath destinationIndexPath: IndexPath?)
        -> UICollectionViewDropProposal {
            
        let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
        return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
    }
    
}

