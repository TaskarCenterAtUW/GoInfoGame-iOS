//
//  WorkspacesViewModelTests.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 27/05/25.
//


import XCTest
@testable import GoInfoGame
import CoreLocation

final class WorkspacesViewModelTests: XCTestCase {
    
    var viewModel: WorkspacesViewModel!
    var mockAPI: MockWorkspaceAPI!
    var mockLocationService: MockLocationService!
    
    override func setUp() {
        super.setUp()
        mockAPI = MockWorkspaceAPI()
        mockLocationService = MockLocationService()
        viewModel = WorkspacesViewModel(api: mockAPI, locationService: mockLocationService)
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        try super.tearDownWithError()
    }
    
    func testInitialState() throws {
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertTrue(viewModel.workspaces.isEmpty)
    }
    
    func test_enableLocationTracking_doesNotTriggerLocation_whenInPreviewMode() throws {
       
        //Arrange
        viewModel.isPreview = true
        
        //
        viewModel.enableLocationTracking()

        // Assert
        XCTAssertFalse(mockLocationService.didRequestAuthorization)
        XCTAssertFalse(mockLocationService.didStartUpdatingLocation)
        
    }
    
    func test_enableLocationTracking_requestsAuthorizationAndStartsUpdatingLocation() throws {
        // Act
        viewModel.enableLocationTracking()
        
        // Assert
        XCTAssertTrue(mockLocationService.didRequestAuthorization)
        XCTAssertTrue(mockLocationService.didStartUpdatingLocation)
        
    }
    
    func test_enableLocationTracking_updatesLocation() throws {
        // Act
        viewModel.enableLocationTracking()
        
        // Assert
        XCTAssertNotNil(mockLocationService.locationUpdateHandler, "Expected locationUpdateHandler to be assigned")
    }
    
    func test_fetchWorkspacesCalled_WhenLocationUpdateHandlerIsNotNil() throws {
        // Act
        viewModel.enableLocationTracking()
        
        // Simulate location update
        let mockLocation = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        mockLocationService.locationUpdateHandler?(mockLocation)
        
        // Assert
        XCTAssertTrue(mockAPI.didCallFetchWorkspaces)
    }
    
    func test_fetchWorkspacesNotCalled_WhenLocationUpdateHandlerIsNil() throws {
        
        // Arrange
        mockLocationService.locationUpdateHandler = nil
        
        // Act
        viewModel.enableLocationTracking()
        
        
        // Assert
        XCTAssertFalse(mockAPI.didCallFetchWorkspaces, "Expected fetchWorkspaces to not be called when locationUpdateHandler is nil")
        
    }
        
    func test_disableLocationTracking_stopsUpdatingLocation() throws {
        // Act
        viewModel.disableLocationTracking()
        
        // Assert
        XCTAssertTrue(mockLocationService.didStopUpdatingLocation)
    }
    
    func test_fetchWorkspaces_SetStateToLoading() throws {
        viewModel.fetchWorkspacesList()
        
        XCTAssertEqual(viewModel.state, .loading)
    }
    
    func test_stateSetToLoaded_AfterSuccessfulFetch() throws {
        
        // Arrange
        let sampleWorkspace = Workspace(
            id: 1,
            title: "Test Workspace",
            externalAppAccess: 1
        )
        
        mockAPI.returnedWorkspaces = [sampleWorkspace]
    
        let expectation = XCTestExpectation(description: "Wait for API completion")
        
        //Act
        viewModel.fetchWorkspacesList()
        
        DispatchQueue.main.async {
            XCTAssertEqual(self.viewModel.state, .loaded, "Expected state to be .loaded after successful API call")
            XCTAssertEqual(self.viewModel.workspaces.count, 3)
                  expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
        
        

}
    
