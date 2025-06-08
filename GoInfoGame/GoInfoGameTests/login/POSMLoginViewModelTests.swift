//
//  POSMLoginViewModelTests.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 27/05/25.
//

import XCTest
@testable import GoInfoGame

final class POSMLoginViewModelTests: XCTestCase {
    
    var viewModel: PosmLoginViewModel!
    let mockEnv: AppEnv = .staging
    
    override func setUpWithError() throws {
        viewModel = PosmLoginViewModel()
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
    }
    
    func testInitialState() throws {
        XCTAssertEqual(viewModel.username, "")
        XCTAssertEqual(viewModel.password, "")
        XCTAssertEqual(viewModel.state, .idle)
    }
    
    func testPerformLoginWithEmptyCredentials() throws {
        viewModel.performLogin(with: mockEnv)
        XCTAssertEqual(viewModel.state, .error("Username and Password cannot be empty."))
    }
    
    func testPerformLoginWithValidCredentials() throws {
        viewModel.username = "rajeshk@gaussiansolutions.com"
        viewModel.password = "Rajesh1234@"
        
        let expectation = self.expectation(description: "Login Success")
        
        viewModel.performLogin(with: mockEnv)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertEqual(self.viewModel.state, .loaded(.login))
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }



        

}





