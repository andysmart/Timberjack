import UIKit
import Timberjack

class ViewController: UIViewController {
    @IBAction func requestPressed(_ sender: AnyObject) {
        requestURL()
    }
    
    func requestURL() {
        let url = URL(string: "http://httpbin.org/get")!
        
        let task = URLSession.shared.dataTask(with: url)
        task.resume()
    }
}

