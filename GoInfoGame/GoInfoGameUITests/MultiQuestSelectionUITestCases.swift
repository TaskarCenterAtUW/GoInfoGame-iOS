//
//  MultiQuestSelectionUITestCases.swift
//  GoInfoGameUITests
//
//  MultiQuestSelectionBottomSheet (GoInfoGame/UI/Map/MapView.swift), entered by a
//  long-press directly on an existing quest annotation (CustomMap.swift's
//  handleLongPress, within 30pt of a non-cluster pin) - there is no separate mode-toggle
//  control anywhere in the UI. A SINGLE long-pressed pin is enough to open the sheet
//  (selectedCount starts at 1); further long-presses on OTHER pins of the SAME element
//  type add them to the batch, and long-pressing an already-selected pin again removes
//  it.
//
//  "Answer Quests" opens ONE LongForm for the first-selected element, but submitting
//  applies that SAME answer to EVERY selected element at once
//  (MapViewModel.getSelectedQuest()'s own multi-select branch, which loops
//  self.selectedAnnotaions and calls onAnswer(answer:) on each) - a genuine bulk-answer
//  feature, not just a UI convenience for picking one pin among several.
//
//  Fixture: accessibilityModeOnline's own AccessibilityModeOSMElements.json has 7 blank
//  Sidewalks-typed elements (700001-700007) - this suite uses two of them (700001,
//  700002). Both being EQUALLY blank (not one of this project's richer, partially
//  prefilled fixtures) matters for testAnsweringABatchAppliesTheSameAnswerToBothElements
//  specifically: selectedAnnotaions is a Set, so which of the two elements' tags the
//  opened form actually shows is not deterministic - using two identically-blank
//  elements means the same fill sequence completes the form regardless of which one
//  gets shown.
//
//  Zoom: CustomMap.swift folds nearby quests into one cluster bubble (own custom
//  screen-space grouping, not MapLibre's native clustering) whenever the map is below
//  zoom 17 - the fixed UI-test camera opens at zoom 15. 700001 and 700002 sit ~99m
//  apart, well inside that density-cluster radius, so at the default zoom they render
//  as ONE cluster pin with no per-element accessibility value at all, not two
//  individual questAnnotation buttons. zoomToIndividualPins() taps the zoom-in button a
//  few times to cross into the next bucket (>=17), where only screen-overlapping pins
//  get merged - 99m apart no longer overlaps at that zoom, so both render individually.
//

import XCTest

final class MultiQuestSelectionUITestCases: ScreenshotOnFailureUITestCase {

    // MARK: - Helpers

