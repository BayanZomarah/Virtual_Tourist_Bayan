

import Foundation
import UIKit


extension PhotoAlbumViewController: UICollectionViewDelegate , UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return fetchedResultsController.fetchedObjects!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCollectionCell", for: indexPath) as! PhotoCollectionViewCell
        
        let photo = fetchedResultsController.object(at: indexPath)
        
        if let data = photo.imageDATA {
            cell.image.image = UIImage(data: data)
        } else {
            cell.image.image = UIImage(named: "lo")
            cell.contentView.alpha = 1.0

            downloadImage(imagePath: photo.photoURL!) { imageData, errorString in
                if let imageData = imageData {
                    DispatchQueue.main.async {
                        cell.image.image = UIImage(data: imageData)
                    }
                    photo.imageDATA = imageData
                    try? self.dataController.viewContext.save()
                }
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let cell = collectionView.cellForItem(at: indexPath)
        cell?.contentView.alpha = 0.4
        
        if selectedPhotos.contains(indexPath) == false {
            selectedPhotos.append(indexPath)
        }
        selectPhotoActionButton()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.contentView.alpha = 1.0
        
        if let index = selectedPhotos.firstIndex(of: indexPath) {
            selectedPhotos.remove(at: index)
        }
        selectPhotoActionButton()
    }

    func selectPhotoActionButton() {
        if selectedPhoto() {
            toolbarButton.title = "Delete Selected Photos"
            toolbarButton.tintColor = .red
        }
        else {
            toolbarButton.title = "Update Collection"
            toolbarButton.tintColor = .yellow
        }
    }

    func selectedPhoto() -> Bool {
        if selectedPhotos.count == 0 {
            return false
        }
        return true
    }

    func deSelectedPhotos() {
        let photos = selectedPhotos.map() { fetchedResultsController.object(at: $0) }
        photos.forEach() { photo in
            dataController.viewContext.delete(photo)
            try? dataController.viewContext.save()
        }
        
        selectedPhotos.removeAll()
        selectPhotoActionButton()
    }
}

