

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let dataController = DataController(modelName: "coreDataVT")


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        dataController.load()
        let navigationController = window?.rootViewController as! UINavigationController
        let mapVC = navigationController.topViewController as! TravelLocationMapViewController
        mapVC.dataController = dataController
        
        return true
    }
}
