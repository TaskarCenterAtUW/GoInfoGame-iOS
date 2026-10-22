//
//  QuestModelTests.swift
//  GoInfoGameTests
//
//  The long-form quest definition (decoded from the UI tests' WorkspaceDetailsWithQuests.json),
//  answer validation, "is this element fully answered?" (LongFormElement+Completion) and
//  LongFormViewModel - dependency visibility, prefill, clearing hidden answers and building the
//  tag dictionary that gets submitted.
//

import XCTest
@testable import GoInfoGame

private func decodeWorkspace(_ fixture: String = "WorkspaceDetailsWithQuests") throws -> Workspace {
    try JSONDecoder().decode(Workspace.self, from: MockHTTP.fixture(fixture))
}

private func quest(_ json: String) throws -> LongQuest {
    try JSONDecoder().decode(LongQuest.self, from: Data(json.utf8))
}

private func choice(_ value: String) -> QuestAnswerChoice {
    QuestAnswerChoice(value: value, choiceText: value, imageURL: nil, choiceFollowUp: nil)
}

// MARK: - Decoding

final class LongFormDecodingTests: XCTestCase {

    func testTheSharedWorkspaceFixtureDecodesIntoThreeElementTypes() throws {
        let workspace = try decodeWorkspace()
        XCTAssertEqual(workspace.id, 222)
        XCTAssertEqual(workspace.title, "Copy from Stage Kondapur Dataset")
        XCTAssertEqual(workspace.type, "osw")
        XCTAssertEqual(workspace.externalAppAccess, 1)
        XCTAssertFalse(workspace.overrideConflicts)

        let longForm = try XCTUnwrap(workspace.longFormQuest)
        XCTAssertEqual(longForm.version, "3.0.0")
        XCTAssertEqual(longForm.recencyPeriod, 36500)
        XCTAssertEqual(longForm.elements.map(\.elementType), ["Sidewalks", "Crossings", "Kerbs"])
        XCTAssertEqual(longForm.elements.map(\.quests.count), [7, 5, 3])
        XCTAssertEqual(longForm.elements[0].questQuery, "ways with (highway=footway and footway=sidewalk)")
        XCTAssertEqual(longForm.elements[2].elementTypeIcon, "kerb")
        XCTAssertEqual(longForm.featurePresets?.map(\.name), ["Bench", "Power Pole"])
        XCTAssertNil(longForm.customIcons)
    }

    func testQuestFieldsAreMappedFromTheirSnakeCaseKeys() throws {
        let sidewalks = try XCTUnwrap(try decodeWorkspace().longFormQuest?.elements.first)
        let surface = try XCTUnwrap(sidewalks.quests.first { $0.questID == 101 })
        XCTAssertEqual(surface.questType, .exclusiveChoice)
        XCTAssertEqual(surface.questTag, "ext:surface")
        XCTAssertEqual(surface.questAnswerChoices?.map(\.value), ["asphalt", "concrete", "paving_stones", "gravel", "other"])
        XCTAssertNotNil(surface.questAnswerChoices?.first?.imageURL)
        XCTAssertNil(surface.questAnswerDependency)

        let width = try XCTUnwrap(sidewalks.quests.first { $0.questID == 103 })
        XCTAssertEqual(width.questType, .numeric)
        XCTAssertEqual(width.questAnswerValidation?.min, 12)
        XCTAssertEqual(width.questAnswerValidation?.max, 240)
    }

    func testASingleDependencyObjectIsWrappedIntoAnArray() throws {
        let sidewalks = try XCTUnwrap(try decodeWorkspace().longFormQuest?.elements.first)
        let description = try XCTUnwrap(sidewalks.quests.first { $0.questID == 102 })
        XCTAssertEqual(description.questAnswerDependency?.count, 1)
        XCTAssertEqual(description.questAnswerDependency?.first?.questionID, 101)
        guard case .string(let required)? = description.questAnswerDependency?.first?.requiredValue else { return XCTFail("expected a string") }
        XCTAssertEqual(required, "other")
    }

