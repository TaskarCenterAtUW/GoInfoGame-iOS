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
    var mockLocationTracker: MockLocationTracker!
    
    override func setUp() {
        super.setUp()
        mockAPI = MockWorkspaceAPI()
        mockLocationTracker = MockLocationTracker()
        viewModel = WorkspacesViewModel(api: mockAPI, locationTracker: mockLocationTracker)
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
        XCTAssertFalse(mockLocationTracker.didStartTracking)
    }
     
    func test_enableLocationTracking_updatesLocation() throws {
        // Act
        viewModel.enableLocationTracking()
        
        // Assert
        XCTAssertNotNil(mockLocationTracker.locationUpdateHandler, "Expected locationUpdateHandler to be assigned")
    }
  
    func test_fetchWorkspacesCalled_WhenLocationUpdateHandlerIsNotNil() throws {
        // Act
        viewModel.enableLocationTracking()
        
        // Simulate location update
        let mockLocation = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        mockLocationTracker.locationUpdateHandler?(mockLocation)
        
        // Assert
        XCTAssertTrue(mockAPI.didCallFetchWorkspaces, "Expected fetchWorkspaces to be called when locationUpdateHandler is not nil")
    }
    
    func test_fetchWorkspacesNotCalled_WhenLocationUpdateHandlerIsNil() throws {
        
        // Arrange
        mockLocationTracker.locationUpdateHandler = nil
        
        // Act
        viewModel.enableLocationTracking()
        
        
        // Assert
        XCTAssertFalse(mockAPI.didCallFetchWorkspaces, "Expected fetchWorkspaces to not be called when locationUpdateHandler is nil")
        
    }
        
    func test_disableLocationTracking_stopsUpdatingLocation() throws {
        // Act
        viewModel.disableLocationTracking()
        
        // Assert
        XCTAssertTrue(mockLocationTracker.didStopTracking, "Expected didStopTracking to be true after disabling location tracking")
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
            XCTAssertEqual(self.viewModel.workspaces.count, 1)
                  expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_stateSetToError_AfterFailedFetch() throws {
        // Arrange
        mockAPI.shouldSucceed = false
        
        let expectation = XCTestExpectation(description: "Wait for API completion")
        
        // Act
        viewModel.fetchWorkspacesList()
        DispatchQueue.main.async {
            XCTAssertEqual(self.viewModel.state, .error("Not found could not be found."), "Expected state to be .error after failed API call")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

        
        

}
    
