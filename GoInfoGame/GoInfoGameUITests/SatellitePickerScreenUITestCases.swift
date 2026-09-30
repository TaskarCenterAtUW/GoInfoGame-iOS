//
//  SatellitePickerScreenUITestCases.swift
//  GoInfoGameUITests
//
//  SatellitePickerSheet (GoInfoGame/UI/Map/Satellite Server/SatellitePickerSheet.swift),
//  reached from Map's floating "layers" button (A11yID.Map.layersButton). A single List
//  of imagery options: "Default Imagery" (always present) plus any WMTS satellite
//  servers whose geographic extent covers the map's current center
//  (MapViewModel.updateOptions(for:)/sattiliteServersFor(point:)).
//
//  Network: not relevant to this screen (confirmed directly) - selecting a row is
//  entirely local/in-memory (CustomMap.swift's updateSatelliteOverlay(option:) builds a
//  new MLNRasterTileSource from data already fetched when the workspace loaded). Actual
//  tile requests happen asynchronously afterward, not gated by or awaited from this UI.
//
//  Fixture: mapWithQuestClusters (via WorkspaceDetailsWithQuests.json, which already
//  defines one world-spanning WMTS server - "Esri World Imagery (Clarity) Beta") gives
//  exactly 2 options for free. mapWithNoImageryOptions (via WorkspaceDetailsNoImagery
//  .json - identical except imageryListDef is null) gives the single-option control
//  case - workspacesSingleAutoRedirect can't be reused for this the way it is elsewhere
//  in this project: its own fixture (WorkspaceDetailsSingle.json) has
//  longFormQuestDef: null, which makes the app fall back to the Workspaces picker
//  screen instead of ever reaching Map (confirmed directly - see
//  WorkspacesScreenUITestCases' own test for that fallback).
//
//  Persistence: NONE - selectedOption is plain in-memory MapViewModel state with no
//  UserDefaults read/write anywhere near this code (confirmed directly) - every fresh
//  launch starts on "Default Imagery". Tested as the real, current behavior.
//
//  Dismissal: unlike every other sheet tested elsewhere in this project, this one has no
//  close button and explicitly allows swipe-to-dismiss (MapView.swift's own .sheet has
//  no .interactiveDismissDisabled(), and sets .presentationDragIndicator(.visible)) -
//  its own dedicated test below.
//

import XCTest

final class SatellitePickerScreenUITestCases: ScreenshotOnFailureUITestCase {

    // MARK: - Helpers

