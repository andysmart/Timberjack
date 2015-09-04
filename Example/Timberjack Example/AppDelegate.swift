import UIKit
import Timberjack

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        Timberjack.logStyle = .Verbose //Either .Verbose, or .Light
        Timberjack.register() //Register Timberjack to log all requests
        
        return true
    }
}

