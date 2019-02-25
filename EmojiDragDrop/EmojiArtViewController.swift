//
//  ViewController.swift
//  EmojiDragDrop
//
//  Created by Marcos Felipe Souza on 11/02/19.
//  Copyright © 2019 Marcos. All rights reserved.
//

import UIKit
import MobileCoreServices
import os.log

class EmojiArtViewController: UIViewController {
    

    @IBOutlet weak var dropZoneView: UIView! {
        didSet {
            dropZoneView.addInteraction(UIDropInteraction(delegate: self))
        }
    }
    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
    @IBOutlet weak var scrollViewWidth: NSLayoutConstraint!
    
    var emojiArt: EmojiArt? {
        get {
            if let imageSource = emojiArtBackgroundImage {
                let emojis = emojiArtView.subviews.compactMap {$0 as? UILabel}.compactMap { EmojiArt.EmojiInfo(label: $0)}
                switch imageSource {
                case .local(let data, _):
                    return EmojiArt(imageData: data, emojis: emojis)
                case .remote(let url, _):
                    return EmojiArt(url: url, emojis: emojis)
                }
            }
            return nil
        }
        set {
            emojiArtBackgroundImage = nil
            emojiArtView.subviews.compactMap { $0 as? UILabel}.forEach { $0.removeFromSuperview() }
            
            let imageData = newValue?.imageData
            let image = (imageData != nil) ? UIImage(data: imageData!) : nil
            if let url = newValue?.url {
                imageFetcher = ImageFetcher(fetch: url, handler: { (url, image) in
                    DispatchQueue.main.async {
                        
                        if image == self.imageFetcher.backup {
                            self.emojiArtBackgroundImage = .local(imageData!, image)
                        } else {
                            self.emojiArtBackgroundImage = .remote(url, image)
                        }
                    }
                })
                imageFetcher.backup = image
                imageFetcher.fetch(url)
            
            } else if image != nil {
                emojiArtBackgroundImage = .local(imageData!, image!)
            }
            
            newValue?.emojis.forEach { model in
                let attributedText = model.text.attributedString(withTextStyle: .body, ofSize: CGFloat(model.size))
                self.emojiArtView.addLabel(with: attributedText, centeredAt: CGPoint(x: model.x, y: model.y))
            }
            
        }
    }
    
    enum ImageSource {
        case remote(URL, UIImage)
        case local(Data, UIImage)
        
        var image: UIImage {
            switch self {
                case .remote(_, let image): return image
                case .local(_, let image): return image
            }
        }
    }
    
