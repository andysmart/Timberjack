import UIKit
import Timberjack

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Timberjack.logStyle = .verbose //Either .Verbose, or .Light
        Timberjack.register() //Register Timberjack to log all requests
        
        return true
    }
}

