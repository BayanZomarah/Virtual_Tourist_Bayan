
import UIKit
import MapKit
import CoreData

class TravelLocationMapViewController: UIViewController{
    
 
    var dataController: DataController!
    var fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
    

    @IBOutlet var mapView: MKMapView!
    
    var pinned: Pin!

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        loadAllPins()
        
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(TravelLocationMapViewController.handleLongPress(_:)))
        longPressRecogniser.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressRecogniser)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadAllPins()
    }
    

    @objc func handleLongPress(_ gestureRecognizer : UIGestureRecognizer){
        if gestureRecognizer.state != .began { return }
        let touchPoint = gestureRecognizer.location(in: mapView)
        let touchMapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        newAnnotation(Coordinate: touchMapCoordinate)
    }
    
   
    
    func newAnnotation(Coordinate: CLLocationCoordinate2D ){
        let annotation = MKPointAnnotation()
        annotation.coordinate = Coordinate
        persistNewPin(location: Coordinate)
        mapView.addAnnotation(annotation)
    }
    
    // MARK: Save Pin Data
   
    
    // MARK: Load All Pins
    
    func loadAllPins() {
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            for pin in result {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude), longitude: CLLocationDegrees(pin.longitute))
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "photoAlbumSegue"{
            let viewC = segue.destination as! PhotoAlbumViewController
            viewC.pin = pinned
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("tapped on pin")
        //assign lat and log
        if let alatitude = view.annotation?.coordinate.latitude , let alongitude = view.annotation?.coordinate.longitude {
            if let result = try? dataController.viewContext.fetch(fetchRequest) {
                for pin in result {
                    if pin.latitude == alatitude && pin.longitute == alongitude {
                        pinned = pin
                        print("inside mapview did select")
                        self.performSegue(withIdentifier: "photoAlbumSegue", sender: nil)
                    }
                    else {
                        print("returning")
                    }
                    
                }
            }
        }
    }
    
    
}

//commit
