import UIKit
import Timberjack

class ViewController: UIViewController {
    
    @IBAction func requestPressed(sender : AnyObject) {
        requestURL()
    }
    
    func requestURL() {
        let url = NSURL(string: "http://httpbin.org/get")!
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(url)
        task.resume()
    }
}

