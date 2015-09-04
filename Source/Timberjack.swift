import Foundation

let TimberjackRequestHandledKey = "Timberjack"

public class Timberjack: NSURLProtocol {
    var connection: NSURLConnection?
    var data: NSMutableData?
    var response: NSURLResponse?
    
    //MARK: - NSURLProtocol
    
    public override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        guard self.propertyForKey(TimberjackRequestHandledKey, inRequest: request) != nil else {
            return false
        }
        
        return true
    }
    
    public override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }
    
    public override class func requestIsCacheEquivalent(a: NSURLRequest, toRequest b: NSURLRequest) -> Bool {
        return super.requestIsCacheEquivalent(a, toRequest: b)
    }

    public override func startLoading() {
        guard let newRequest = request.mutableCopy() as? NSMutableURLRequest else { return }
        
        Timberjack.setProperty(true, forKey: TimberjackRequestHandledKey, inRequest: newRequest)
        connection = NSURLConnection(request: newRequest, delegate: self)
        
        print("---------------------")
        
        if let url = newRequest.URL?.absoluteString {
            print("Request: \(url)")
        }
        
        print("Method: \(newRequest.HTTPMethod)")
        
        if let headers = newRequest.allHTTPHeaderFields {
            print("Headers: [")
            for (key, value) in headers {
                print("  \(key) : \(value)")
            }
            print("]")
        }
    }
    
    public override func stopLoading() {
        connection?.cancel()
        connection = nil
    }
}
