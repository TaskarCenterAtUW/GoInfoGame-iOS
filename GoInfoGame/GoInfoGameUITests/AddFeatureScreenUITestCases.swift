//
//  AddFeatureScreenUITestCases.swift
//  GoInfoGameUITests
//
//  AddFeatureView/FeatureSubmissionView (GoInfoGame/UI/Map/AddFeatureView.swift), reached
//  by long-pressing an empty map area to open PinChoiceCard, then tapping "Add Feature"
//  (the sibling of "Create Note", covered in LongFormScreenUITestCases' own Compose Note
//  tests). Two sheets in sequence: AddFeatureView's preset grid (Bench, Power Pole - seeded
//  via WorkspaceDetailsWithQuests.json's own "feature-presets", added alongside its
//  existing quest definitions), then FeatureSubmissionView's note+photo form once a preset
//  is picked.
//
//  Submit has no disabled state - unlike LongForm, a feature's only required data is the
//  preset's own tags, so the note (and photo) are genuinely optional and Submit is always
//  enabled.
//
//  FeatureSubmissionManager persists the draft (Realm + disk) and fires the actual OSM
//  node-creation network calls from a detached Task *after* the sheet has already
//  dismissed - mirrors Create Note's own fire-and-forget shape. A successful creation
//  surfaces as "<preset> added successfully" on A11yID.Map.syncStatusAlert (reused, not a
//  dedicated identifier - see MapView.swift's own .featureSubmitted handling); a failed/
//  offline one is never surfaced directly (FeatureSubmissionManager's own doc comment: "A
//  failed attempt is never surfaced to the user") - instead it stays queued, reflected
//  only in A11yID.Map.syncButton's own accessibility value ("<N> pending").
//
//  Real camera capture (CameraView, backed by UIImagePickerController) is not something
//  this suite attempts - same reasoning as A11yID.Map.compassButton's own rotation
//  gesture - so photo coverage stops at "the Add Photo control exists and is tappable".
//

import XCTest

final class AddFeatureScreenUITestCases: ScreenshotOnFailureUITestCase {

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

    /// LongFormOSMElements.json's handful of elements sit ~350m+ apart (deliberately, so
    /// pins don't cluster - see that fixture's own header comment), so unlike
    /// MapScreenUITestCases' own dense real-world dataset, an empty corner is reliably
    /// available at the default zoom without needing to zoom in first.
    private func emptyMapPoint(_ app: XCUIApplication) -> CGPoint? {
        let window = app.windows.firstMatch
        let annotationFrames = app.buttons.matching(identifier: A11yID.Map.clusterAnnotation).allElementsBoundByIndex.map(\.frame)
            + app.buttons.matching(identifier: A11yID.Map.questAnnotation).allElementsBoundByIndex.map(\.frame)

        let margin: CGFloat = 60
        let candidates = [
            CGPoint(x: window.frame.minX + margin, y: window.frame.minY + 160),
            CGPoint(x: window.frame.maxX - margin, y: window.frame.minY + 160),
            CGPoint(x: window.frame.minX + margin, y: window.frame.maxY - 160),
            CGPoint(x: window.frame.maxX - margin, y: window.frame.maxY - 160)
        ]
        return candidates.first { point in
            !annotationFrames.contains { $0.insetBy(dx: -margin, dy: -margin).contains(point) }
        }
    }

