
import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController  {
    
    


    @IBOutlet var mapView: MKMapView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var toolbarButton: UIBarButtonItem!

    
    var pin: Pin!
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photos>!
    var selectedPhotos: [IndexPath]! = []
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.allowsMultipleSelection = true
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        dataController = appDelegate.dataController
        
       
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self

        setupFetchedResultsController()
        if fetchedResultsController.fetchedObjects!.count == 0 {
            print("loading photos")
            getPhotos()
        }
    }
    
    
    func setupFetchedResultsController() {
        
        let fetchRequest:NSFetchRequest<Photos> = Photos.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do{
            try fetchedResultsController.performFetch()
        }catch{
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        
    }
    
    struct showAlert {
        
        static func showAlert(message: String, title: String, vc: UIViewController)
        {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            let OKAction = UIAlertAction(title: "ok", style: .default, handler: nil)
            alertController.addAction(OKAction)
            
            vc.present(alertController, animated: true, completion: nil)
        }
        
        
        
    }

    
    func getPhotos() {
        
        let call = FlickrApi.sharedInstance
        
        call.getPhotosforLocation(pin.latitude, pin.longitute, 20) { (success, photos) in
            
            if success == false {
                print("Unable to download images from Flickr.")
                return
            }
            
            print("Flickr images fetched : \(photos!.count)")
            if photos!.count == 0 {
                
                showAlert.showAlert(message: "This location contains no images, try another location", title: "Error..", vc: self)
            }
            
            photos!.forEach() { url in
                let photo = Photos(context: self.dataController.viewContext)
                photo.photoURL = URL(string: url["url_m"] as! String)?.absoluteString
                photo.pin = self.pin
                
                do {
                    try self.dataController.viewContext.save()
                } catch  {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func downloadImage( imagePath:String, completionHandler: @escaping (_ imageData: Data?, _ errorString: String?) -> Void){

        let session = URLSession.shared
        let imgURL = NSURL(string: imagePath)
        let request: NSURLRequest = NSURLRequest(url: imgURL! as URL)
        
        let task = session.dataTask(with: request as URLRequest) {data, response, downloadError in
            
            if downloadError != nil {
                completionHandler(nil, "Could not download image \(imagePath)")
            } else {
                
                completionHandler(data, nil)
            }
        }
        task.resume()
    }

    @IBAction func updateCollection(_ sender: Any) {
        if selectedPhoto() {
            deSelectedPhotos()
        } else {
            fetchedResultsController.fetchedObjects?.forEach() { photo in
                dataController.viewContext.delete(photo)
                do {
                    try dataController.viewContext.save()
                } catch {
                    print("Unable to delete photo. \(error.localizedDescription)")
                }
            }
            getPhotos()
            self.collectionView.reloadData()
        }
    }
    
}


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

