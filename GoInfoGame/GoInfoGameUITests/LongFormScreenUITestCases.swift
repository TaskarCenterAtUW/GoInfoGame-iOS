//
//  LongFormScreenUITestCases.swift
//  GoInfoGameUITests
//
//  The quest-answer form (quests/LongQuests/View/LongForm.swift), reached by tapping a
//  quest annotation on the Map. All three scenarios here (longFormOnline,
//  longFormNetworkDown, longFormNetworkRecovers) land on the Map the same way
//  MapScreenUITestCases.mapWithQuestClusters does - one eligible workspace, real
//  auto-redirect - but serve LongFormOSMElements.json (not MapOSMElements.json): a
//  small, deliberately-placed fixture instead of the real ~2km/973-element capture, so
//  a test can target ONE specific, known element instead of whichever pin happens to be
//  first. See that fixture's own "_note" field for exactly what each element is; the
//  ones this suite uses by id:
//    121949  sidewalk, no tags at all in the map data (a genuine blank form, UNLESS the
//            freshness fetch below prefills it)
//    409776  sidewalk, ext:obstruction=yes / ext:obstruction:type=other + an existing
//            KartaView photo (real captured tags) plus ext:text_entry and
//            ext:component:quest_type-MultipleChoice (synthetic, added purely to exercise
//            those two component types' own prefill) - used for prefill + dependency tests
//    409893  crossing, no tags at all - used for the "fill it out and submit" tests
//    900001  sidewalk, SYNTHETIC, every applicable question already answered - must
//            never show a pin at all (LongElementQuest.isApplicable excludes it)
//    900101  kerb node, SYNTHETIC, kerb=raised only - the one node-typed element here
//
//  LongFormLatestElements.json is what `GET /way|node/{id}.json` (the freshness fetch
//  QuestSheetView runs on open, via LongElementQuest.fetchLatestTagsIfNeeded) answers
//  with, keyed by id - it deliberately does NOT just echo the map data back for every
//  id, so "prefill reflects the live fetch, not the stale map load" is genuinely
//  checked, not assumed:
//    121949  server says ext:surface=asphalt, width=36 (the map data has neither) -
//            proves prefill comes from the fetch
//    409777  server says every applicable Sidewalks question is now answered - proves
//            the "already answered by another user" branch, not the form, is shown
//    409776  duplicates its own map-data tags exactly (including the two synthetic
//            component-type-demo tags) - exists only because it HAS an override entry
//            at all; a tag added to one of its two fixture entries and not the other is
//            silently invisible to the form, since QuestSheetView always rebuilds from
//            this file's response once the freshness fetch succeeds, never from the map
//            data directly (confirmed directly - see this file's own LongFormLatest
//            Elements.json "_note").
//  Every other id (409893, 900101) has no override, so the stub falls back to echoing
//  that element's own entry from the map data - a perfectly realistic response ("hasn't
//  changed since map.json was fetched"), not a gap in the fixture.
//
//  Scope: quest ANSWERING (prefill from tags, dependency show/hide, validation,
//  submit/save, online/offline) and the sheet's own chrome (dismiss, screen-bounds,
//  overlap). Deliberately OUT of scope: Compose Note (its own small text-submission
//  flow, unrelated to answering quests) and the changeset-conflict resolution sheet
//  (needs a second, concurrent edit to trigger - no fixture for that here). AutoCapture
//  (LiDAR) cannot be exercised at all in the Simulator, which has no LiDAR sensor -
//  QuestOptions.swift's own canShowQuest() hides that question type on such a device,
//  so it is simply never offered, not a gap in this suite.
//

import XCTest

final class LongFormScreenUITestCases: ScreenshotOnFailureUITestCase {

    // MARK: - Helpers