    @discardableResult
    private func reachMapScreen(scenario: String, file: StaticString = #filePath, line: UInt = #line) -> XCUIApplication {
        let app = launchApp(scenario: scenario)
        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 30),
                      "Did not reach the Map screen via the Workspaces auto-redirect flow", file: file, line: line)
        return app
    }

    /// layersButton is a floating button directly on the map canvas (A11yID.Map's own
    /// "Floating buttons" grouping), not a toolbar item - never subject to iOS 26's
    /// toolbar-overflow collapse the way accessibilityModeButton/manageQuestsButton are.
    @discardableResult
    private func openSatellitePicker(_ app: XCUIApplication, timeout: TimeInterval = 30) -> Bool {
        let entryButton = element(app, id: A11yID.Map.layersButton)
        guard entryButton.waitForExistence(timeout: timeout) else { return false }
        entryButton.tap()
        return element(app, id: A11yID.Map.satellitePickerScrollView).waitForExistence(timeout: timeout)
    }

    private func scroll(in app: XCUIApplication) -> XCUIElement {
        element(app, id: A11yID.Map.satellitePickerScrollView)
    }

    /// Scrolls SatellitePickerSheet's own List to `element`. Mirrors every other
    /// suite's own copy of this helper in this project.
    @discardableResult
    private func scrollListToElement(_ element: XCUIElement, in scrollView: XCUIElement,
                                     maxSwipes: Int = 16, requireFullyOnScreen: Bool = false) -> Bool {
        let app = XCUIApplication()
        let window = app.windows.firstMatch.frame
        let listFrame = scrollView.frame
        let x: CGFloat = listFrame.minX + 8
        let topY = listFrame.minY + 24
        let bottomY = listFrame.maxY - 24
        func satisfied() -> Bool {
            guard element.isHittable else { return false }
            guard requireFullyOnScreen else { return true }
            return window.contains(element.frame)
        }
        var swipes = 0
        while !satisfied() && swipes < maxSwipes {
            let down = !(element.exists && element.frame.midY < window.midY)
            let big = !(element.exists && element.isHittable)
            let (fromY, toY): (CGFloat, CGFloat)
            if big {
                (fromY, toY) = down ? (bottomY, topY) : (topY, bottomY)
            } else {
                let nudge: CGFloat = 60
                let midY = (topY + bottomY) / 2
                (fromY, toY) = down ? (midY + nudge, midY - nudge)
                                    : (midY - nudge, midY + nudge)
            }
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: fromY))
            let end = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: toY))
            start.press(forDuration: 0.05, thenDragTo: end)
            swipes += 1
        }
        return element.exists && satisfied()
    }

    // MARK: - Options, selection

    func testSatellitePickerShowsAvailableOptions() throws {
        let app = reachMapScreen(scenario: UITestScenario.mapWithQuestClusters)
        XCTAssertTrue(openSatellitePicker(app), "Satellite picker did not open")
        let scrollView = scroll(in: app)

        let defaultRow = element(app, id: A11yID.Map.satelliteOptionRow(id: "none"))
        XCTAssertTrue(scrollListToElement(defaultRow, in: scrollView), "Default Imagery row not reachable")
        XCTAssertTrue(defaultRow.isSelected, "Default Imagery is not selected by default")

        let esriRow = element(app, id: A11yID.Map.satelliteOptionRow(id: "EsriWorldImageryClarity"))
        XCTAssertTrue(scrollListToElement(esriRow, in: scrollView), "Esri WMTS row not reachable")
        XCTAssertFalse(esriRow.isSelected, "Esri WMTS option is selected despite Default Imagery being the default")
    }

    func testSelectingOptionUpdatesCheckmarkAndClosesSheet() throws {
        let app = reachMapScreen(scenario: UITestScenario.mapWithQuestClusters)
        XCTAssertTrue(openSatellitePicker(app), "Satellite picker did not open")
        let scrollView = scroll(in: app)

        let esriRow = element(app, id: A11yID.Map.satelliteOptionRow(id: "EsriWorldImageryClarity"))
        XCTAssertTrue(scrollListToElement(esriRow, in: scrollView), "Esri WMTS row not reachable")
        esriRow.tap()

        XCTAssertTrue(element(app, id: A11yID.Map.satellitePickerScrollView).waitForNonExistence(timeout: 10),
                      "Satellite picker did not close after selecting an option")

        XCTAssertTrue(openSatellitePicker(app), "Satellite picker did not reopen")
        let scrollView2 = scroll(in: app)
        let esriRow2 = element(app, id: A11yID.Map.satelliteOptionRow(id: "EsriWorldImageryClarity"))
        XCTAssertTrue(scrollListToElement(esriRow2, in: scrollView2), "Esri WMTS row not reachable after reopening")
        XCTAssertTrue(esriRow2.isSelected, "Esri WMTS option is not selected after choosing it")

        let defaultRow2 = element(app, id: A11yID.Map.satelliteOptionRow(id: "none"))
        XCTAssertTrue(scrollListToElement(defaultRow2, in: scrollView2), "Default Imagery row not reachable after reopening")
        XCTAssertFalse(defaultRow2.isSelected, "Default Imagery is still selected after choosing a different option")
    }

    /// No close button on this sheet - swipe-to-dismiss is explicitly allowed instead
    /// (see this file's own header comment). Dismissing this way must not change the
    /// selection, unlike tapping a row.
    func testSwipeToDismissClosesWithoutChangingSelection() throws {
        let app = reachMapScreen(scenario: UITestScenario.mapWithQuestClusters)
        XCTAssertTrue(openSatellitePicker(app), "Satellite picker did not open")
        let scrollView = scroll(in: app)

        scrollView.swipeDown()
        XCTAssertTrue(element(app, id: A11yID.Map.satellitePickerScrollView).waitForNonExistence(timeout: 10),
                      "Satellite picker did not close after swiping down")

        XCTAssertTrue(openSatellitePicker(app), "Satellite picker did not reopen")
        let scrollView2 = scroll(in: app)
        let defaultRow = element(app, id: A11yID.Map.satelliteOptionRow(id: "none"))
        XCTAssertTrue(scrollListToElement(defaultRow, in: scrollView2), "Default Imagery row not reachable")
        XCTAssertTrue(defaultRow.isSelected, "Selection changed despite dismissing by swipe, not by picking a row")
    }

    /// WorkspaceDetailsNoImagery.json has imageryListDef: null, so updateOptions(for:)
    /// has nothing to geo-fence in - only the always-present "Default Imagery" option
    /// should show.
    func testSingleOptionCaseShowsOnlyDefaultImagery() throws {
        let app = reachMapScreen(scenario: UITestScenario.mapWithNoImageryOptions)
        XCTAssertTrue(openSatellitePicker(app), "Satellite picker did not open")

        XCTAssertTrue(element(app, id: A11yID.Map.satelliteOptionRow(id: "none")).waitForExistence(timeout: 10),
                      "Default Imagery row not shown")
        XCTAssertFalse(element(app, id: A11yID.Map.satelliteOptionRow(id: "EsriWorldImageryClarity")).exists,
                       "A WMTS option is shown despite the workspace defining no imagery list")
    }

    // MARK: - Layout: overlap, screen bounds, reachability

    func testSatellitePickerElementsDoNotOverlap() throws {
        let app = reachMapScreen(scenario: UITestScenario.mapWithQuestClusters)
        XCTAssertTrue(openSatellitePicker(app), "Satellite picker did not open")
        let scrollView = scroll(in: app)

        let defaultRow = element(app, id: A11yID.Map.satelliteOptionRow(id: "none"))
        let esriRow = element(app, id: A11yID.Map.satelliteOptionRow(id: "EsriWorldImageryClarity"))
        XCTAssertTrue(scrollListToElement(esriRow, in: scrollView), "Rows not reachable")
        assertNoOverlap([(defaultRow, "Default Imagery row"), (esriRow, "Esri WMTS row")])
    }

    func testSatellitePickerElementsFitWithinScreenBounds() throws {
        let app = reachMapScreen(scenario: UITestScenario.mapWithQuestClusters)
        XCTAssertTrue(openSatellitePicker(app), "Satellite picker did not open")
        let scrollView = scroll(in: app)
        let window = app.windows.firstMatch

        for (name, control) in [
            ("Default Imagery row", element(app, id: A11yID.Map.satelliteOptionRow(id: "none"))),
            ("Esri WMTS row", element(app, id: A11yID.Map.satelliteOptionRow(id: "EsriWorldImageryClarity"))),
        ] {
            XCTAssertTrue(scrollListToElement(control, in: scrollView, requireFullyOnScreen: true), "\(name) not reachable by scrolling")
            XCTAssertGreaterThanOrEqual(control.frame.minX, window.frame.minX, "\(name) extends past the left edge of the screen")
            XCTAssertLessThanOrEqual(control.frame.maxX, window.frame.maxX, "\(name) extends past the right edge of the screen")
            XCTAssertGreaterThanOrEqual(control.frame.minY, window.frame.minY, "\(name) extends past the top edge of the screen")
            XCTAssertLessThanOrEqual(control.frame.maxY, window.frame.maxY, "\(name) extends past the bottom edge of the screen")
        }
    }

    func testAllSatellitePickerElementsReachableAndTappable() throws {
        let app = reachMapScreen(scenario: UITestScenario.mapWithQuestClusters)
        XCTAssertTrue(openSatellitePicker(app), "Satellite picker did not open")
        let scrollView = scroll(in: app)

        for (name, control) in [
            ("Default Imagery row", element(app, id: A11yID.Map.satelliteOptionRow(id: "none"))),
            ("Esri WMTS row", element(app, id: A11yID.Map.satelliteOptionRow(id: "EsriWorldImageryClarity"))),
        ] {
            XCTAssertTrue(scrollListToElement(control, in: scrollView), "\(name) not reachable by scrolling")
            XCTAssertTrue(control.isHittable, "\(name) exists but is not tappable")
        }
    }
}
