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
    case verbose
    case light
}

open class Timberjack: URLProtocol {
    var connection: NSURLConnection?
    var data: NSMutableData?
    var response: URLResponse?
    var newRequest: NSMutableURLRequest?
    
    open static var logStyle: Style = .verbose
    
    open class func register() {
        URLProtocol.registerClass(self)
    }
    
    open class func unregister() {
        URLProtocol.unregisterClass(self)
    }
    
    open class func defaultSessionConfiguration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.protocolClasses?.insert(Timberjack.self, at: 0)
        return config
    }
    
    //MARK: - NSURLProtocol
    
    open override class func canInit(with request: URLRequest) -> Bool {
        guard self.property(forKey: TimberjackRequestHandledKey, in: request) == nil else {
            return false
        }
        
        return true
    }
    
    open override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    open override class func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool {
        return super.requestIsCacheEquivalent(a, to: b)
    }

    open override func startLoading() {
        guard let req = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest, newRequest == nil else { return }
        
        self.newRequest = req
        
        Timberjack.setProperty(true, forKey: TimberjackRequestHandledKey, in: newRequest!)
        Timberjack.setProperty(Date(), forKey: TimberjackRequestTimeKey, in: newRequest!)
        
        connection = NSURLConnection(request: newRequest! as URLRequest, delegate: self)
        
        logRequest(newRequest! as URLRequest)
    }
    
    open override func stopLoading() {
        connection?.cancel()
        connection = nil
    }
    
    // MARK: NSURLConnectionDelegate
    
    func connection(_ connection: NSURLConnection!, didReceiveResponse response: URLResponse!) {
        let policy = URLCache.StoragePolicy(rawValue: request.cachePolicy.rawValue) ?? .notAllowed
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: policy)
        
        self.response = response
        self.data = NSMutableData()
    }
    
    func connection(_ connection: NSURLConnection!, didReceiveData data: Data!) {
        client?.urlProtocol(self, didLoad: data)
        self.data?.append(data)
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection!) {
        client?.urlProtocolDidFinishLoading(self)
        
        if let response = response {
            logResponse(response, data: data as Data?)
        }
    }
    
    func connection(_ connection: NSURLConnection!, didFailWithError error: NSError!) {
        client?.urlProtocol(self, didFailWithError: error)
        logError(error)
    }
    
    //MARK: - Logging
    
    open func logDivider() {
        print("---------------------")
    }
    
    open func logError(_ error: NSError) {
        logDivider()
        
        print("Error: \(error.localizedDescription)")
        
        if Timberjack.logStyle == .verbose {
            if let reason = error.localizedFailureReason {
                print("Reason: \(reason)")
            }
            
            if let suggestion = error.localizedRecoverySuggestion {
                print("Suggestion: \(suggestion)")
            }
        }
    }
    
    open func logRequest(_ request: URLRequest) {
        logDivider()
        
        if let url = request.url?.absoluteString {
            print("Request: \(request.httpMethod!) \(url)")
        }
        
        if Timberjack.logStyle == .verbose {
            if let headers = request.allHTTPHeaderFields {
                self.logHeaders(headers as [String : AnyObject])
            }
        }
    }
    
    open func logResponse(_ response: URLResponse, data: Data? = nil) {
        logDivider()
        
        if let url = response.url?.absoluteString {
            print("Response: \(url)")
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            let localisedStatus = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode).capitalized
            print("Status: \(httpResponse.statusCode) - \(localisedStatus)")
        }
        
        if Timberjack.logStyle == .verbose {
            if let headers = (response as? HTTPURLResponse)?.allHeaderFields as? [String: AnyObject] {
                self.logHeaders(headers)
            }
            
            if let startDate = Timberjack.property(forKey: TimberjackRequestTimeKey, in: newRequest! as URLRequest) as? Date {
                let difference = fabs(startDate.timeIntervalSinceNow)
                print("Duration: \(difference)s")
            }
            
            guard let data = data else { return }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                let pretty = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                
                if let string = NSString(data: pretty, encoding: String.Encoding.utf8.rawValue) {
                    print("JSON: \(string)")
                }
            }
                
            catch {
                if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                    print("Data: \(string)")
                }
            }
        }
    }
    
    open func logHeaders(_ headers: [String: AnyObject]) {
        print("Headers: [")
        for (key, value) in headers {
            print("  \(key) : \(value)")
        }
        print("]")
    }
}