    @discardableResult
    private func reachMapScreen(scenario: String, file: StaticString = #filePath, line: UInt = #line) -> XCUIApplication {
        let app = launchApp(scenario: scenario)
        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 30),
                      "Did not reach the Map screen via the Workspaces auto-redirect flow", file: file, line: line)
        return app
    }

    private func scroll(in app: XCUIApplication) -> XCUIElement {
        element(app, id: A11yID.LongForm.scrollView)
    }

    /// The base class's `scrollToElement` swipes at coordinates XCUIElement.swipeUp()/
    /// swipeDown() pick automatically for the given element, generally centered - fine
    /// for every other screen's plain ScrollView, but LongForm's ExclusiveChoiceView and
    /// MultipleChoiceView (QuestOptions.swift) each wrap their own choice grid in their
    /// OWN nested ScrollView, still inside this screen's outer List. Confirmed directly:
    /// once any such question is anywhere near the swipe's path, the touch can get
    /// captured by that inner ScrollView instead of the outer List, so the outer list's
    /// scroll position never actually advances and a question below the fold is never
    /// reached no matter how many swipes are attempted. This app's own production
    /// structure isn't something to change for testing (LongForm.swift's own listRowInsets
    /// gives each row a 20pt leading/trailing margin, outside any grid/inner ScrollView's
    /// bounds) - a swipe confined to that left margin reliably reaches the outer List
    /// instead, so this screen uses that in place of the base class's helper throughout.
    @discardableResult
    private func scrollFormToElement(_ element: XCUIElement, in scrollView: XCUIElement,
                                     maxSwipes: Int = 16, requireFullyOnScreen: Bool = false) -> Bool {
        let app = XCUIApplication()
        let window = app.windows.firstMatch.frame
        // Absolute screen coordinates throughout (app's own normalizedOffset .zero is
        // the window's top-left) - the target margin is a property of the screen, not
        // of scrollView's own frame, so there's no need to convert between the two.
        // Not the screen edge: the List itself starts at x=8 (confirmed directly via
        // its own frame), so a touch there risks landing right on/outside its own
        // boundary rather than reliably inside it. Rows are inset 20pt from that edge
        // (listRowInsets in LongForm.swift), so x=15 sits inside the List but still
        // outside any row's own content/inner ScrollView.
        let x: CGFloat = 15
        let topY = window.minY + 24
        let bottomY = window.maxY - 24
        // XCUITest considers an element "hittable" once its CENTER is on-screen and
        // unobscured - fine for reachability, but a tall grid cell (a MultipleChoice
        // question's choice tiles, QuestOptions.swift) can satisfy that while still
        // extending well past the bottom edge (confirmed directly: a choice tile
        // reported hittable with ~40pt of its own height below y=852). The bounds test
        // needs the stricter, fully-contained condition instead.
        func satisfied() -> Bool {
            guard element.isHittable else { return false }
            guard requireFullyOnScreen else { return true }
            return window.contains(element.frame)
        }
        var swipes = 0
        while !satisfied() && swipes < maxSwipes {
            let down = !(element.exists && element.frame.midY < window.midY)
            // A full top-to-bottom swipe is the fastest way to bring a not-yet-visible
            // element into view, but once it's already hittable and only the stricter
            // full-containment check is failing (a small tile a few points past an
            // edge), that same big a step reliably overshoots straight past the other
            // edge instead of settling it - confirmed directly: with only the big swipe,
            // a small tile oscillated in and out of full containment for every attempt
            // and never once landed inside it. Once hittable, switch to a small nudge
            // centered on the window's own middle so each step only moves the content a
            // little.
            let big = !(element.exists && element.isHittable)
            let (fromY, toY): (CGFloat, CGFloat)
            if big {
                (fromY, toY) = down ? (bottomY, topY) : (topY, bottomY)
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

    /// Call after typing into any field, before scrolling further: the keyboard covers
    /// roughly the bottom third of the screen, which is exactly where scrollFormToElement
    /// starts its "reveal more content below" swipe - confirmed directly that leaving it
    /// up made every later question unreachable, since that starting touch landed on the
    /// keyboard instead of the list. The numeric field's own accessory toolbar has a real
    /// "Done" button (QuestOptions.swift's SignedDecimalTextField); the free-text field's
    /// default keyboard has no such button (nothing here configures one), so this falls
    /// back to a tap in the same left margin scrollFormToElement itself uses to reliably
    /// reach the list rather than any field's own content - a tap there while a field is
    /// first responder ends editing the same way tapping any non-field content would.
    private func dismissKeyboardIfShown(_ app: XCUIApplication) {
        let done = app.toolbars.buttons["Done"]
        if done.exists {
            done.tap()
            return
        }
        guard app.keyboards.count > 0 else { return }
        // The List itself shrinks to make room for the keyboard (`.padding(.bottom,
        // keyboardHeight)` in LongForm.swift), but the window's own frame doesn't - so a
        // tap at the WINDOW's vertical middle can land on the keyboard itself once it's
        // tall enough to reach that far up (confirmed directly: this only ever failed to
        // dismiss for the free-text field, whose keyboard is the tallest of the two kinds
        // this form uses). A point near the List's own top edge stays clear of the
        // keyboard regardless of how much room it ends up taking.
        let list = scroll(in: app)
        let y = list.frame.minY + 24
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: 15, dy: y))
            .tap()
    }

    /// A single, non-looping snapshot - quest annotations share one identifier (see
    /// A11yID.Map.questAnnotation's own comment), so the underlying OSM element's id,
    /// exposed as the pin's accessibilityValue (LongElementQuest.displayUnit's own
    /// comment explains how it gets there), is the only way to target one specific pin.
    private func findQuestAnnotation(_ app: XCUIApplication, elementID: Int64) -> XCUIElement? {
        app.buttons.matching(identifier: A11yID.Map.questAnnotation)
            .allElementsBoundByIndex.first(where: { $0.value as? String == "\(elementID)" })
    }

    private func waitUntil(timeout: TimeInterval, condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if condition() { return true }
            usleep(300_000)
        } while Date() < deadline
        return condition()
    }

    private func waitForAnnotationGone(_ app: XCUIApplication, elementID: Int64, timeout: TimeInterval) -> Bool {
        waitUntil(timeout: timeout) { findQuestAnnotation(app, elementID: elementID) == nil }
    }

    /// Taps the pin for `elementID` and waits for whichever of QuestSheetView's two
    /// outcomes actually applies - the LongForm itself (dismissButton), or "already
    /// answered by another user" (alreadyAnsweredOKButton). Neither branch has a root
    /// identifier of its own (see A11yID.LongForm's own comment for why), so this is
    /// the "did it open" signal for both.
    @discardableResult
    private func openForm(_ app: XCUIApplication, elementID: Int64, timeout: TimeInterval = 40) -> Bool {
        guard waitUntil(timeout: timeout, condition: { findQuestAnnotation(app, elementID: elementID) != nil }),
              let pin = findQuestAnnotation(app, elementID: elementID) else { return false }
        pin.tap()
        return element(app, id: A11yID.LongForm.dismissButton).waitForExistence(timeout: 15)
            || element(app, id: A11yID.LongForm.alreadyAnsweredOKButton).waitForExistence(timeout: 2)
    }

    /// A representative control from every visible question on 409776's form (the
    /// richest of this suite's fixtures - 6 applicable questions plus an existing
    /// photo), used by both layout tests below.
    private func longFormControls(_ app: XCUIApplication) -> [(String, XCUIElement)] {
        [
            ("Dismiss button", element(app, id: A11yID.LongForm.dismissButton)),
            ("Compose Note button", element(app, id: A11yID.LongForm.composeNoteButton)),
            ("Ignore this quest button", element(app, id: A11yID.LongForm.ignoreQuestButton)),
            ("Quest 107 text entry", element(app, id: A11yID.LongForm.textInput(questID: 107))),
            ("Quest 106 choice 1", element(app, id: A11yID.LongForm.option(questID: 106, value: "choice_1"))),
            ("Quest 101 asphalt option", element(app, id: A11yID.LongForm.option(questID: 101, value: "asphalt"))),
            ("Quest 103 numeric width", element(app, id: A11yID.LongForm.numericInput(questID: 103))),
            ("Quest 104 obstruction yes", element(app, id: A11yID.LongForm.option(questID: 104, value: "yes"))),
            ("Quest 105 obstruction type other", element(app, id: A11yID.LongForm.option(questID: 105, value: "other"))),
            ("Submit button", element(app, id: A11yID.LongForm.submitButton)),
        ]
    }

    // MARK: - Prefill

    /// 409893 has no tags at all in the map data, and no override in
    /// LongFormLatestElements.json (so the freshness fetch just echoes the same blank
    /// tags back) - a genuinely blank form, distinct from testOpeningFormPrefillsFrom
    /// FreshlyFetchedTagsNotStaleMapData below, where blank map data gets prefilled
    /// anyway because the LIVE fetch disagrees with it.
    func testFormOpensBlankWhenNoTagsMatchAndNoServerOverride() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormOnline)
        XCTAssertTrue(openForm(app, elementID: 409893), "Form did not open")
        let scrollView = scroll(in: app)

        let markingsNo = element(app, id: A11yID.LongForm.option(questID: 201, value: "no"))
        XCTAssertTrue(scrollFormToElement(markingsNo, in: scrollView), "Markings option not reachable")
        XCTAssertTrue(markingsNo.label.hasSuffix("option unselected"),
                      "Blank crossing shows a prefilled markings answer - label: \(markingsNo.label)")

        let lanes = element(app, id: A11yID.LongForm.numericInput(questID: 204))
        XCTAssertTrue(scrollFormToElement(lanes, in: scrollView), "Lane-count field not reachable")
        XCTAssertTrue(lanes.label.contains("Current value: empty"),
                      "Blank crossing's lane-count field is not empty - label: \(lanes.label)")
    }

    /// 121949 carries no tags at all in the map data - any prefilled answer here can
    /// only have come from the live GET /way/121949.json fetch (LongFormLatestElements
    /// .json's override), proving prefill genuinely reflects that fetch and not the
    /// stale map load.
    func testOpeningFormPrefillsFromFreshlyFetchedTagsNotStaleMapData() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormOnline)
        XCTAssertTrue(openForm(app, elementID: 121949), "Form did not open")
        let scrollView = scroll(in: app)

        let asphalt = element(app, id: A11yID.LongForm.option(questID: 101, value: "asphalt"))
        XCTAssertTrue(scrollFormToElement(asphalt, in: scrollView), "Surface option not reachable")
        XCTAssertTrue(asphalt.label.hasSuffix("option selected"),
                      "Surface not prefilled from the freshly-fetched ext:surface=asphalt tag - label: \(asphalt.label)")

        let width = element(app, id: A11yID.LongForm.numericInput(questID: 103))
        XCTAssertTrue(scrollFormToElement(width, in: scrollView), "Width field not reachable")
        XCTAssertTrue(width.label.contains("Current value: 36"),
                      "Width not prefilled from the freshly-fetched width=36 tag - label: \(width.label)")
    }

    /// 409776's real captured tags (ext:obstruction=yes, ext:obstruction:type=other)
    /// prefill both the primary question and its dependent follow-up. Changing the
    /// primary answer away from "yes" must hide the now-inapplicable follow-up
    /// (LongFormViewModel.clearAnswersForHiddenQuests) rather than leaving it visible
    /// with a stale answer.
    func testFollowUpQuestionPrefillsAndClearsWhenDependencyAnswerChanges() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormOnline)
        XCTAssertTrue(openForm(app, elementID: 409776), "Form did not open")
        let scrollView = scroll(in: app)

        let obstructionYes = element(app, id: A11yID.LongForm.option(questID: 104, value: "yes"))
        XCTAssertTrue(scrollFormToElement(obstructionYes, in: scrollView), "Obstruction option not reachable")
        XCTAssertTrue(obstructionYes.label.hasSuffix("option selected"),
                      "Obstruction not prefilled from the element's real ext:obstruction=yes tag - label: \(obstructionYes.label)")

        let obstructionTypeOther = element(app, id: A11yID.LongForm.option(questID: 105, value: "other"))
        XCTAssertTrue(scrollFormToElement(obstructionTypeOther, in: scrollView), "Obstruction-type option not reachable")
        XCTAssertTrue(obstructionTypeOther.label.hasSuffix("option selected"),
                      "Dependent obstruction-type question not prefilled from ext:obstruction:type=other - label: \(obstructionTypeOther.label)")

        let obstructionNo = element(app, id: A11yID.LongForm.option(questID: 104, value: "no"))
        XCTAssertTrue(scrollFormToElement(obstructionNo, in: scrollView), "Obstruction 'no' option not reachable")
        obstructionNo.tap()

        XCTAssertTrue(element(app, id: A11yID.LongForm.question(questID: 105)).waitForNonExistence(timeout: 5),
                      "Dependent obstruction-type question still shown after changing its dependency to \"no\"")
    }

    /// 409776 also carries a synthetic ext:text_entry tag (added purely to exercise this
    /// component type - see this file's header comment). The layout tests already prove
    /// the TextEntry field renders safely; this proves it actually reflects the prefilled
    /// tag value, not just that it exists. TextEditor surfaces its current text as the
    /// element's own `value` in the accessibility tree (like any other text-input
    /// control) - its `label` only reports a character count (see TextEntryView's own
    /// accessibilityLabel), which cannot distinguish "prefilled with this text" from
    /// "prefilled with some other text of the same length".
    func testTextEntryQuestionPrefillsFromTag() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormOnline)
        XCTAssertTrue(openForm(app, elementID: 409776), "Form did not open")
        let scrollView = scroll(in: app)

        let textEntry = element(app, id: A11yID.LongForm.textInput(questID: 107))
        XCTAssertTrue(scrollFormToElement(textEntry, in: scrollView), "Text entry field not reachable")
        XCTAssertEqual(textEntry.value as? String, "Uneven pavement near the entrance",
                       "Text entry not prefilled from ext:text_entry tag - value: \(String(describing: textEntry.value))")
    }

    /// 409776 also carries a synthetic ext:component:quest_type-MultipleChoice tag set to
    /// "choice_1;choice_3" (added purely to exercise this component type - see this file's
    /// header comment). MultipleChoiceView splits an existing tag's value on ";"
    /// (initializeSelectedValues, QuestOptions.swift) to seed its selection set - this
    /// proves a multi-value tag pre-selects every matching tile, not just the first, and
    /// leaves every non-matching tile unselected.
    func testMultipleChoiceQuestionPrefillsMultipleSelectionsFromSemicolonSeparatedTag() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormOnline)
        XCTAssertTrue(openForm(app, elementID: 409776), "Form did not open")
        let scrollView = scroll(in: app)

        for value in ["choice_1", "choice_3"] {
            let option = element(app, id: A11yID.LongForm.option(questID: 106, value: value))
            XCTAssertTrue(scrollFormToElement(option, in: scrollView), "Quest 106 option \(value) not reachable")
            XCTAssertTrue(option.label.hasSuffix("option selected"),
                          "\(value) not prefilled as selected from the semicolon-separated tag - label: \(option.label)")
        }
        for value in ["choice_2", "choice_4"] {
            let option = element(app, id: A11yID.LongForm.option(questID: 106, value: value))
            XCTAssertTrue(scrollFormToElement(option, in: scrollView), "Quest 106 option \(value) not reachable")
            XCTAssertTrue(option.label.hasSuffix("option unselected"),
                          "\(value) incorrectly prefilled as selected - label: \(option.label)")
        }
    }

    /// Selecting "other" for 409776's (currently blank) surface question must reveal its
    /// dependent description question (102, TextEntry) - the reverse direction of
    /// testFollowUpQuestionPrefillsAndClearsWhenDependencyAnswerChanges above, which only
    /// covers a dependency already met via tags before the form even opens. Also checks
    /// that answering one question live doesn't disturb this same element's other,
    /// already tag-prefilled answers (104's ext:obstruction=yes) sitting alongside it.
    func testSelectingOtherSurfaceRevealsDescriptionQuestion() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormOnline)
        XCTAssertTrue(openForm(app, elementID: 409776), "Form did not open")
        let scrollView = scroll(in: app)

        let other = element(app, id: A11yID.LongForm.option(questID: 101, value: "other"))
        XCTAssertTrue(scrollFormToElement(other, in: scrollView), "Surface 'other' option not reachable")
        other.tap()

        let description = element(app, id: A11yID.LongForm.textInput(questID: 102))
        XCTAssertTrue(scrollFormToElement(description, in: scrollView),
                      "Surface-description question not shown after selecting 'other'")

        let obstructionYes = element(app, id: A11yID.LongForm.option(questID: 104, value: "yes"))
        XCTAssertTrue(scrollFormToElement(obstructionYes, in: scrollView), "Obstruction option not reachable")
        XCTAssertTrue(obstructionYes.label.hasSuffix("option selected"),
                      "Answering surface live disturbed 409776's own tag-prefilled obstruction answer - label: \(obstructionYes.label)")
    }

    /// The one node-typed element in this suite (every other fixture is a way) -
    /// exercises fetchNode2/OSMNode rather than fetchway2/OSMWay entirely untested
    /// otherwise. kerb=raised prefills 301 and satisfies 303's dependency, but 303
    /// itself has no height tag, so it must show visible-but-blank, not some stray
    /// carried-over value.
    func testKerbNodeFormShowsRaisedPrefillAndBlankDependentHeightQuestion() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormOnline)
        XCTAssertTrue(openForm(app, elementID: 900101), "Kerb node form did not open")
        let scrollView = scroll(in: app)

        let raised = element(app, id: A11yID.LongForm.option(questID: 301, value: "raised"))
        XCTAssertTrue(scrollFormToElement(raised, in: scrollView), "Kerb type option not reachable")
        XCTAssertTrue(raised.label.hasSuffix("option selected"),
                      "Kerb type not prefilled from kerb=raised - label: \(raised.label)")

        let height = element(app, id: A11yID.LongForm.numericInput(questID: 303))
        XCTAssertTrue(scrollFormToElement(height, in: scrollView),
                      "Height question not shown despite its kerb=raised dependency being met")
        XCTAssertTrue(height.label.contains("Current value: empty"),
                      "Height incorrectly prefilled - label: \(height.label)")
    }

    // MARK: - Saving answers

    /// The strongest available proof answers actually reached the server: fully
    /// answering every applicable Crossings question and submitting must, once the
    /// online round trip (changeset create/upload/close) completes and the merged tags
    /// land locally, make this element's own pin disappear.
    func testSubmittingFullyAnsweredElementRemovesItsPin() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormOnline)
        XCTAssertTrue(openForm(app, elementID: 409893), "Form did not open")
        let scrollView = scroll(in: app)

        for (questID, value) in [(201, "no"), (202, "no")] {
            let option = element(app, id: A11yID.LongForm.option(questID: questID, value: value))
            XCTAssertTrue(scrollFormToElement(option, in: scrollView), "Quest \(questID) option \(value) not reachable")
            option.tap()
        }

        let lanes = element(app, id: A11yID.LongForm.numericInput(questID: 204))
        XCTAssertTrue(scrollFormToElement(lanes, in: scrollView), "Lane-count field not reachable")
        lanes.tap()
        lanes.typeText("4")
        dismissKeyboardIfShown(app)

        let notes = element(app, id: A11yID.LongForm.textInput(questID: 205))
        XCTAssertTrue(scrollFormToElement(notes, in: scrollView), "Notes field not reachable")
        notes.tap()
        notes.typeText("UI test note")
        dismissKeyboardIfShown(app)

        let submit = element(app, id: A11yID.LongForm.submitButton)
        XCTAssertTrue(scrollFormToElement(submit, in: scrollView), "Submit button not reachable")
        XCTAssertTrue(submit.isEnabled, "Submit disabled despite every answer being valid")
        submit.tap()

        // Submit closes the sheet immediately - MapView's dismissSheet handler sets
        // isPresented = false for every scenario, including the syncBackground event
        // QuestSubmissionManager fires right after persisting locally, before any
        // network call even starts.
        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 10),
                      "Map toolbar did not reappear after submitting - sheet may not have closed")

        XCTAssertTrue(waitForAnnotationGone(app, elementID: 409893, timeout: 30),
                      "Crossing's pin is still on the map after fully answering and submitting it")
    }

    /// 409776 already has 4 of its 6 applicable Sidewalks questions auto-filled from real
    /// tags (104/105 obstruction, 106/107 the component-type demos) - completing it only
    /// needs the remaining two (101 surface, 103 width) answered by hand. Submitting must
    /// succeed with that mix and remove the pin, proving auto-filled and manually-entered
    /// answers merge into one complete submission rather than the submit gate only
    /// recognizing whichever kind was entered most recently. Companion to
    /// testSubmittingFullyAnsweredElementRemovesItsPin above (a Crossing, entirely
    /// hand-answered) - this is the Sidewalks element type, with auto-fill in the mix.
    func testCompletingRemainingSidewalkQuestionsAfterAutoFillRemovesPinOnSubmit() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormOnline)
        XCTAssertTrue(openForm(app, elementID: 409776), "Form did not open")
        let scrollView = scroll(in: app)

        // "concrete" rather than "other" keeps 102 (surface description) out of play here
        // - that dependency reveal is its own test, testSelectingOtherSurfaceReveals
        // DescriptionQuestion above.
        let concrete = element(app, id: A11yID.LongForm.option(questID: 101, value: "concrete"))
        XCTAssertTrue(scrollFormToElement(concrete, in: scrollView), "Surface 'concrete' option not reachable")
        concrete.tap()

        let width = element(app, id: A11yID.LongForm.numericInput(questID: 103))
        XCTAssertTrue(scrollFormToElement(width, in: scrollView), "Width field not reachable")
        width.tap()
        width.typeText("40")
        dismissKeyboardIfShown(app)

        let obstructionYes = element(app, id: A11yID.LongForm.option(questID: 104, value: "yes"))
        XCTAssertTrue(scrollFormToElement(obstructionYes, in: scrollView), "Obstruction option not reachable")
        XCTAssertTrue(obstructionYes.label.hasSuffix("option selected"),
                      "409776's own tag-prefilled obstruction answer missing going into submit - label: \(obstructionYes.label)")

        let submit = element(app, id: A11yID.LongForm.submitButton)
        XCTAssertTrue(scrollFormToElement(submit, in: scrollView), "Submit button not reachable")
        XCTAssertTrue(submit.isEnabled, "Submit disabled despite every applicable question being answered")
        submit.tap()

        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 10),
                      "Map toolbar did not reappear after submitting - sheet may not have closed")
        XCTAssertTrue(waitForAnnotationGone(app, elementID: 409776, timeout: 30),
                      "Sidewalk's pin is still on the map after completing its remaining questions and submitting")
    }

    /// count_lanes_crossed's own quest_answer_validation (min 1, max 10) must block
    /// Submit for an out-of-range value and release it again once corrected -
    /// LongFormViewModel.validationErrorMessage() drives both the button's .disabled
    /// state and its background color.
    func testNumericValidationBlocksSubmitUntilCorrected() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormOnline)
        XCTAssertTrue(openForm(app, elementID: 409893), "Form did not open")
        let scrollView = scroll(in: app)

        let markingsNo = element(app, id: A11yID.LongForm.option(questID: 201, value: "no"))
        XCTAssertTrue(scrollFormToElement(markingsNo, in: scrollView), "Markings option not reachable")
        markingsNo.tap()

        let lanes = element(app, id: A11yID.LongForm.numericInput(questID: 204))
        XCTAssertTrue(scrollFormToElement(lanes, in: scrollView), "Lane-count field not reachable")
        lanes.tap()
        lanes.typeText("99")
        dismissKeyboardIfShown(app)

        let submit = element(app, id: A11yID.LongForm.submitButton)
        XCTAssertTrue(scrollFormToElement(submit, in: scrollView), "Submit button not reachable")
        XCTAssertFalse(submit.isEnabled, "Submit stayed enabled with an out-of-range lane count (99, max 10)")

        // Dismissing the keyboard above dropped focus - back to lanes and re-tap it
        // before it can accept more input.
        XCTAssertTrue(scrollFormToElement(lanes, in: scrollView), "Lane-count field not reachable")
        lanes.tap()
        // "\u{8}" is backspace - clears the invalid "99" before typing a valid value,
        // since typeText appends at the cursor rather than replacing the field.
        lanes.typeText("\u{8}\u{8}5")
        dismissKeyboardIfShown(app)

        XCTAssertTrue(scrollFormToElement(submit, in: scrollView), "Submit button not reachable")
        XCTAssertTrue(submit.isEnabled, "Submit did not re-enable after correcting the lane count to a valid value")
    }

    // MARK: - Compose Note

    /// Compose Note is an inline toggle box within this same sheet (LongForm.swift's
    /// own notesBoxContent), not a separate screen - opened by composeNoteButton,
    /// submits via POST /notes.json (the same OSM API host every other LongForm
    /// network call uses).
    func testComposeNoteButtonOpensTextEditorWithSubmitDisabled() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormOnline)
        XCTAssertTrue(openForm(app, elementID: 409776), "Form did not open")
        let scrollView = scroll(in: app)

        let composeNote = element(app, id: A11yID.LongForm.composeNoteButton)
        XCTAssertTrue(scrollFormToElement(composeNote, in: scrollView), "Compose Note button not reachable")
        composeNote.tap()

        let editor = element(app, id: A11yID.LongForm.composeNoteTextEditor)
        XCTAssertTrue(scrollFormToElement(editor, in: scrollView), "Note text editor not reachable")

        let submit = element(app, id: A11yID.LongForm.composeNoteSubmitButton)
        XCTAssertTrue(scrollFormToElement(submit, in: scrollView), "Note submit button not reachable")
        XCTAssertFalse(submit.isEnabled, "Note submit button is enabled despite the text editor being empty")
    }

    func testTypingNoteTextEnablesSubmitButton() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormOnline)
        XCTAssertTrue(openForm(app, elementID: 409776), "Form did not open")
        let scrollView = scroll(in: app)

        element(app, id: A11yID.LongForm.composeNoteButton).tap()
        let editor = element(app, id: A11yID.LongForm.composeNoteTextEditor)
        XCTAssertTrue(scrollFormToElement(editor, in: scrollView), "Note text editor not reachable")
        editor.tap()
        editor.typeText("Uneven pavement near the entrance")
        dismissKeyboardIfShown(app)

        let submit = element(app, id: A11yID.LongForm.composeNoteSubmitButton)
        XCTAssertTrue(scrollFormToElement(submit, in: scrollView), "Note submit button not reachable")
        XCTAssertTrue(submit.isEnabled, "Note submit button did not enable after typing text")
    }

    func testCancelClosesComposeNoteWithoutSubmitting() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormOnline)
        XCTAssertTrue(openForm(app, elementID: 409776), "Form did not open")
        let scrollView = scroll(in: app)

        element(app, id: A11yID.LongForm.composeNoteButton).tap()
        let editor = element(app, id: A11yID.LongForm.composeNoteTextEditor)
        XCTAssertTrue(scrollFormToElement(editor, in: scrollView), "Note text editor not reachable")
        editor.tap()
        editor.typeText("This should never be submitted")
        dismissKeyboardIfShown(app)

        let cancel = element(app, id: A11yID.LongForm.composeNoteCancelButton)
        XCTAssertTrue(scrollFormToElement(cancel, in: scrollView), "Cancel button not reachable")
        cancel.tap()

        XCTAssertTrue(element(app, id: A11yID.LongForm.composeNoteTextEditor).waitForNonExistence(timeout: 5),
                      "Note text editor still showing after Cancel")
        XCTAssertFalse(element(app, id: A11yID.LongForm.composeNoteStatusMessage).exists,
                       "A status message appeared despite cancelling instead of submitting")
    }

    // MARK: - Compose Note: network on/off

    func testSubmittingNoteOnlineShowsSuccessMessage() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormOnline)
        XCTAssertTrue(openForm(app, elementID: 409776), "Form did not open")
        let scrollView = scroll(in: app)

        element(app, id: A11yID.LongForm.composeNoteButton).tap()
        let editor = element(app, id: A11yID.LongForm.composeNoteTextEditor)
        XCTAssertTrue(scrollFormToElement(editor, in: scrollView), "Note text editor not reachable")
        editor.tap()
        editor.typeText("Uneven pavement near the entrance")
        dismissKeyboardIfShown(app)

        let submit = element(app, id: A11yID.LongForm.composeNoteSubmitButton)
        XCTAssertTrue(scrollFormToElement(submit, in: scrollView), "Note submit button not reachable")
        submit.tap()

        let status = element(app, id: A11yID.LongForm.composeNoteStatusMessage)
        XCTAssertTrue(status.waitForExistence(timeout: 15), "Status message did not appear after submitting")
        XCTAssertEqual(status.label, "Note submitted successfully", "Unexpected status text - label: \(status.label)")
        XCTAssertTrue(element(app, id: A11yID.LongForm.composeNoteTextEditor).waitForNonExistence(timeout: 5),
                      "Note box still showing after a successful submit")
    }

    func testSubmittingNoteOfflineShowsErrorMessage() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormNetworkDown)
        XCTAssertTrue(openForm(app, elementID: 409776), "Form did not open")
        let scrollView = scroll(in: app)

        element(app, id: A11yID.LongForm.composeNoteButton).tap()
        let editor = element(app, id: A11yID.LongForm.composeNoteTextEditor)
        XCTAssertTrue(scrollFormToElement(editor, in: scrollView), "Note text editor not reachable")
        editor.tap()
        editor.typeText("Uneven pavement near the entrance")
        dismissKeyboardIfShown(app)

        let submit = element(app, id: A11yID.LongForm.composeNoteSubmitButton)
        XCTAssertTrue(scrollFormToElement(submit, in: scrollView), "Note submit button not reachable")
        submit.tap()

        let status = element(app, id: A11yID.LongForm.composeNoteStatusMessage)
        XCTAssertTrue(status.waitForExistence(timeout: 15), "Status message did not appear after a failed submit")
        XCTAssertNotEqual(status.label, "Note submitted successfully",
                          "Got the success message despite the network being down - label: \(status.label)")
    }

    // MARK: - Compose Note: layout

    func testComposeNoteControlsLayout() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormOnline)
        XCTAssertTrue(openForm(app, elementID: 409776), "Form did not open")
        let scrollView = scroll(in: app)

        element(app, id: A11yID.LongForm.composeNoteButton).tap()
        let editor = element(app, id: A11yID.LongForm.composeNoteTextEditor)
        let submit = element(app, id: A11yID.LongForm.composeNoteSubmitButton)
        let cancel = element(app, id: A11yID.LongForm.composeNoteCancelButton)
        XCTAssertTrue(scrollFormToElement(cancel, in: scrollView, requireFullyOnScreen: true), "Compose Note controls not reachable")

        let window = app.windows.firstMatch
        for (name, control) in [("Note text editor", editor), ("Submit button", submit), ("Cancel button", cancel)] {
            XCTAssertTrue(control.isHittable, "\(name) exists but is not tappable")
            XCTAssertTrue(window.frame.contains(control.frame), "\(name) extends outside the screen bounds")
        }
        assertNoOverlap([(submit, "Submit button"), (cancel, "Cancel button")])
    }

    // MARK: - Already answered

    /// The freshness fetch can reveal that someone else fully answered this element
    /// since the map data was loaded (409777's LongFormLatestElements.json override) -
    /// QuestSheetView must show the "already answered" message instead of the form.
    func testTappingElementAnsweredByAnotherUserShowsMessageInsteadOfForm() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormOnline)
        XCTAssertTrue(waitUntil(timeout: 40, condition: { findQuestAnnotation(app, elementID: 409777) != nil }),
                      "No quest annotation appeared for element 409777")
        findQuestAnnotation(app, elementID: 409777)?.tap()

        XCTAssertTrue(element(app, id: A11yID.LongForm.alreadyAnsweredOKButton).waitForExistence(timeout: 15),
                      "Already-answered message did not appear for an element fully answered by another user")
        XCTAssertTrue(element(app, id: A11yID.LongForm.alreadyAnsweredMessage).exists,
                      "Already-answered message text not found")
        XCTAssertFalse(element(app, id: A11yID.LongForm.submitButton).exists,
                       "LongForm shown despite the element being fully answered by someone else")

        element(app, id: A11yID.LongForm.alreadyAnsweredOKButton).tap()
        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 10),
                      "Did not return to the Map screen after dismissing the already-answered message")
    }

    // MARK: - Network on/off

    /// The freshness fetch failing must not hang the sheet or crash it - LongForm falls
    /// back to whatever tags the map data already had (blank, for 121949), not to the
    /// online-only asphalt/36 prefill from testOpeningFormPrefillsFromFreshlyFetched
    /// TagsNotStaleMapData.
    func testNetworkDownDuringFreshnessFetchFallsBackToCachedTags() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormNetworkDown)
        XCTAssertTrue(openForm(app, elementID: 121949), "Form did not open despite the freshness fetch failing")
        let scrollView = scroll(in: app)

        let asphalt = element(app, id: A11yID.LongForm.option(questID: 101, value: "asphalt"))
        XCTAssertTrue(scrollFormToElement(asphalt, in: scrollView), "Surface option not reachable")
        XCTAssertTrue(asphalt.label.hasSuffix("option unselected"),
                      "Surface incorrectly prefilled despite the freshness fetch failing - label: \(asphalt.label)")
    }

    /// Submitting always persists locally and returns immediately (QuestProtocols
    /// .updateTags's own doc comment: "whether or not there's connectivity") - offline,
    /// the answer must queue rather than being lost, reflected in the sync button's
    /// badge, and stay queued across a retry while the network is still down.
    func testOfflineSubmissionQueuesAnswerForLaterSync() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormNetworkDown)
        XCTAssertTrue(openForm(app, elementID: 409893), "Form did not open")
        let scrollView = scroll(in: app)

        let markingsNo = element(app, id: A11yID.LongForm.option(questID: 201, value: "no"))
        XCTAssertTrue(scrollFormToElement(markingsNo, in: scrollView), "Markings option not reachable")
        markingsNo.tap()

        let submit = element(app, id: A11yID.LongForm.submitButton)
        XCTAssertTrue(scrollFormToElement(submit, in: scrollView), "Submit button not reachable")
        submit.tap()

        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 10),
                      "Map toolbar did not reappear after submitting offline")

        let sync = element(app, id: A11yID.Map.syncButton)
        XCTAssertTrue(waitUntil(timeout: 15) { (sync.value as? String)?.contains("pending") == true },
                      "Sync badge never showed the offline answer as pending")

        // Retrying while still offline must not lose or falsely clear the pending answer.
        sync.tap()
        XCTAssertTrue(waitUntil(timeout: 10) { (sync.value as? String)?.contains("pending") == true },
                      "Pending answer disappeared from the sync badge despite the network staying down")
    }

    /// longFormNetworkRecovers fails only the FIRST changeset/create attempt - the one
    /// Submit's own initial drain makes - so the badge should already read "pending" by
    /// the time the sheet closes, and a manual sync retry (which hits the now-succeeding
    /// stub) should clear it.
    func testSyncButtonRetriesAndClearsQueueOnceNetworkRecovers() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormNetworkRecovers)
        XCTAssertTrue(openForm(app, elementID: 409893), "Form did not open")
        let scrollView = scroll(in: app)

        let markingsNo = element(app, id: A11yID.LongForm.option(questID: 201, value: "no"))
        XCTAssertTrue(scrollFormToElement(markingsNo, in: scrollView), "Markings option not reachable")
        markingsNo.tap()

        let submit = element(app, id: A11yID.LongForm.submitButton)
        XCTAssertTrue(scrollFormToElement(submit, in: scrollView), "Submit button not reachable")
        submit.tap()

        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 10),
                      "Map toolbar did not reappear after submitting")

        let sync = element(app, id: A11yID.Map.syncButton)
        XCTAssertTrue(waitUntil(timeout: 15) { (sync.value as? String)?.contains("pending") == true },
                      "Sync badge never showed the answer as pending after its first attempt failed")

        sync.tap()

        XCTAssertTrue(waitUntil(timeout: 20) { (sync.value as? String ?? "").isEmpty },
                      "Sync badge did not clear after the network recovered and sync was retried")
    }

    // MARK: - Navigation

    /// MapView hides its own navigation bar (.navigationBarHidden(isPresented)) for as
    /// long as the quest sheet is up, so Profile is not reachable mid-form - confirmed
    /// directly on a real run before writing this. It becomes reachable again, and the
    /// map is still intact, once the form is dismissed.
    func testMapToolbarHiddenWhileFormIsOpenAndReappearsAfterDismiss() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormOnline)
        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).exists,
                      "Map toolbar not present before opening the form")

        XCTAssertTrue(openForm(app, elementID: 121949), "Form did not open")
        XCTAssertFalse(element(app, id: A11yID.Map.workspaceTitleButton).exists,
                       "Map toolbar still present while the quest form is open - Profile would be reachable mid-form")
        XCTAssertFalse(app.buttons[A11yID.Map.profileButton].exists,
                       "Profile button still present while the quest form is open")

        element(app, id: A11yID.LongForm.dismissButton).tap()
        XCTAssertTrue(element(app, id: A11yID.Map.workspaceTitleButton).waitForExistence(timeout: 10),
                      "Map toolbar did not reappear after dismissing the form")
    }

    // MARK: - Layout: overlap

    func testLongFormElementsDoNotOverlap() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormOnline)
        XCTAssertTrue(openForm(app, elementID: 409776), "Form did not open")
        let scrollView = scroll(in: app)

        // Compose Note / Ignore this quest share one HStack row - the exact case
        // LongForm.swift's own comment on composeNoteButton warns can make taps land
        // on the wrong button if List's default row styling isn't suppressed.
        let composeNote = element(app, id: A11yID.LongForm.composeNoteButton)
        let ignore = element(app, id: A11yID.LongForm.ignoreQuestButton)
        XCTAssertTrue(scrollFormToElement(composeNote, in: scrollView), "Compose Note button not reachable")
        assertNoOverlap([(composeNote, "Compose Note button"), (ignore, "Ignore this quest button")])

        // Quest 106's 4 MultipleChoice tiles share one LazyVGrid.
        let choiceTiles = ["choice_1", "choice_2", "choice_3", "choice_4"].map {
            (element(app, id: A11yID.LongForm.option(questID: 106, value: $0)), "Quest 106 choice \($0)")
        }
        XCTAssertTrue(scrollFormToElement(choiceTiles[0].0, in: scrollView), "Quest 106 choice tiles not reachable")
        assertNoOverlap(choiceTiles)
    }

    // MARK: - Layout: screen bounds

    func testLongFormElementsFitWithinScreenBounds() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormOnline)
        XCTAssertTrue(openForm(app, elementID: 409776), "Form did not open")
        let scrollView = scroll(in: app)
        let window = app.windows.firstMatch

        for (name, control) in longFormControls(app) {
            XCTAssertTrue(scrollFormToElement(control, in: scrollView, requireFullyOnScreen: true), "\(name) not reachable by scrolling")
            XCTAssertGreaterThanOrEqual(control.frame.minX, window.frame.minX, "\(name) extends past the left edge of the screen")
            XCTAssertLessThanOrEqual(control.frame.maxX, window.frame.maxX, "\(name) extends past the right edge of the screen")
            XCTAssertGreaterThanOrEqual(control.frame.minY, window.frame.minY, "\(name) extends past the top edge of the screen")
            XCTAssertLessThanOrEqual(control.frame.maxY, window.frame.maxY, "\(name) extends past the bottom edge of the screen")
        }
    }

    // MARK: - Layout: reachability, tap targets

    func testAllLongFormElementsReachableAndTappable() throws {
        let app = reachMapScreen(scenario: UITestScenario.longFormOnline)
        XCTAssertTrue(openForm(app, elementID: 409776), "Form did not open")
        let scrollView = scroll(in: app)

        for (name, control) in longFormControls(app) {
            XCTAssertTrue(scrollFormToElement(control, in: scrollView), "\(name) not reachable by scrolling")
            XCTAssertTrue(control.isHittable, "\(name) exists but is not tappable")
        }
    }
}