    private var _emojiArtBackgroundImageURL: URL?
    var emojiArtBackgroundImage: ImageSource? {
        didSet {
            scrollView?.zoomScale = 1.0
            //_emojiArtBackgroundImageURL = emojiArtBackgroundImage?.image
            emojiArtView.backgroundImage = emojiArtBackgroundImage?.image
            let size = emojiArtBackgroundImage?.image.size ?? CGSize.zero
            emojiArtView.frame = CGRect(origin: CGPoint.zero, size: size)
            scrollView?.contentSize = size
            scrollViewHeight?.constant = size.height
            scrollViewWidth?.constant = size.width
            guard let dropZone = self.dropZoneView, size.width > 0, size.height > 0 else {
                return
            }
            scrollView?.zoomScale = max(dropZone.bounds.size.width / size.width, dropZone.bounds.size.height / size.height)
            self.documentChanged()
        }
    }
    
    
    private var font: UIFont {
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(64.0))
    }
    
    var emojis = "🦁🐒🐥🐘🦉🐷🐝🦋🐴🐗🐧🐸🐼🐻🐔🐮🐯🦍🦢🐹🦜🐶".map {String($0)}
    var emojiArtView: EmojiArtView = EmojiArtView()
    
    var imageFetcher: ImageFetcher!
    
    
    @IBOutlet weak var emojiCollectionView: UICollectionView! {
        didSet {
            emojiCollectionView.delegate = self
            emojiCollectionView.dataSource = self
            emojiCollectionView.dragDelegate = self
            emojiCollectionView.dropDelegate = self
            
            //para iPhone
            emojiCollectionView.dragInteractionEnabled = true
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
    
    
    
    private var addingEmoji = false
    @IBAction func addEmoji(_ sender: UIButton) {
        addingEmoji = true
        emojiCollectionView.reloadSections(IndexSet(integer: 0))
    }
    
    var document: EmojiArtDocument?
    
    //Close the file for open others
    @IBAction func closeButton(_ sender: UIBarButtonItem) {
        //self.saveButton()
        self.documentChanged()
        if document?.emojiArt != nil {
            document?.thumbnail = emojiArtView.snapshot
        }
        dismiss(animated: true) {  [weak self] in
            self?.document?.close()
        }
        
    }

    @IBOutlet weak var cameraButton: UIBarButtonItem! {
        didSet {
            cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        }
    }
    @IBAction func cameraButtonDidTap(_ sender: UIBarButtonItem)  {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [kUTTypeImage as String]
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
        
    }
    
    //Save in file
//    @IBAction func saveButton(_ sender: UIBarButtonItem? = nil) {
//        //saveWithFileManager()
//        self.document?.emojiArt = emojiArt
//        if self.document?.emojiArt != nil {
//            self.document?.updateChangeCount(.done)
//        }
//    }
    private var documentObserver: NSObjectProtocol?
    private var emojiArtObserver: NSObjectProtocol?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        //loadJsonFileManager()
        
        if document?.documentState != .normal { //ViewDidApper sempre run qndo a camera dar dismiss().
            documentObserver = NotificationCenter.default.addObserver(
                forName: .UIDocumentStateChanged,
                object: document,
                queue: OperationQueue.main,
                using: { [weak self] notification in
                    print("documentState chage to \(self?.document?.documentState)")
            })
            
            emojiArtObserver = NotificationCenter.default.addObserver(
                forName: .emojiArtViewDidChange,
                object: self.emojiArtView,
                queue: OperationQueue.main,
                using: { [weak self] notification in
                    self?.documentChanged()
            })
            
            document?.open { [weak self] success in
                if success {
                    self?.title = self?.document?.localizedName
                    self?.emojiArt = self?.document?.emojiArt
                }
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        if let documentObserver = self.documentObserver {
            NotificationCenter.default.removeObserver(documentObserver)
        }
        if let emojiArtObserver = self.emojiArtObserver {
            NotificationCenter.default.removeObserver(emojiArtObserver)
        }
    }
    private func documentChanged() {
        os_log("salvando o doc.", log: OSLog.default, type: .debug)
        
        document?.emojiArt = emojiArt
        if document?.emojiArt != nil {
            document?.updateChangeCount(.done)
        }
    }

    //Init o Document
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        if let url = try? FileManager.default.url(
//            for: .documentDirectory,
//            in: .userDomainMask,
//            appropriateFor: nil,
//            create: true
//        ).appendingPathComponent("Untitled.json") {
//            self.document = EmojiArtDocument(fileURL: url)
//        }
//    }
    
    private var supressBadURLWarnings = false
    private func presentBadURLWarning(for url: URL?) {
        
        guard !supressBadURLWarnings else { return }
        
        let alert = UIAlertController(title: "Image Transfer Failed",
                                      message: "Couldn't transfer the dropped image from its source",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Keep Warning",
                                      style: .default))
        
        alert.addAction(UIAlertAction(
            title: "Stop Warning",
            style: .destructive,
            handler: { action in
                self.supressBadURLWarnings = true
        }))
        
        present(alert, animated: true)
    }
    
    private func saveWithFileManager() {
        if let json = self.emojiArt?.json {
            
            if let url = try? FileManager.default.url(for: .documentDirectory,
                                                      in: .userDomainMask,
                                                      appropriateFor: nil,
                                                      create: true) {
                
                let urlCompleted = url.appendingPathComponent("Untitled.json")
                
                do {
                    try json.write(to: urlCompleted)
                    print("Save with success")
                } catch let error {
                    print("couldn't save \(error)")
                }
                
            }
            
            if let jsonString = String(data: json, encoding: .utf8) {
                print(jsonString)
            }
        }
    }
    
    private func loadJsonFileManager() {
        guard let url = try? FileManager.default.url(for: .documentDirectory,
                                                     in: .userDomainMask,
                                                     appropriateFor: nil,
                                                     create: true)
            .appendingPathComponent("Untitled.json") else { return }
        
        
        guard let jsonData = try? Data(contentsOf: url) else { return }
        self.emojiArt = EmojiArt(json: jsonData)
    }
    
    private func attributedStringEmoji(at index: IndexPath) -> NSAttributedString? {
        guard let emojiCell: EmojiCollectionViewCell =
            self.emojiCollectionView.cellForItem(at: index) as? EmojiCollectionViewCell,
            let emojiText = emojiCell.label.attributedText else { return nil }
        return emojiText
    }
    
}

//MARK: - EmojiArtViewDelegate
//extension EmojiArtViewController: EmojiArtViewDelegate {
//    func emojiArtViewDidChange(_ sender: EmojiArtView) {
//        documentChanged()
//    }
//}
//MARK: - UIImagePickerControllerDelegate e UINavigationControllerDelegate
extension EmojiArtViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.presentingViewController?.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let imageGalery = (info[UIImagePickerControllerEditedImage] ?? info[UIImagePickerControllerOriginalImage]) as? UIImage {
            guard let image = imageGalery.scaled(by: 0.25) else {return}
            //let named = String(describing: Date.timeIntervalSinceReferenceDate)
            //let url = image?.storeLocallyAsJPEG(named: named)
            guard let imageData = UIImageJPEGRepresentation(image, 1.0) else { return }
            self.emojiArtBackgroundImage = EmojiArtViewController.ImageSource.local(imageData, image)
        }
        
        picker.presentingViewController?.dismiss(animated: true)
    }
    
}