    @discardableResult
    private func reachMapScreen(scenario: String, file: StaticString = #filePath, line: UInt = #line) -> XCUIApplication {
        let app = launchApp(scenario: scenario)
        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 30),
                      "Did not reach the Map screen via the Workspaces auto-redirect flow", file: file, line: line)
        return app
    }

    private func waitUntil(timeout: TimeInterval, condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if condition() { return true }
            usleep(300_000)
        } while Date() < deadline
        return condition()
    }

    private func findQuestAnnotation(_ app: XCUIApplication, elementID: Int64) -> XCUIElement? {
        app.buttons.matching(identifier: A11yID.Map.questAnnotation)
            .allElementsBoundByIndex.first(where: { $0.value as? String == "\(elementID)" })
    }

    @discardableResult
    private func longPressAnnotation(_ app: XCUIApplication, elementID: Int64, timeout: TimeInterval = 40) -> Bool {
        guard waitUntil(timeout: timeout, condition: { findQuestAnnotation(app, elementID: elementID) != nil }),
              let pin = findQuestAnnotation(app, elementID: elementID) else { return false }
        pin.press(forDuration: 0.6)
        return true
    }

    /// Crosses from CustomMap's density-cluster zoom bucket (<17, the default UI-test
    /// camera's zoom 15) into the overlap bucket (>=17), where 700001/700002's ~99m
    /// separation no longer counts as overlapping - see this file's header comment.
    /// Exactly 2 taps (15 -> 17): going further shrinks the visible map area enough
    /// that 700002 (90m E of the fixed camera) can fall outside the viewport, since
    /// zooming in narrows the shown area around the same fixed center rather than
    /// panning toward either pin - confirmed empirically (3 taps reliably lost 700002).
    /// Must be called before the first longPressAnnotation() in every test.
    private func zoomToIndividualPins(_ app: XCUIApplication) {
        let zoomIn = element(app, id: A11yID.Map.zoomInButton)
        for _ in 0..<2 { zoomIn.tap() }
        // Clustering re-runs after a short debounce plus each zoom's own animated
        // camera move - same settle time as this project's other zoom-then-long-press
        // tests (see MapScreenUITestCases.testLongPressingEmptyMapAreaShowsPinChoiceCard).
        sleep(2)
    }

    private func scroll(in app: XCUIApplication) -> XCUIElement {
        element(app, id: A11yID.LongForm.scrollView)
    }

    /// Mirrors LongFormScreenUITestCases' own copy of this helper (not visible across
    /// files) - LongForm's choice grids wrap their own nested ScrollView inside this
    /// screen's outer List, so a swipe confined to the row's left margin is needed to
    /// reliably reach the outer List instead of being captured by an inner one.
    @discardableResult
    private func scrollFormToElement(_ element: XCUIElement, in scrollView: XCUIElement,
                                     maxSwipes: Int = 16, requireFullyOnScreen: Bool = false) -> Bool {
        let app = XCUIApplication()
        let window = app.windows.firstMatch.frame
        let x: CGFloat = 15
        let topY = window.minY + 24
        let bottomY = window.maxY - 24
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
                // A full top-to-bottom swipe can jump a whole screen's worth of content
                // in one go - easily skipping clean over a short question sandwiched
                // between two taller ones (e.g. 101 between 106 and 104) before it's ever
                // instantiated in this lazy CollectionView, after which the "scroll
                // further down" heuristic can't recover since it never reverses
                // direction. A half-span swipe still covers ground faster than the
                // small nudge below, with much less overshoot risk.
                let half = (bottomY - topY) / 4
                (fromY, toY) = down ? (window.midY + half, window.midY - half)
                                    : (window.midY - half, window.midY + half)
            } else {
                let nudge: CGFloat = 60
                (fromY, toY) = down ? (window.midY + nudge, window.midY - nudge)
                                    : (window.midY - nudge, window.midY + nudge)
            }
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: fromY))
            let end = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: toY))
            start.press(forDuration: 0.05, thenDragTo: end)
            swipes += 1
        }
        return element.exists && satisfied()
    }

    private func dismissKeyboardIfShown(_ app: XCUIApplication) {
        let done = app.toolbars.buttons["Done"]
        if done.exists {
            done.tap()
            return
        }
        guard app.keyboards.count > 0 else { return }
        let list = scroll(in: app)
        let y = list.frame.minY + 24
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: 15, dy: y))
            .tap()
    }

    // MARK: - Entering / building the selection

    func testLongPressingPinOpensMultiSelectSheetWithCountOne() throws {
        let app = reachMapScreen(scenario: UITestScenario.accessibilityModeOnline)
        zoomToIndividualPins(app)
        XCTAssertTrue(longPressAnnotation(app, elementID: 700001), "Could not long-press element 700001")

        XCTAssertTrue(element(app, id: A11yID.Map.multiSelectSheet).waitForExistence(timeout: 10),
                      "Multi-select sheet did not appear")
        let countLabel = element(app, id: A11yID.Map.multiSelectCountLabel)
        XCTAssertTrue(countLabel.waitForExistence(timeout: 5), "Count label not shown")
        XCTAssertTrue(countLabel.label.hasPrefix("1 "), "Count label does not start at 1 - label: \(countLabel.label)")
    }

    func testLongPressingSecondPinOfSameTypeIncrementsCount() throws {
        let app = reachMapScreen(scenario: UITestScenario.accessibilityModeOnline)
        zoomToIndividualPins(app)
        XCTAssertTrue(longPressAnnotation(app, elementID: 700001), "Could not long-press element 700001")
        XCTAssertTrue(element(app, id: A11yID.Map.multiSelectSheet).waitForExistence(timeout: 10), "Multi-select sheet did not appear")

        XCTAssertTrue(longPressAnnotation(app, elementID: 700002), "Could not long-press element 700002")

        let countLabel = element(app, id: A11yID.Map.multiSelectCountLabel)
        XCTAssertTrue(waitUntil(timeout: 10, condition: { countLabel.label.hasPrefix("2 ") }),
                      "Count did not increment to 2 after long-pressing a second same-type pin - label: \(countLabel.label)")
    }

    func testLongPressingSameTypePinTwiceTogglesItOffAndClosesSheet() throws {
        let app = reachMapScreen(scenario: UITestScenario.accessibilityModeOnline)
        zoomToIndividualPins(app)
        XCTAssertTrue(longPressAnnotation(app, elementID: 700001), "Could not long-press element 700001")
        XCTAssertTrue(element(app, id: A11yID.Map.multiSelectSheet).waitForExistence(timeout: 10), "Multi-select sheet did not appear")

        XCTAssertTrue(longPressAnnotation(app, elementID: 700001), "Could not long-press element 700001 again")

        XCTAssertTrue(element(app, id: A11yID.Map.multiSelectSheet).waitForNonExistence(timeout: 10),
                      "Sheet still showing after toggling the only selected pin back off")
    }

    func testCancelClearsSelectionAndClosesSheet() throws {
        let app = reachMapScreen(scenario: UITestScenario.accessibilityModeOnline)
        zoomToIndividualPins(app)
        XCTAssertTrue(longPressAnnotation(app, elementID: 700001), "Could not long-press element 700001")
        XCTAssertTrue(element(app, id: A11yID.Map.multiSelectSheet).waitForExistence(timeout: 10), "Multi-select sheet did not appear")

        let cancelButton = element(app, id: A11yID.Map.multiSelectCancelButton)
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5), "Cancel button not shown")
        cancelButton.tap()

        XCTAssertTrue(element(app, id: A11yID.Map.multiSelectSheet).waitForNonExistence(timeout: 10),
                      "Multi-select sheet still showing after Cancel")
        // A fresh long-press on the same pin should start a brand new selection at 1,
        // not resume some stale state - proving Cancel genuinely cleared it.
        XCTAssertTrue(longPressAnnotation(app, elementID: 700001), "Could not long-press element 700001 after cancelling")
        let countLabel = element(app, id: A11yID.Map.multiSelectCountLabel)
        XCTAssertTrue(countLabel.waitForExistence(timeout: 5), "Count label not shown on the new selection")
        XCTAssertTrue(countLabel.label.hasPrefix("1 "), "New selection did not start at 1 - label: \(countLabel.label)")
    }

    // MARK: - Answering a batch

    /// The defining behavior of this feature: one LongForm submission applies to every
    /// selected element, not just the one the form happened to show. See this file's
    /// own header comment for why both elements here are equally blank.
    func testAnsweringABatchAppliesTheSameAnswerToBothElements() throws {
        let app = reachMapScreen(scenario: UITestScenario.accessibilityModeOnline)
        zoomToIndividualPins(app)
        XCTAssertTrue(longPressAnnotation(app, elementID: 700001), "Could not long-press element 700001")
        XCTAssertTrue(element(app, id: A11yID.Map.multiSelectSheet).waitForExistence(timeout: 10), "Multi-select sheet did not appear")
        XCTAssertTrue(longPressAnnotation(app, elementID: 700002), "Could not long-press element 700002")
        let countLabel = element(app, id: A11yID.Map.multiSelectCountLabel)
        XCTAssertTrue(waitUntil(timeout: 10, condition: { countLabel.label.hasPrefix("2 ") }), "Count did not reach 2")

        element(app, id: A11yID.Map.multiSelectAnswerQuestsButton).tap()

        XCTAssertTrue(element(app, id: A11yID.LongForm.dismissButton).waitForExistence(timeout: 15),
                      "LongForm did not open for the selected batch")
        let scrollView = scroll(in: app)

        // Fully answer every applicable Sidewalks question - both 700001 and 700002 are
        // equally blank, so this same sequence completes whichever one the form shows.
        // Order matches the form's actual top-to-bottom layout, per
        // WorkspaceDetailsWithQuests.json's own quest array order: 107, 106, 101, 103,
        // 104 (102/105 are the OTHER component type's own entry, not shown here) -
        // scrollFormToElement's "nonexistent element means scroll further down" heuristic
        // can't recover from jumping back UP to an earlier question once scrolled past it.
        let textEntry = element(app, id: A11yID.LongForm.textInput(questID: 107))
        XCTAssertTrue(scrollFormToElement(textEntry, in: scrollView), "Quest 107 text entry not reachable")
        textEntry.tap()
        textEntry.typeText("Batch answer test")
        dismissKeyboardIfShown(app)

        let choice1 = element(app, id: A11yID.LongForm.option(questID: 106, value: "choice_1"))
        XCTAssertTrue(scrollFormToElement(choice1, in: scrollView), "Quest 106 choice_1 not reachable")
        choice1.tap()

        let concrete = element(app, id: A11yID.LongForm.option(questID: 101, value: "concrete"))
        XCTAssertTrue(scrollFormToElement(concrete, in: scrollView), "Surface option not reachable")
        concrete.tap()

        let width = element(app, id: A11yID.LongForm.numericInput(questID: 103))
        XCTAssertTrue(scrollFormToElement(width, in: scrollView), "Width field not reachable")
        width.tap()
        width.typeText("40")
        dismissKeyboardIfShown(app)

        let obstructionNo = element(app, id: A11yID.LongForm.option(questID: 104, value: "no"))
        XCTAssertTrue(scrollFormToElement(obstructionNo, in: scrollView), "Obstruction option not reachable")
        obstructionNo.tap()

        let submit = element(app, id: A11yID.LongForm.submitButton)
        XCTAssertTrue(scrollFormToElement(submit, in: scrollView), "Submit button not reachable")
        XCTAssertTrue(submit.isEnabled, "Submit disabled despite every applicable question being answered")
        submit.tap()

        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 10),
                      "Map toolbar did not reappear after submitting")
        XCTAssertTrue(waitUntil(timeout: 30, condition: { findQuestAnnotation(app, elementID: 700001) == nil }),
                      "Element 700001's pin is still on the map after the batch submit")
        XCTAssertTrue(waitUntil(timeout: 5, condition: { findQuestAnnotation(app, elementID: 700002) == nil }),
                      "Element 700002's pin is still on the map after the batch submit - the bulk answer should have applied to it too")
    }

    // MARK: - Layout

    func testMultiSelectSheetLayout() throws {
        let app = reachMapScreen(scenario: UITestScenario.accessibilityModeOnline)
        zoomToIndividualPins(app)
        XCTAssertTrue(longPressAnnotation(app, elementID: 700001), "Could not long-press element 700001")
        XCTAssertTrue(element(app, id: A11yID.Map.multiSelectSheet).waitForExistence(timeout: 10), "Multi-select sheet did not appear")

        let countLabel = element(app, id: A11yID.Map.multiSelectCountLabel)
        let answerButton = element(app, id: A11yID.Map.multiSelectAnswerQuestsButton)
        let cancelButton = element(app, id: A11yID.Map.multiSelectCancelButton)

        let window = app.windows.firstMatch.frame
        for (name, control) in [("Count label", countLabel), ("Answer Quests button", answerButton), ("Cancel button", cancelButton)] {
            XCTAssertTrue(control.isHittable, "\(name) exists but is not tappable")
            XCTAssertTrue(window.contains(control.frame), "\(name) extends outside the screen bounds")
        }
        assertNoOverlap([(answerButton, "Answer Quests button"), (cancelButton, "Cancel button")])
    }
}
