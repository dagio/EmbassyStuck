//
//  EmbassyStuckUITests.swift
//  EmbassyStuckUITests
//
//  Created by Damien Gavard on 13/04/2017.
//  Copyright © 2017 Damien Gavard. All rights reserved.
//

import XCTest

class EmbassyStuckUITests: XCTestCase {

    var app: XCUIApplication!
    var webServer: FixturesWebServer!
        
    override func setUp() {
        super.setUp()

        app = XCUIApplication()

        webServer = FixturesWebServer()
        webServer.start()
    }

    override func tearDown() {
        super.tearDown()

        webServer.stop()
    }
    
    func testExample() {
        app.launch()

        XCTAssertTrue(app.staticTexts["Hello World"].exists)

        app.terminate()
    }
    
}
