// Copyright (c) 2015 Rocket Town Ltd
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

let TimberjackRequestHandledKey = "Timberjack"
let TimberjackRequestTimeKey = "TimberjackRequestTime"

public enum Style {
    case Verbose
    case Light
}

public typealias TimberjackPrint = ((String) -> Void)

public class Timberjack: NSURLProtocol {
    var connection: NSURLConnection?
    var data: NSMutableData?
    var response: NSURLResponse?
    var newRequest: NSMutableURLRequest?

    public enum FilterListMode {
        case Black
        case White
    }

    public static var printLog: TimberjackPrint = { log in
      print(log)
    }
    public static var logStyle: Style = .Verbose
    public static var filteredMode: FilterListMode = .Black
    public static var whiteListUrl: [NSURL]?
    public static var blackListUrl: [NSURL]?

    public class func register() {
        NSURLProtocol.registerClass(self)
    }
    
    public class func unregister() {
        NSURLProtocol.unregisterClass(self)
    }
    
    public class func defaultSessionConfiguration() -> NSURLSessionConfiguration {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.protocolClasses?.insert(Timberjack.self, atIndex: 0)
        return config
    }
    
    //MARK: - NSURLProtocol
    
    public override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        guard self.propertyForKey(TimberjackRequestHandledKey, inRequest: request) == nil else {
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
        guard let req = request.mutableCopy() as? NSMutableURLRequest where newRequest == nil else { return }
        
        self.newRequest = req
        
        Timberjack.setProperty(true, forKey: TimberjackRequestHandledKey, inRequest: newRequest!)
        Timberjack.setProperty(NSDate(), forKey: TimberjackRequestTimeKey, inRequest: newRequest!)
        
        connection = NSURLConnection(request: newRequest!, delegate: self)
        
        logRequest(newRequest!)
    }
    
    public override func stopLoading() {
        connection?.cancel()
        connection = nil
    }
    
    // MARK: NSURLConnectionDelegate
    
    func connection(connection: NSURLConnection!, didReceiveResponse response: NSURLResponse!) {
        let policy = NSURLCacheStoragePolicy(rawValue: request.cachePolicy.rawValue) ?? .NotAllowed
        client?.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: policy)
        
        self.response = response
        self.data = NSMutableData()
    }
    
    func connection(connection: NSURLConnection!, didReceiveData data: NSData!) {
        client?.URLProtocol(self, didLoadData: data)
        self.data?.appendData(data)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection!) {
        client?.URLProtocolDidFinishLoading(self)
        
        if let response = response {
            logResponse(response, data: data)
        }
    }
    
    func connection(connection: NSURLConnection!, didFailWithError error: NSError!) {
        client?.URLProtocol(self, didFailWithError: error)
        logError(error)
    }
    
    //MARK: - Logging
    
    public func logDivider() {
      Timberjack.printLog("---------------------")
    }
    
    public func logError(error: NSError) {
        logDivider()
        
        Timberjack.printLog("Error: \(error.localizedDescription)")
        
        if Timberjack.logStyle == .Verbose {
            if let reason = error.localizedFailureReason {
                Timberjack.printLog("Reason: \(reason)")
            }
            
            if let suggestion = error.localizedRecoverySuggestion {
                Timberjack.printLog("Suggestion: \(suggestion)")
            }
        }
    }
    
    public func logRequest(request: NSURLRequest) {
        if !shouldLog(request.URL) {
            return
        }

        logDivider()
        
        if let url = request.URL?.absoluteString {
            Timberjack.printLog("Request: \(request.HTTPMethod!) \(url)")
        }
        
        if Timberjack.logStyle == .Verbose {
            if let headers = request.allHTTPHeaderFields {
                self.logHeaders(headers)
            }
        }
    }
    
    public func logResponse(response: NSURLResponse, data: NSData? = nil) {
        if !shouldLog(response.URL) {
            return
        }

        logDivider()
        
        if let url = response.URL?.absoluteString {
            Timberjack.printLog("Response: \(url)")
        }
        
        if let httpResponse = response as? NSHTTPURLResponse {
            let localisedStatus = NSHTTPURLResponse.localizedStringForStatusCode(httpResponse.statusCode).capitalizedString
            Timberjack.printLog("Status: \(httpResponse.statusCode) - \(localisedStatus)")
        }
        
        if Timberjack.logStyle == .Verbose {
            if let headers = (response as? NSHTTPURLResponse)?.allHeaderFields as? [String: AnyObject] {
                self.logHeaders(headers)
            }
            
            if let startDate = Timberjack.propertyForKey(TimberjackRequestTimeKey, inRequest: newRequest!) as? NSDate {
                let difference = fabs(startDate.timeIntervalSinceNow)
                Timberjack.printLog("Duration: \(difference)s")
            }
            
            guard let data = data else { return }
            
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)
                let pretty = try NSJSONSerialization.dataWithJSONObject(json, options: .PrettyPrinted)
                
                if let string = NSString(data: pretty, encoding: NSUTF8StringEncoding) {
                    Timberjack.printLog("JSON: \(string)")
                }
            }
                
            catch {
                if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    Timberjack.printLog("Data: \(string)")
                }
            }
        }
    }
    
    public func logHeaders(headers: [String: AnyObject]) {
        Timberjack.printLog("Headers: [")
        for (key, value) in headers {
            Timberjack.printLog("  \(key) : \(value)")
        }
        Timberjack.printLog("]")
    }

    func shouldLog(url: NSURL?) -> Bool {
      let filteredList = Timberjack.filteredMode == .Black ? Timberjack.blackListUrl : Timberjack.whiteListUrl

        switch (Timberjack.filteredMode, url, filteredList) {
        case (.Black, let url?, let list?):
            return !list.contains(url)
        case (.Black, _, _):
            return true
        case (.White, let url?, let list?):
            return list.contains(url)
        case (.White, _, _):
            return false
        }
    }
}

extension String {
  func contains(aString: String) -> Bool {
    return self.rangeOfString(aString) != nil
  }
}

extension NSURL {
  func contains(url: NSURL) -> Bool {
    return self.absoluteString.contains(url.absoluteString)
  }
}

extension SequenceType where Generator.Element == NSURL {
  func contains(element: NSURL) -> Bool {
    return self.reduce(false) { return $0 || element.contains($1) }
  }
}