    /// Mirrors MapScreenUITestCases' own copy of this helper (not visible across files) -
    /// CustomMap.swift's long-press gesture (a UILongPressGestureRecognizer, 0.5s minimum)
    /// is the only way to drop a pin; there is no separate single-tap path.
    private func longPress(_ app: XCUIApplication, at point: CGPoint, duration: TimeInterval = 0.6) {
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: point.x, dy: point.y))
            .press(forDuration: duration)
    }

    /// Long-presses an empty map area, waits for PinChoiceCard, and taps "Add Feature" -
    /// the entry point every test in this file needs. Skips (rather than fails) if no
    /// empty point is found, mirroring MapScreenUITestCases.
    /// testLongPressingEmptyMapAreaShowsPinChoiceCard's own reasoning: a specific point
    /// being empty isn't guaranteed on every run, and that absence is not itself this
    /// suite's concern.
    @discardableResult
    private func openAddFeatureGrid(_ app: XCUIApplication) throws -> Bool {
        guard let point = emptyMapPoint(app) else {
            throw XCTSkip("No empty map point found on this dataset")
        }
        longPress(app, at: point)

        let addFeature = element(app, id: A11yID.Map.pinChoiceAddFeatureButton)
        guard addFeature.waitForExistence(timeout: 5) else { return false }
        addFeature.tap()
        return true
    }

    // MARK: - Preset grid

    func testTappingAddFeatureOpensPresetGridWithBothPresets() throws {
        let app = reachMapScreen(scenario: UITestScenario.addFeatureOnline)
        XCTAssertTrue(try openAddFeatureGrid(app), "Add Feature button did not appear on the pin-choice card")

        let bench = element(app, id: A11yID.AddFeature.presetButton(name: "Bench"))
        let powerPole = element(app, id: A11yID.AddFeature.presetButton(name: "Power Pole"))
        XCTAssertTrue(bench.waitForExistence(timeout: 10), "Bench preset not shown")
        XCTAssertTrue(powerPole.exists, "Power Pole preset not shown")
    }

    func testClosingPresetGridReturnsToMapWithoutOpeningSubmissionForm() throws {
        let app = reachMapScreen(scenario: UITestScenario.addFeatureOnline)
        XCTAssertTrue(try openAddFeatureGrid(app), "Add Feature button did not appear on the pin-choice card")

        let closeButton = element(app, id: A11yID.AddFeature.closeButton)
        XCTAssertTrue(closeButton.waitForExistence(timeout: 10), "Preset grid did not appear")
        closeButton.tap()

        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 10),
                      "Map toolbar did not reappear after closing the preset grid")
        XCTAssertFalse(element(app, id: A11yID.AddFeature.submissionNoteTextEditor).exists,
                       "Submission form opened despite no preset ever being picked")
    }

    func testNoFeaturePresetsShowsEmptyMessage() throws {
        // mapWithNoImageryOptions's own WorkspaceDetailsNoImagery.json has a genuinely
        // populated longFormQuestDef (so the Map screen loads normally, unlike
        // workspacesSingleAutoRedirect's longFormQuestDef: null, which
        // InitialViewModel.fetchLongQuestsFor treats as a failure and falls back to the
        // picker instead of navigating here) but no "feature-presets" key at all (unlike
        // WorkspaceDetailsWithQuests.json, which addFeatureOnline/addFeatureNetworkDown
        // use) - QuestsRepository.featurePresets decodes empty.
        let app = reachMapScreen(scenario: UITestScenario.mapWithNoImageryOptions)
        XCTAssertTrue(try openAddFeatureGrid(app), "Add Feature button did not appear on the pin-choice card")

        XCTAssertTrue(element(app, id: A11yID.AddFeature.noPresetsMessage).waitForExistence(timeout: 10),
                      "Empty-presets message not shown for a workspace with no feature-presets configured")
    }

    // MARK: - Submission form

    func testSelectingPresetOpensSubmissionFormWithEmptyNote() throws {
        let app = reachMapScreen(scenario: UITestScenario.addFeatureOnline)
        XCTAssertTrue(try openAddFeatureGrid(app), "Add Feature button did not appear on the pin-choice card")

        let bench = element(app, id: A11yID.AddFeature.presetButton(name: "Bench"))
        XCTAssertTrue(bench.waitForExistence(timeout: 10), "Bench preset not shown")
        bench.tap()

        XCTAssertTrue(element(app, id: A11yID.AddFeature.submissionNoteTextEditor).waitForExistence(timeout: 10),
                      "Submission form did not open after picking a preset")
        let charCount = element(app, id: A11yID.AddFeature.submissionNoteCharCountLabel)
        XCTAssertTrue(charCount.waitForExistence(timeout: 5), "Character count label not shown")
        XCTAssertEqual(charCount.label, "0/255", "Character count did not start at 0/255 - label: \(charCount.label)")

        // No required fields for a feature (unlike LongForm) - Submit is always enabled.
        XCTAssertTrue(element(app, id: A11yID.AddFeature.submissionSubmitButton).isEnabled,
                      "Submit is disabled despite a feature having no required fields")
    }

    func testTypingNoteUpdatesCharacterCount() throws {
        let app = reachMapScreen(scenario: UITestScenario.addFeatureOnline)
        XCTAssertTrue(try openAddFeatureGrid(app), "Add Feature button did not appear on the pin-choice card")

        let bench = element(app, id: A11yID.AddFeature.presetButton(name: "Bench"))
        XCTAssertTrue(bench.waitForExistence(timeout: 10), "Bench preset not shown")
        bench.tap()

        let textEditor = element(app, id: A11yID.AddFeature.submissionNoteTextEditor)
        XCTAssertTrue(textEditor.waitForExistence(timeout: 10), "Submission form did not open")
        textEditor.tap()
        textEditor.typeText("Needs repair")

        let charCount = element(app, id: A11yID.AddFeature.submissionNoteCharCountLabel)
        XCTAssertTrue(waitUntil(timeout: 5, condition: { charCount.label == "12/255" }),
                      "Character count did not update after typing - label: \(charCount.label)")
    }

    func testClosingSubmissionFormReturnsToPresetGrid() throws {
        let app = reachMapScreen(scenario: UITestScenario.addFeatureOnline)
        XCTAssertTrue(try openAddFeatureGrid(app), "Add Feature button did not appear on the pin-choice card")

        let bench = element(app, id: A11yID.AddFeature.presetButton(name: "Bench"))
        XCTAssertTrue(bench.waitForExistence(timeout: 10), "Bench preset not shown")
        bench.tap()

        let submissionClose = element(app, id: A11yID.AddFeature.submissionCloseButton)
        XCTAssertTrue(submissionClose.waitForExistence(timeout: 10), "Submission form did not open")
        submissionClose.tap()

        XCTAssertTrue(element(app, id: A11yID.AddFeature.presetButton(name: "Bench")).waitForExistence(timeout: 10),
                      "Preset grid did not reappear after closing the submission form without submitting")
    }

    // MARK: - Submitting

    func testSubmittingFeatureOnlineShowsSuccessAlertAndClosesSheets() throws {
        let app = reachMapScreen(scenario: UITestScenario.addFeatureOnline)
        XCTAssertTrue(try openAddFeatureGrid(app), "Add Feature button did not appear on the pin-choice card")

        let bench = element(app, id: A11yID.AddFeature.presetButton(name: "Bench"))
        XCTAssertTrue(bench.waitForExistence(timeout: 10), "Bench preset not shown")
        bench.tap()

        let textEditor = element(app, id: A11yID.AddFeature.submissionNoteTextEditor)
        XCTAssertTrue(textEditor.waitForExistence(timeout: 10), "Submission form did not open")
        textEditor.tap()
        textEditor.typeText("Needs repair")

        element(app, id: A11yID.AddFeature.submissionSubmitButton).tap()

        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 10),
                      "Map toolbar did not reappear after submitting")
        XCTAssertFalse(element(app, id: A11yID.AddFeature.submissionNoteTextEditor).exists,
                       "Submission form still showing after submitting")

        let alert = element(app, id: A11yID.Map.syncStatusAlert)
        XCTAssertTrue(waitUntil(timeout: 15, condition: { alert.exists && alert.label.contains("Bench added successfully") }),
                      "Success alert not shown after the feature synced - label: \(alert.label)")
    }

    func testSubmittingFeatureOfflineQueuesItForLaterSync() throws {
        let app = reachMapScreen(scenario: UITestScenario.addFeatureNetworkDown)
        XCTAssertTrue(try openAddFeatureGrid(app), "Add Feature button did not appear on the pin-choice card")

        let powerPole = element(app, id: A11yID.AddFeature.presetButton(name: "Power Pole"))
        XCTAssertTrue(powerPole.waitForExistence(timeout: 10), "Power Pole preset not shown")
        powerPole.tap()

        XCTAssertTrue(element(app, id: A11yID.AddFeature.submissionNoteTextEditor).waitForExistence(timeout: 10),
                      "Submission form did not open")
        element(app, id: A11yID.AddFeature.submissionSubmitButton).tap()

        // The sheet closes immediately regardless of the network outcome - the draft was
        // already persisted before this point (FeatureSubmissionManager.submit's own doc
        // comment) - and a failed attempt is never surfaced directly, so the only visible
        // signal is the sync button's own badge value.
        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 10),
                      "Map toolbar did not reappear after submitting")

        let syncButton = element(app, id: A11yID.Map.syncButton)
        XCTAssertTrue(waitUntil(timeout: 15, condition: { syncButton.value as? String == "1 pending" }),
                      "Sync button does not show 1 pending feature after an offline submission - value: \(String(describing: syncButton.value))")
    }

    // MARK: - Layout

    func testAddFeatureLayout() throws {
        let app = reachMapScreen(scenario: UITestScenario.addFeatureOnline)
        XCTAssertTrue(try openAddFeatureGrid(app), "Add Feature button did not appear on the pin-choice card")

        let bench = element(app, id: A11yID.AddFeature.presetButton(name: "Bench"))
        let powerPole = element(app, id: A11yID.AddFeature.presetButton(name: "Power Pole"))
        let gridClose = element(app, id: A11yID.AddFeature.closeButton)
        XCTAssertTrue(bench.waitForExistence(timeout: 10), "Bench preset not shown")

        let window = app.windows.firstMatch.frame
        for (name, control) in [("Bench preset", bench), ("Power Pole preset", powerPole), ("Grid close button", gridClose)] {
            XCTAssertTrue(control.isHittable, "\(name) exists but is not tappable")
            XCTAssertTrue(window.contains(control.frame), "\(name) extends outside the screen bounds")
        }

        bench.tap()
        let textEditor = element(app, id: A11yID.AddFeature.submissionNoteTextEditor)
        XCTAssertTrue(textEditor.waitForExistence(timeout: 10), "Submission form did not open")
        let addPhoto = element(app, id: A11yID.AddFeature.submissionAddPhotoButton)
        let submit = element(app, id: A11yID.AddFeature.submissionSubmitButton)
        let submissionClose = element(app, id: A11yID.AddFeature.submissionCloseButton)
        for (name, control) in [("Add Photo button", addPhoto), ("Submit button", submit), ("Submission close button", submissionClose)] {
            XCTAssertTrue(control.isHittable, "\(name) exists but is not tappable")
            XCTAssertTrue(window.contains(control.frame), "\(name) extends outside the screen bounds")
        }
        assertNoOverlap([(addPhoto, "Add Photo button"), (submit, "Submit button")])
    }
}