    func testADependencyArrayIsKept() throws {
        let crossings = try XCTUnwrap(try decodeWorkspace().longFormQuest?.elements[1])
        let features = try XCTUnwrap(crossings.quests.first { $0.questID == 203 })
        XCTAssertEqual(features.questAnswerDependency?.count, 1)
        XCTAssertEqual(features.questAnswerDependency?.first?.questionID, 202)

        let multi = try quest(#"{"quest_id":1,"quest_title":"t","quest_description":"d","quest_answer_dependency":[{"question_id":2,"required_value":"a"},{"question_id":3,"required_value":["x","y"]}]}"#)
        XCTAssertEqual(multi.questAnswerDependency?.count, 2)
        guard case .array(let values)? = multi.questAnswerDependency?.last?.requiredValue else { return XCTFail("expected an array") }
        XCTAssertEqual(values, ["x", "y"])
    }

    func testUnknownOrMissingOptionalFieldsDecodeAsNil() throws {
        let q = try quest(#"{"quest_id":9,"quest_title":"t","quest_description":"d","quest_type":"HologramChoice"}"#)
        XCTAssertNil(q.questType, "an unrecognised quest_type is dropped, not fatal")
        XCTAssertNil(q.questTag)
        XCTAssertNil(q.questAnswerChoices)
        XCTAssertNil(q.questAnswerDependency)
        XCTAssertNil(q.questAnswerValidation)
        XCTAssertNil(q.autoCaptureAttributes)
        XCTAssertNil(q.questImageURL)
    }

    func testMissingRequiredFieldsFailTheDecode() {
        XCTAssertThrowsError(try quest(#"{"quest_title":"t","quest_description":"d"}"#))
    }

    func testAutoCaptureAttributesAreDecoded() throws {
        let q = try quest(#"{"quest_id":5,"quest_title":"t","quest_description":"d","quest_type":"AutoCapture","auto_capture_attributes":{"a":"ext:a","b":"ext:b"}}"#)
        XCTAssertEqual(q.questType, .autoCapture)
        XCTAssertEqual(q.autoCaptureAttributes, ["a": "ext:a", "b": "ext:b"])
    }

    func testRequiredValueRoundTripsBothShapesAndRejectsOthers() throws {
        let string = try JSONDecoder().decode(RequiredValue.self, from: Data(#""yes""#.utf8))
        let array = try JSONDecoder().decode(RequiredValue.self, from: Data(#"["a","b"]"#.utf8))
        XCTAssertEqual(String(decoding: try JSONEncoder().encode(string), as: UTF8.self), #""yes""#)
        XCTAssertEqual(String(decoding: try JSONEncoder().encode(array), as: UTF8.self), #"["a","b"]"#)
        XCTAssertThrowsError(try JSONDecoder().decode(RequiredValue.self, from: Data("42".utf8)))
    }

    func testVoiceOverTitlesSayHowManyAnswersAreAllowed() throws {
        let sidewalks = try XCTUnwrap(try decodeWorkspace().longFormQuest?.elements.first)
        let exclusive = try XCTUnwrap(sidewalks.quests.first { $0.questID == 101 })
        let multiple = try XCTUnwrap(sidewalks.quests.first { $0.questID == 106 })
        let text = try XCTUnwrap(sidewalks.quests.first { $0.questID == 107 })
        XCTAssertEqual(exclusive.getQuestTitleVoiceOver(), exclusive.questTitle + "Only one item can be selected.")
        XCTAssertEqual(multiple.getQuestTitleVoiceOver(), multiple.questTitle + "Multiple items can be selected.")
        XCTAssertEqual(text.getQuestTitleVoiceOver(), text.questTitle)
    }

    func testTheResponseAcceptsABareTopLevelArrayAndAppliesDefaults() throws {
        let bare = try JSONDecoder().decode(LongFormResponse.self, from: Data(#"[{"element_type":"Sidewalks","quest_query":"ways with (a=b)","quests":[]}]"#.utf8))
        XCTAssertEqual(bare.elements.count, 1)
        XCTAssertNil(bare.version)
        XCTAssertEqual(bare.recencyPeriod, 90)
        XCTAssertNil(bare.featurePresets)

        let wrapped = try JSONDecoder().decode(LongFormResponse.self, from: Data(#"{"elements":[]}"#.utf8))
        XCTAssertEqual(wrapped.recencyPeriod, 90, "recency_period defaults to 90 days when the workspace doesn't set one")
    }

    func testFeaturePresetsAndCustomIconsDecode() throws {
        let json = #"{"elements":[],"feature-presets":[{"name":"Bench","icon":"bench","tags":{"amenity":"bench"}}],"custom-icons":[{"name":"x","url":"https://i/x.png","type":"png"}]}"#
        let response = try JSONDecoder().decode(LongFormResponse.self, from: Data(json.utf8))
        XCTAssertEqual(response.featurePresets?.first?.tags, ["amenity": "bench"])
        XCTAssertEqual(response.customIcons?.first, CustomIcon(name: "x", url: "https://i/x.png", type: "png"))
        let a = FeaturePreset(name: "Bench", icon: "bench", tags: ["amenity": "bench"])
        let b = FeaturePreset(name: "Bench", icon: "bench", tags: ["amenity": "bench"])
        XCTAssertEqual(a, b, "presets compare by content, not by their per-instance UUID")
        XCTAssertNotEqual(a.id, b.id)
    }

    func testTheWorkspaceModelAppliesItsDefaults() throws {
        let minimal = try JSONDecoder().decode(Workspace.self, from: Data(#"{"id":1,"title":"T","externalAppAccess":0}"#.utf8))
        XCTAssertEqual(minimal.type, "osw")
        XCTAssertFalse(minimal.overrideConflicts)
        XCTAssertNil(minimal.longFormQuest)
        XCTAssertNil(minimal.imageryList)
        XCTAssertNil(minimal.createdDateDisplay)
    }

    func testWorkspaceDatesAreFormattedWithOrWithoutFractionalSeconds() throws {
        func display(_ createdAt: String) throws -> String? {
            try JSONDecoder().decode(Workspace.self, from: Data(#"{"id":1,"title":"T","externalAppAccess":1,"createdAt":"\#(createdAt)"}"#.utf8)).createdDateDisplay
        }
        XCTAssertEqual(try display("2025-09-12T12:27:22.679Z"), try display("2025-09-12T12:27:22Z"))
        XCTAssertNotNil(try display("2025-09-12T12:27:22Z"))
        XCTAssertNil(try display("not a date"))
    }

    func testImageryAndProjectGroupModels() throws {
        let workspace = try decodeWorkspace()
        let server = try XCTUnwrap(workspace.imageryList?.first)
        XCTAssertEqual(server.id, "EsriWorldImageryClarity")
        XCTAssertTrue(server.attribution.attributionRequired)
        XCTAssertEqual(server.extent.maxZoom, 19)

        let roles = try JSONDecoder().decode([ProjectGroupRole].self, from: MockHTTP.fixture("ProjectGroupRoles"))
        XCTAssertEqual(roles.first?.projectGroupName, "AA Viewer Internal")
        XCTAssertEqual(roles.first?.tdeiProjectGroupId, "1ec1c79b-6b7a-4011-936b-c75dbbd903e3")
    }

    func testTheWorkspaceListFixtureDecodes() throws {
        let list = try JSONDecoder().decode([Workspace].self, from: MockHTTP.fixture("WorkspacesList"))
        let raw = try XCTUnwrap(MockHTTP.fixtureJSON("WorkspacesList") as? [[String: Any]])
        XCTAssertEqual(list.count, raw.count)
        XCTAssertEqual(list.count, 119)
        XCTAssertEqual(list.filter { $0.externalAppAccess == 1 }.count, raw.filter { ($0["externalAppAccess"] as? Int) == 1 }.count)
        XCTAssertEqual(Set(list.map(\.id)).count, list.count, "workspace ids are unique")
        XCTAssertTrue(list.contains { $0.id == 222 && $0.title == "Copy from Stage Kondapur Dataset" })
    }
}

// MARK: - Answer validation

final class QuestAnswerValidationTests: XCTestCase {

    private func validation(min: Int?, max: Int?) -> QuestAnswerValidation {
        try! JSONDecoder().decode(QuestAnswerValidation.self, from: Data("{\(min.map { "\"min\":\($0)" } ?? ""),\(max.map { "\"max\":\($0)" } ?? "")}".replacingOccurrences(of: "{,", with: "{").replacingOccurrences(of: ",}", with: "}").utf8))
    }

    func testEmptyInputIsNeverAnError() {
        XCTAssertNil(validation(min: 1, max: 10).errorMessage(forRawValue: ""))
    }

    func testNonNumbersAreRejected() {
        XCTAssertEqual(validation(min: 1, max: 10).errorMessage(forRawValue: "abc"), "Please enter a valid number.")
        XCTAssertEqual(validation(min: nil, max: nil).errorMessage(forRawValue: "1.2.3"), "Please enter a valid number.")
    }

    func testBoundsAreInclusive() {
        let v = validation(min: 12, max: 240)
        XCTAssertNil(v.errorMessage(forRawValue: "12"))
        XCTAssertNil(v.errorMessage(forRawValue: "240"))
        XCTAssertNil(v.errorMessage(forRawValue: "36.5"))
        XCTAssertEqual(v.errorMessage(forRawValue: "11.99"), "Value must be between 12 and 240.")
        XCTAssertEqual(v.errorMessage(forRawValue: "241"), "Value must be between 12 and 240.")
    }

    func testOneSidedBoundsHaveTheirOwnMessages() {
        XCTAssertEqual(validation(min: 5, max: nil).errorMessage(forRawValue: "4"), "Value must be at least 5.")
        XCTAssertNil(validation(min: 5, max: nil).errorMessage(forRawValue: "1000"))
        XCTAssertEqual(validation(min: nil, max: 9).errorMessage(forRawValue: "10"), "Value must be at most 9.")
        XCTAssertNil(validation(min: nil, max: 9).errorMessage(forRawValue: "-100"))
    }

    func testNegativeNumbersAndBoundsWork() {
        XCTAssertNil(validation(min: -10, max: 10).errorMessage(forRawValue: "-3"))
        XCTAssertNotNil(validation(min: -10, max: 10).errorMessage(forRawValue: "-11"))
    }
}

// MARK: - "Fully answered?" (LongFormElement+Completion)

final class LongFormCompletionTests: AppTestCase {

    private var sidewalks: LongFormElement!
    private var crossings: LongFormElement!
    private var kerbs: LongFormElement!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let elements = try XCTUnwrap(try decodeWorkspace().longFormQuest?.elements)
        sidewalks = elements[0]; crossings = elements[1]; kerbs = elements[2]
    }

    /// Everything a Sidewalks element needs when the surface isn't "other" and there is no obstruction.
    private let answeredSidewalk: [String: String] = [
        "ext:text_entry": "Done", "ext:component:quest_type-MultipleChoice": "choice_2",
        "ext:surface": "asphalt", "width": "48", "ext:obstruction": "no"
    ]

    func testTheFullyAnsweredFixtureElementIsComplete() {
        // way 900001 in LongFormOSMElements.json - "fully answered, must show no pin".
        let tags = DatabaseConnector.shared.seedAndTags(id: 900001, in: self)
        XCTAssertTrue(sidewalks.isFullyAnswered(tags: tags, isAutoCaptureCapable: false))
    }

    func testABlankElementIsNotComplete() {
        XCTAssertFalse(sidewalks.isFullyAnswered(tags: ["highway": "footway"], isAutoCaptureCapable: false))
    }

    func testEveryApplicableQuestMustBeAnswered() {
        XCTAssertTrue(sidewalks.isFullyAnswered(tags: answeredSidewalk, isAutoCaptureCapable: false))
        for key in answeredSidewalk.keys {
            var partial = answeredSidewalk
            partial.removeValue(forKey: key)
            XCTAssertFalse(sidewalks.isFullyAnswered(tags: partial, isAutoCaptureCapable: false), "missing \(key)")
            partial[key] = ""
            XCTAssertFalse(sidewalks.isFullyAnswered(tags: partial, isAutoCaptureCapable: false), "empty \(key)")
        }
    }

    func testDependentQuestsCountOnlyWhenTheirParentAnswerTriggersThem() {
        var other = answeredSidewalk
        other["ext:surface"] = "other"
        XCTAssertFalse(sidewalks.isFullyAnswered(tags: other, isAutoCaptureCapable: false), "'other' surface needs its description")
        other["ext:surface:description"] = "cobbles"
        XCTAssertTrue(sidewalks.isFullyAnswered(tags: other, isAutoCaptureCapable: false))

        var obstructed = answeredSidewalk
        obstructed["ext:obstruction"] = "yes"
        XCTAssertFalse(sidewalks.isFullyAnswered(tags: obstructed, isAutoCaptureCapable: false), "an obstruction needs its type")
        obstructed["ext:obstruction:type"] = "bollard;pole"
        XCTAssertTrue(sidewalks.isFullyAnswered(tags: obstructed, isAutoCaptureCapable: false))
    }

    func testAStaleAnswerToAHiddenFollowUpDoesNotMatter() {
        var tags = answeredSidewalk   // obstruction == "no"
        tags["ext:obstruction:type"] = "bollard"
        XCTAssertTrue(sidewalks.isFullyAnswered(tags: tags, isAutoCaptureCapable: false))
    }

    func testOtherElementTypes() {
        XCTAssertFalse(kerbs.isFullyAnswered(tags: ["kerb": "raised", "tactile_paving": "yes"], isAutoCaptureCapable: false), "raised kerbs need a height")
        XCTAssertTrue(kerbs.isFullyAnswered(tags: ["kerb": "raised", "tactile_paving": "yes", "height": "4"], isAutoCaptureCapable: false))
        XCTAssertTrue(kerbs.isFullyAnswered(tags: ["kerb": "flush", "tactile_paving": "no"], isAutoCaptureCapable: false))
        XCTAssertFalse(crossings.isFullyAnswered(tags: ["crossing:markings": "yes"], isAutoCaptureCapable: false))
    }

    func testAnArrayDependencyIsSatisfiedByAnyOfTheValues() throws {
        let json = """
        {"element_type":"X","quest_query":"ways with (a=b)","quests":[
          {"quest_id":1,"quest_title":"parent","quest_description":"d","quest_type":"MultipleChoice","quest_tag":"p"},
          {"quest_id":2,"quest_title":"child","quest_description":"d","quest_type":"TextEntry","quest_tag":"c",
           "quest_answer_dependency":{"question_id":1,"required_value":["x","y"]}}]}
        """
        let element = try JSONDecoder().decode(LongFormElement.self, from: Data(json.utf8))
        XCTAssertTrue(element.isFullyAnswered(tags: ["p": "z"], isAutoCaptureCapable: false), "no x/y chosen -> child hidden")
        XCTAssertFalse(element.isFullyAnswered(tags: ["p": "z;y"], isAutoCaptureCapable: false), "y chosen -> child required")
        XCTAssertTrue(element.isFullyAnswered(tags: ["p": "z;y", "c": "ok"], isAutoCaptureCapable: false))
        XCTAssertFalse(element.isFullyAnswered(tags: [:], isAutoCaptureCapable: false), "the parent question itself still needs an answer")
    }

    func testAutoCaptureOnlyBlocksDevicesThatCanRunIt() throws {
        let json = """
        {"element_type":"X","quest_query":"ways with (a=b)","quests":[
          {"quest_id":1,"quest_title":"scan","quest_description":"d","quest_type":"AutoCapture","auto_capture_attributes":{"w":"ext:w","h":"ext:h"}}]}
        """
        let element = try JSONDecoder().decode(LongFormElement.self, from: Data(json.utf8))
        XCTAssertTrue(element.isFullyAnswered(tags: [:], isAutoCaptureCapable: false), "a device without LiDAR can't be asked to scan")
        XCTAssertFalse(element.isFullyAnswered(tags: [:], isAutoCaptureCapable: true))
        XCTAssertTrue(element.isFullyAnswered(tags: ["ext:h": "3"], isAutoCaptureCapable: true), "any one captured attribute counts")
        XCTAssertFalse(element.isFullyAnswered(tags: ["ext:h": ""], isAutoCaptureCapable: true))
    }

    func testAQuestWithoutATagCannotBlockCompletion() throws {
        let json = #"{"element_type":"X","quest_query":"ways with (a=b)","quests":[{"quest_id":1,"quest_title":"t","quest_description":"d","quest_type":"TextEntry"}]}"#
        let element = try JSONDecoder().decode(LongFormElement.self, from: Data(json.utf8))
        XCTAssertTrue(element.isFullyAnswered(tags: [:], isAutoCaptureCapable: false))
    }

    func testTheDeviceDefaultComesFromLiDARDetection() {
        // Called without the explicit flag, as the app does; the answer is device specific but must not crash.
        _ = sidewalks.isFullyAnswered(tags: answeredSidewalk)
        _ = LiDARDetection.shared.isLiDARSupported()
    }
}

private extension DatabaseConnector {
    /// Seeds the shared fixture and returns the stored tags of one element.
    func seedAndTags(id: Int, in test: AppTestCase) -> [String: String] {
        test.seedMap("LongFormOSMElements")
        return getWay(id: id)?.tags.toDictionary() ?? [:]
    }
}

// MARK: - LongFormViewModel

final class LongFormViewModelTests: XCTestCase {

    private var model: LongFormViewModel!
    private var sidewalks: LongFormElement!
    private var kerbs: LongFormElement!
    private var crossings: LongFormElement!

    override func setUpWithError() throws {
        let elements = try XCTUnwrap(try decodeWorkspace().longFormQuest?.elements)
        sidewalks = elements[0]; crossings = elements[1]; kerbs = elements[2]
        model = LongFormViewModel()
        model.longForm = sidewalks
    }

    private func q(_ id: Int, in element: LongFormElement? = nil) -> LongQuest {
        (element ?? sidewalks).quests.first { $0.questID == id }!
    }

    // MARK: Visibility

    func testQuestsWithoutDependenciesAreAlwaysShown() {
        XCTAssertTrue(model.shouldShowQuest(q(101)))
        XCTAssertTrue(model.shouldShowQuest(q(107)))
    }

    func testAFollowUpAppearsOnlyForTheTriggeringAnswer() {
        XCTAssertFalse(model.shouldShowQuest(q(102)))
        model.selectedChoices[101] = choice("asphalt")
        XCTAssertFalse(model.shouldShowQuest(q(102)))
        model.selectedChoices[101] = choice("other")
        XCTAssertTrue(model.shouldShowQuest(q(102)))
        model.selectedChoices[101] = .some(nil)
        XCTAssertFalse(model.shouldShowQuest(q(102)), "a cleared parent hides the follow-up")
    }

    func testMultipleChoiceAnswersAreCommaSeparatedWhenChecked() throws {
        let features = q(203, in: crossings)
        model.longForm = crossings
        model.selectedChoices[202] = choice("no")
        XCTAssertFalse(model.shouldShowQuest(features))
        model.selectedChoices[202] = choice("yes")
        XCTAssertTrue(model.shouldShowQuest(features))

        let dep = QuestAnswerDependency(questionID: 1, requiredValue: .string("b"))
        model.selectedChoices[1] = choice("a, b, c")
        XCTAssertTrue(model.checkDependency(dep))
        model.selectedChoices[1] = choice("a, c")
        XCTAssertFalse(model.checkDependency(dep))
        model.selectedChoices[1] = choice("")
        XCTAssertFalse(model.checkDependency(dep), "an empty answer satisfies nothing")
    }

    func testAnArrayRequirementNeedsAnyOverlap() {
        let dep = QuestAnswerDependency(questionID: 1, requiredValue: .array(["x", "y"]))
        model.selectedChoices[1] = choice("z, y")
        XCTAssertTrue(model.checkDependency(dep))
        model.selectedChoices[1] = choice("z, w")
        XCTAssertFalse(model.checkDependency(dep))
        XCTAssertFalse(model.checkDependency(QuestAnswerDependency(questionID: 99, requiredValue: .string("x"))), "never answered")
    }

    func testAQuestWithSeveralDependenciesNeedsAllOfThem() throws {
        let json = #"{"quest_id":5,"quest_title":"t","quest_description":"d","quest_answer_dependency":[{"question_id":1,"required_value":"a"},{"question_id":2,"required_value":"b"}]}"#
        let multi = try quest(json)
        model.selectedChoices[1] = choice("a")
        XCTAssertFalse(model.shouldShowQuest(multi))
        model.selectedChoices[2] = choice("b")
        XCTAssertTrue(model.shouldShowQuest(multi))
        model.selectedChoices[1] = choice("nope")
        XCTAssertFalse(model.shouldShowQuest(multi))
    }

    // MARK: Prefill

    func testPrefillSeedsAnswersFromExistingTags() {
        model.prefillAnswers(tags: ["ext:surface": "concrete", "width": "36", "ext:text_entry": "hello",
                                    "ext:component:quest_type-MultipleChoice": "choice_1;choice_3"])

        XCTAssertEqual(model.selectedChoices[101]??.value, "concrete")
        XCTAssertEqual(model.selectedChoices[103]??.value, "36")
        XCTAssertEqual(model.selectedChoices[107]??.value, "hello")
        XCTAssertEqual(model.selectedChoices[106]??.value, "choice_1;choice_3")
        XCTAssertNil(model.selectedChoices[104], "no tag -> no answer")
    }

    func testPrefillReusesTheExactChoiceObjectSoItsHighlightedAsSelected() throws {
        model.prefillAnswers(tags: ["ext:surface": "gravel"])
        let original = try XCTUnwrap(q(101).questAnswerChoices?.first { $0.value == "gravel" })
        XCTAssertEqual(model.selectedChoices[101]??.id, original.id, "QuestAnswerChoice's Equatable includes its per-instance UUID")
        XCTAssertEqual(model.selectedChoices[101]!, original)
    }

    func testPrefillIgnoresUnknownChoicesAndEmptyValues() {
        model.prefillAnswers(tags: ["ext:surface": "lava", "width": "", "ext:obstruction": ""])
        XCTAssertNil(model.selectedChoices[101], "a value that isn't one of the configured choices")
        XCTAssertNil(model.selectedChoices[103])
        XCTAssertNil(model.selectedChoices[104])
    }

    func testPrefillSkipsAutoCaptureAndHandlesNoLongForm() throws {
        let element = try JSONDecoder().decode(LongFormElement.self, from: Data(#"{"element_type":"X","quest_query":"q","quests":[{"quest_id":1,"quest_title":"t","quest_description":"d","quest_type":"AutoCapture","quest_tag":"ext:scan"}]}"#.utf8))
        model.longForm = element
        model.prefillAnswers(tags: ["ext:scan": "1"])
        XCTAssertTrue(model.selectedChoices.isEmpty)

        let bare = LongFormViewModel()
        bare.prefillAnswers(tags: ["a": "b"])
        XCTAssertTrue(bare.selectedChoices.isEmpty)
    }

    // MARK: Clearing hidden answers

    func testChangingAParentClearsItsNowHiddenFollowUp() {
        model.selectedChoices[104] = choice("yes")
        model.selectedChoices[105] = choice("bollard")
        model.clearAnswersForHiddenQuests()
        XCTAssertEqual(model.selectedChoices[105]??.value, "bollard", "still visible, so untouched")

        model.selectedChoices[104] = choice("no")
        model.clearAnswersForHiddenQuests()
        XCTAssertTrue(model.selectedChoices.keys.contains(105), "the key stays so the removal reaches the server")
        XCTAssertNil(model.selectedChoices[105] ?? nil, "but its answer is gone")
        XCTAssertEqual(model.selectedChoices[104]??.value, "no")

        model.clearAnswersForHiddenQuests()    // idempotent
        XCTAssertTrue(model.selectedChoices.keys.contains(105))
    }

    func testClearingWithoutALongFormDoesNothing() {
        let bare = LongFormViewModel()
        bare.clearAnswersForHiddenQuests()
        XCTAssertNil(bare.validationErrorMessage())
        XCTAssertTrue(bare.getAnswersForSubmission().isEmpty)
    }

    // MARK: Validation

    func testValidationReportsTheFirstOutOfRangeAnswer() throws {
        model.selectedChoices[103] = choice("5")
        let message = try XCTUnwrap(model.validationErrorMessage())
        XCTAssertEqual(message, "\(q(103).questTitle): Value must be between 12 and 240.")
        model.selectedChoices[103] = choice("100")
        XCTAssertNil(model.validationErrorMessage())
        model.selectedChoices[103] = choice("abc")
        XCTAssertTrue(model.validationErrorMessage()?.hasSuffix("Please enter a valid number.") == true)
    }

    func testHiddenAndUnansweredQuestsAreNotValidated() {
        model.longForm = kerbs
        model.selectedChoices[303] = choice("99")      // out of range, but its parent isn't 'raised'
        XCTAssertNil(model.validationErrorMessage())
        model.selectedChoices[301] = choice("raised")
        XCTAssertNotNil(model.validationErrorMessage(), "now the height is visible and invalid")
        model.selectedChoices[303] = .some(nil)
        XCTAssertNil(model.validationErrorMessage(), "a cleared answer is not an error")
    }

    // MARK: Building the submission

    func testSubmissionContainsOneTagPerAnsweredVisibleQuest() {
        model.selectedChoices[101] = choice("concrete")
        model.selectedChoices[103] = choice("40")
        model.selectedChoices[104] = choice("no")
        model.selectedChoices[107] = choice("note")
        XCTAssertEqual(model.getAnswersForSubmission(), ["ext:surface": "concrete", "width": "40", "ext:obstruction": "no", "ext:text_entry": "note"])
    }

    func testAnAnswerToAHiddenQuestIsLeftOut() {
        model.selectedChoices[101] = choice("asphalt")
        model.selectedChoices[102] = choice("stale description")     // 102 only applies to 'other'
        XCTAssertNil(model.getAnswersForSubmission()["ext:surface:description"])
    }

    func testAClearedQuestIsSubmittedAsAnEmptyTagSoItIsRemoved() {
        model.selectedChoices[101] = .some(nil)
        XCTAssertEqual(model.getAnswersForSubmission()["ext:surface"], "")
    }

    func testAClearedHiddenFollowUpStillReachesTheServerAsARemoval() {
        model.selectedChoices[104] = choice("yes")
        model.selectedChoices[105] = choice("pole")
        model.selectedChoices[104] = choice("no")
        model.clearAnswersForHiddenQuests()
        let submission = model.getAnswersForSubmission()
        XCTAssertEqual(submission["ext:obstruction"], "no")
        XCTAssertEqual(submission["ext:obstruction:type"], "")
    }

    func testAutoCaptureAnswersAreExpandedIntoTagsAndFlagged() throws {
        let element = try JSONDecoder().decode(LongFormElement.self, from: Data(#"{"element_type":"X","quest_query":"q","quests":[{"quest_id":1,"quest_title":"t","quest_description":"d","quest_type":"AutoCapture"}]}"#.utf8))
        model.longForm = element

        model.selectedChoices[1] = choice("ext:w=10|ext:h=2||ext:w=14|ext:h=4")
        let captured = model.getAnswersForSubmission()
        XCTAssertEqual(captured["ext:w"], "10,14")
        XCTAssertEqual(captured["ext:h"], "2,4")
        XCTAssertEqual(captured["ext:autoCapture:ignored"], "no")

        model.selectedChoices[1] = choice("   ")
        XCTAssertEqual(model.getAnswersForSubmission(), ["ext:autoCapture:ignored": "yes"], "an empty capture counts as skipped")

        model.selectedChoices[1] = .some(nil)
        XCTAssertTrue(model.getAnswersForSubmission().isEmpty, "a cleared auto-capture adds nothing")

        model.selectedChoices.removeAll()
        let untouched = model.getAnswersForSubmission()
        if LiDARDetection.shared.isLiDARSupported() {
            XCTAssertEqual(untouched, ["ext:autoCapture:ignored": "yes"])
        } else {
            XCTAssertTrue(untouched.isEmpty)
        }
    }

    func testMalformedAutoCapturePairsAreSkipped() throws {
        let element = try JSONDecoder().decode(LongFormElement.self, from: Data(#"{"element_type":"X","quest_query":"q","quests":[{"quest_id":1,"quest_title":"t","quest_description":"d","quest_type":"AutoCapture"}]}"#.utf8))
        model.longForm = element
        model.selectedChoices[1] = choice("novalue|ext:a=1|=|ext:b=x=y")
        let answers = model.getAnswersForSubmission()
        XCTAssertEqual(answers["ext:a"], "1")
        XCTAssertEqual(answers["ext:b"], "x=y", "only the first '=' splits key from value")
        XCTAssertNil(answers["novalue"])
    }
}