//MARK: - UICollectionViewDelegate
extension EmojiArtViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let inputCell = cell as? TextFieldCollectionViewCell {
            inputCell.textField.becomeFirstResponder()
        }
    }
    
}

//MARK: - UICollectionViewDataSource
extension EmojiArtViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch section {
            case 0: return 1
            case 1: return emojis.count
            default: return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 1 {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath) as? EmojiCollectionViewCell else { return UICollectionViewCell() }
            let text = NSAttributedString(string: emojis[indexPath.item], attributes: [.font: font])
            cell.label.attributedText = text
            return cell
        
        } else if addingEmoji {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiInputCell", for: indexPath)
            if let textFieldCell = cell as? TextFieldCollectionViewCell {
                textFieldCell.resignedHandle = { [weak self, unowned textFieldCell] in
                    guard let text = textFieldCell.textField.text else { return }
                    self?.emojis = (text.map{ String($0) } + (self?.emojis ?? [])).uniquified
                    self?.addingEmoji = false
                    self?.emojiCollectionView.reloadData()
                }
            }
            return cell
        
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddEmojiButtonCell", for: indexPath)
            return cell
        }
    }
}

//MARK: -  UICollectionViewDelegateFlowLayout
extension EmojiArtViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if addingEmoji && indexPath.section == 0 {
            return CGSize(width: 300, height: 80)
        } else {
            return CGSize(width: 80, height: 80)
        }
    }
}

//MARK: - UIScrollViewDelegate
extension EmojiArtViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return emojiArtView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.scrollViewWidth.constant = scrollView.contentSize.width
        self.scrollViewHeight.constant = scrollView.contentSize.height
    }
}

//MARK: - UIDropInteractionDelegate
extension EmojiArtViewController: UIDropInteractionDelegate {
    
    //Apenas pode fazer drag and drop NSURL e UIImage
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSURL.self) || session.canLoadObjects(ofClass: UIImage.self)
    }
    
    //Copia o drag and drop de um app de fora pra dentro do dropZone
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        
        self.imageFetcher = ImageFetcher() { (url, image) in
            DispatchQueue.main.async {
                self.emojiArtBackgroundImage = .remote(url, image)
            }
        }
        
        session.loadObjects(ofClass: NSURL.self) { urls in
            guard let url = urls.first as? URL else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                if let dataImage = try? Data(contentsOf: url.imageURL), let image = UIImage(data: dataImage) {
                    DispatchQueue.main.async {
                        self.emojiArtBackgroundImage = .remote(url, image)
                    }
                } else {
                    self.presentBadURLWarning(for: url)
                }
                
            }
            
//            self.imageFetcher.fetch(url)
        }
        session.loadObjects(ofClass: UIImage.self) { images in
            guard let image = images.first as? UIImage else { return }
            guard let imageData = UIImageJPEGRepresentation(image, 1.0) else { return }
            self.emojiArtBackgroundImage = .local(imageData, image)
            self.imageFetcher.backup = image
        }
    }
}

//MARK: - UICollectionViewDropDelegate
extension EmojiArtViewController: UICollectionViewDropDelegate {
    
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
                let dropPlaceholder = UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "DropPlaceholderCell")
                
                let placeholderContext = coordinator.drop(item.dragItem, to: dropPlaceholder)
                item.dragItem.itemProvider.loadObject(ofClass: NSAttributedString.self) { (provider, error) in
                    DispatchQueue.main.async {
                        guard let attributedString = provider as? NSAttributedString else {
                            placeholderContext.deletePlaceholder()
                            return
                        }
                        placeholderContext.commitInsertion(dataSourceUpdates: { insertionIndexPath in
                            self.emojis.insert(attributedString.string, at: insertionIndexPath.item)
                        })
                    }
                }
            }
        }
    }
    
    
    //Altera a sessao quando navega com o drag, para soltar.
    func collectionView(_ collectionView: UICollectionView,
                        dropSessionDidUpdate session: UIDropSession,
                        withDestinationIndexPath destinationIndexPath: IndexPath?)
        -> UICollectionViewDropProposal {
            
            guard let indexPath = destinationIndexPath, indexPath.section == 1 else {
                return UICollectionViewDropProposal(operation: .cancel)
            }
            
            let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
            return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
    }
}

// MARK: - UICollectionViewDragDelegate
extension EmojiArtViewController: UICollectionViewDragDelegate {
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
        guard let attributeString = attributedStringEmoji(at: index), !addingEmoji else { return [] }
        let dragItem = UIDragItem(itemProvider: NSItemProvider(object: attributeString))
        dragItem.localObject = attributeString
        return [dragItem]
    }
    
    // primeiro passo, serve para pegar o elemento... so pegaremos o objeto do tipo NSAttributedString
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSAttributedString.self)
    }
}
