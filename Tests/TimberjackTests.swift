//
//  TimberjackTests.swift
//  TimberjackTests
//
//  Created by Andy Smart on 04/09/2015.
//  Copyright (c) 2015 Rocket Town Ltd. All rights reserved.
//

import UIKit
import XCTest

@testable import Timberjack

class TimberjackTests: XCTestCase {

    private var buffer: [String] = []

    override func setUp() {
        buffer = []
        Timberjack.printLog = { log in
            self.buffer.append(log)
        }
    }

    func testLogDefaultBehavior() {
        // Given
        let urlRequested = NSURL(string: "http://www.example.com/sample")
        let request = NSURLRequest(URL: urlRequested!)

        // When
        let instance = Timberjack()
        instance.logRequest(request)

        // Then
        XCTAssert(buffer.count != 0)
    }
    
    func testLogDisableWithBlackList() {
        // Given
        let urlFiltered = NSURL(string: "http://www.example.com")
        let urlRequested = NSURL(string: "http://www.example.com/sample")
        Timberjack.filteredMode = .Black
        Timberjack.blackListUrl = [urlFiltered!]
        let request = NSURLRequest(URL: urlRequested!)

        // When
        let instance = Timberjack()
        instance.logRequest(request)

        // Then
        XCTAssert(buffer.count == 0)
    }
    
    func testLogEnableWithBlackList() {
        // Given
        let urlFiltered = NSURL(string: "http://www.example.com")
        let urlRequested = NSURL(string: "http://www.example2.com")
        Timberjack.filteredMode = .Black
        Timberjack.blackListUrl = [urlFiltered!]
        let request = NSURLRequest(URL: urlRequested!)

        // When
        let instance = Timberjack()
        instance.logRequest(request)

        // Then
        XCTAssert(buffer.count != 0)
    }
    
    func testLogEnableWithWhiteList() {
        // Given
        let urlFiltered = NSURL(string: "http://www.example.com")
        let urlRequested = NSURL(string: "http://www.example.com/sample")
        Timberjack.filteredMode = .White
        Timberjack.whiteListUrl = [urlFiltered!]
        let request = NSURLRequest(URL: urlRequested!)

        // When
        let instance = Timberjack()
        instance.logRequest(request)

        // Then
        XCTAssert(buffer.count != 0)
    }

    func testLogDisableWithWhiteList() {
        // Given
        let urlFiltered = NSURL(string: "http://www.example.com")
        let urlRequested = NSURL(string: "http://www.example2.com")
        Timberjack.filteredMode = .White
        Timberjack.whiteListUrl = [urlFiltered!]
        let request = NSURLRequest(URL: urlRequested!)

        // When
        let instance = Timberjack()
        instance.logRequest(request)

        // Then
        XCTAssert(buffer.count == 0)
    }
}
