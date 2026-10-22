//
//  QuestRepositoryTests.swift
//  GoInfoGameTests
//
//  Which elements become quest pins and why: LongElementQuest.isApplicable (query match +
//  completeness + the recency window), AppQuestManager (turns the local element database into
//  pins), QuestsRepository, hidden quests and the map annotation types. Quest definitions and
//  elements are the UI tests' WorkspaceDetailsWithQuests.json and LongFormOSMElements.json.
//
//  Elements in LongFormOSMElements.json:
//    121949 blank sidewalk | 409777 partly answered sidewalk | 409776 partly answered sidewalk
//    409893 crossing       | 900001 fully answered sidewalk   | 900101 kerb node (barrier=kerb)
//

import XCTest
import CoreLocation
import osmparser
@testable import GoInfoGame

// MARK: - LongElementQuest

final class LongElementQuestTests: AppTestCase {

    private let db = DatabaseConnector.shared
    private var sidewalks: LongElementQuest!
    private var crossings: LongElementQuest!
    private var kerbs: LongElementQuest!

    override func setUp() {
        super.setUp()
        loadQuestsSync()
        seedMap("LongFormOSMElements")
        let quests = QuestsRepository.shared.allQuests.compactMap { $0.quest as? LongElementQuest }
        sidewalks = quests[0]; crossings = quests[1]; kerbs = quests[2]
    }

    private func way(_ id: Int) -> osmparser.Way { db.getWay(id: id)!.asWay() }
    private func node(_ id: Int) -> osmparser.Node { db.getNode(id: id)!.asNode() }

    // MARK: Applicability

    func testABlankSidewalkIsApplicableToTheSidewalkQuestOnly() {
        XCTAssertTrue(sidewalks.isApplicable(element: way(121949)))
        XCTAssertFalse(crossings.isApplicable(element: way(121949)))
        XCTAssertFalse(kerbs.isApplicable(element: way(121949)), "kerbs are node-only")
    }

    func testEachElementMatchesItsOwnQueryOnly() {
        XCTAssertTrue(crossings.isApplicable(element: way(409893)))
        XCTAssertFalse(sidewalks.isApplicable(element: way(409893)))
        XCTAssertTrue(kerbs.isApplicable(element: node(900101)))
        XCTAssertFalse(sidewalks.isApplicable(element: node(900101)), "a node never matches a 'ways with' query")
        XCTAssertFalse(kerbs.isApplicable(element: node(800010)), "an untagged geometry node matches nothing")
    }

    func testPartiallyAnsweredElementsStayApplicable() {
        XCTAssertTrue(sidewalks.isApplicable(element: way(409777)))
        XCTAssertTrue(sidewalks.isApplicable(element: way(409776)))
    }

    func testAFullyAnsweredElementIsNotApplicable() {
        XCTAssertFalse(sidewalks.isApplicable(element: way(900001)))
        XCTAssertTrue(sidewalks.isStillConsideredComplete(tags: way(900001).tags, lastEditedAt: Date()))
    }

    func testWithoutARecencyPeriodACompletedElementNeverComesBack() {
        QuestsRepository.shared.recencyPeriodDays = nil
        XCTAssertFalse(sidewalks.isApplicable(element: way(900001)))
        XCTAssertTrue(sidewalks.isStillConsideredComplete(tags: way(900001).tags, lastEditedAt: Date(timeIntervalSince1970: 0)))
    }

    func testACompletedElementReturnsOncePastTheRecencyWindow() {
        let element = way(900001)
        let edited = Date(timeIntervalSince1970: TimeInterval(element.timestampEdited))
        // Whole 24-hour periods since the edit - recency is elapsed time, not calendar days.
        let elapsedDays = Int(Date().timeIntervalSince(edited) / 86_400)
        XCTAssertGreaterThan(elapsedDays, 1, "the fixture element was last edited well in the past")

        QuestsRepository.shared.recencyPeriodDays = elapsedDays + 1
        XCTAssertFalse(sidewalks.isApplicable(element: element), "still inside the window, so it stays hidden")
        QuestsRepository.shared.recencyPeriodDays = elapsedDays
        XCTAssertTrue(sidewalks.isApplicable(element: element), "the window has just run out, so it needs re-answering")
        QuestsRepository.shared.recencyPeriodDays = 1
        XCTAssertTrue(sidewalks.isApplicable(element: element))
    }

    func testAZeroDayRecencyAlwaysBringsCompletedElementsBack() {
        let tags = way(900001).tags
        QuestsRepository.shared.recencyPeriodDays = 0
        XCTAssertFalse(sidewalks.isStillConsideredComplete(tags: tags, lastEditedAt: Date()), "even an edit made this instant")
        XCTAssertTrue(sidewalks.isApplicable(element: way(900001)))

        QuestsRepository.shared.recencyPeriodDays = -3   // a nonsensical value is treated like 0
        XCTAssertFalse(sidewalks.isStillConsideredComplete(tags: tags, lastEditedAt: Date()))
        XCTAssertTrue(sidewalks.isApplicable(element: way(900001)))
    }

    func testRecencyIsMeasuredInElapsedHoursNotCalendarDays() {
        let tags = way(900001).tags
        let hour: TimeInterval = 3_600
        func fresh(_ hoursAgo: Double) -> Bool {
            sidewalks.isStillConsideredComplete(tags: tags, lastEditedAt: Date().addingTimeInterval(-hoursAgo * hour))
        }

        // One recency day is exactly 24 hours from the edit, whatever the time of day or the time zone.
        QuestsRepository.shared.recencyPeriodDays = 1
        XCTAssertTrue(fresh(0))
        XCTAssertTrue(fresh(23.9), "less than 24 hours old is fresh even if it was edited on the previous calendar date")
        XCTAssertFalse(fresh(24.1), "more than 24 hours old needs re-answering")

        QuestsRepository.shared.recencyPeriodDays = 2
        XCTAssertTrue(fresh(47.9))
        XCTAssertFalse(fresh(48.1))
    }

    func testAnIncompleteElementIsNeverConsideredComplete() {
        XCTAssertFalse(sidewalks.isStillConsideredComplete(tags: way(121949).tags, lastEditedAt: Date()))
    }

    func testAnUnresolvableQueryCanNotBeVerifiedSoItIsNotComplete() {
        let orphan = LongElementQuest(questId: "x", questQuery: "ways with (some=other)", elementType: "Mystery", elementTypeIcon: nil)
        XCTAssertFalse(orphan.isStillConsideredComplete(tags: ["anything": "1"], lastEditedAt: Date()))
    }

    // MARK: Identity, icon and filter

    func testIconNamesFollowTheElementTypeUnlessOneIsConfigured() {
        XCTAssertEqual(LongElementQuest.iconName(elementType: "Sidewalks", elementTypeIcon: nil), "sidewalk_surface")
        XCTAssertEqual(LongElementQuest.iconName(elementType: "SIDEWALKS", elementTypeIcon: nil), "sidewalk_surface")
        XCTAssertEqual(LongElementQuest.iconName(elementType: "Crossings", elementTypeIcon: nil), "pedestrian")
        XCTAssertEqual(LongElementQuest.iconName(elementType: "Kerb", elementTypeIcon: nil), "kerb_type")
        XCTAssertEqual(LongElementQuest.iconName(elementType: "Benches", elementTypeIcon: nil), "notes")
        XCTAssertEqual(LongElementQuest.iconName(elementType: "Sidewalks", elementTypeIcon: "custom_icon"), "custom_icon")
        XCTAssertEqual(sidewalks.iconName, "sidewalk", "the workspace's configured element_type_icon wins")
        XCTAssertEqual(kerbs.iconName, "kerb")
    }

    func testTheFilterComesFromTheWorkspaceDefinition() {
        XCTAssertEqual(sidewalks.filter, "ways with (highway=footway and footway=sidewalk)")
        XCTAssertEqual(kerbs.filter, "nodes with (barrier=kerb)")
        XCTAssertEqual(sidewalks.elementType, "Sidewalks")
        XCTAssertNotNil(sidewalks.filterExpression)
        XCTAssertNotNil(sidewalks.filterExpression, "the parsed filter is cached")
    }

    func testCopyingForAnElementCarriesItsIdentityTagsAndGeometry() {
        let copy = sidewalks.copyWithElement(element: way(409776)) as! LongElementQuest
        XCTAssertEqual(copy.id, 409776)
        XCTAssertEqual(copy.type, .way)
        XCTAssertEqual(copy.tags?["ext:obstruction"], "yes")
        XCTAssertEqual(copy.polylines?.count, 2)
        XCTAssertEqual(copy.questId, "409776")
        XCTAssertEqual(copy.elementType, "Sidewalks")
        XCTAssertEqual(copy.filter, sidewalks.filter)

        let kerbCopy = kerbs.copyWithElement(element: node(900101)) as! LongElementQuest
        XCTAssertEqual(kerbCopy.type, .node)
        XCTAssertNil(kerbCopy.polylines)
    }

    func testTheDisplayUnitCarriesTheElementIdForTheMapPin() {
        let copy = sidewalks.copyWithElement(element: way(121949)) as! LongElementQuest
        let unit = copy.displayUnit
        XCTAssertEqual(unit.description, "121949", "UI tests read the pin's element id from here")
        XCTAssertEqual(unit.id, "121949-121949")
        XCTAssertEqual(unit.sheetSize, .LONGFORM)
        XCTAssertTrue(unit.parent is LongElementQuest)
        XCTAssertEqual(unit, copy.displayUnit)
    }

    // MARK: Form / answers

    func testRefreshingTagsRebuildsTheFormAndKeepsTheNewTags() {
        let copy = sidewalks.copyWithElement(element: way(121949)) as! LongElementQuest
        XCTAssertNotNil(copy.internalForm)
        copy.refreshTags(["ext:surface": "gravel"])
        XCTAssertEqual(copy.tags, ["ext:surface": "gravel"])
        _ = copy.form
    }

    func testMovingTheAnnotationRebuildsTheFormButAnUnchangedCoordinateDoesNot() {
        let copy = sidewalks.copyWithElement(element: way(121949)) as! LongElementQuest
        func formTags() -> [String: String]? { (copy.internalForm as? LongForm)?.tags }

        copy.annotationCoordinate = CLLocationCoordinate2D(latitude: 1, longitude: 2)
        let originalTags = formTags()
        copy.tags = ["marker": "changed-after-build"]

        copy.annotationCoordinate = CLLocationCoordinate2D(latitude: 1, longitude: 2)
        XCTAssertEqual(formTags(), originalTags, "the same coordinate must not discard the live form (and its answers)")

        copy.annotationCoordinate = CLLocationCoordinate2D(latitude: 3, longitude: 4)
        XCTAssertEqual(formTags(), ["marker": "changed-after-build"], "a moved annotation rebuilds the form from current tags")
        XCTAssertEqual((copy.internalForm as? LongForm)?.coordinate?.latitude, 3)
    }

    func testAnsweringTheFormForwardsToTheSelectionHandler() {
        let copy = sidewalks.copyWithElement(element: way(121949)) as! LongElementQuest
        var received: LongFormAnswer?
        copy.questAnswersSelected = { received = $0 }
        let form = copy.internalForm as! LongForm
        let answer = LongFormAnswer(tags: ["ext:surface": "gravel"], capturedImage: nil, imageTagKey: nil)
        form.action?(answer)
        XCTAssertEqual(received?.tags, ["ext:surface": "gravel"])
    }

    func testAnAnswerIsQueuedForSubmissionThroughOnAnswer() {
        MockServer.installChangesets()
        MockServer.installLatestElements()
        let copy = sidewalks.copyWithElement(element: way(121949)) as! LongElementQuest
        let events = recordSheetEvents()
        copy.onAnswer(answer: LongFormAnswer(tags: ["ext:surface": "concrete"], capturedImage: nil, imageTagKey: nil))
        waitUntil(timeout: 10, "the answer was never submitted") { events.contains("answerSynced") }
        waitUntil(timeout: 10, "the synced tags never reached the local copy") { db.getWay(id: 121949)?.tags["ext:surface"] == "concrete" }
        XCTAssertEqual(db.getWay(id: 121949)?.tags["ext:surface"], "concrete")
    }

    func testTheLatestTagsAreFetchedForTheElement() async {
        MockServer.installLatestElements()
        let copy = sidewalks.copyWithElement(element: way(121949)) as! LongElementQuest
        let latest = await copy.fetchLatestTagsIfNeeded()
        XCTAssertEqual(latest?.tags["ext:surface"], "asphalt")
        XCTAssertNotNil(latest?.timestamp)
    }

    func testMultiSelectModeStartsOff() {
        XCTAssertFalse(sidewalks.isMultiSelectMode)
        XCTAssertEqual(LongElementQuest().id, -1)
    }
}

// MARK: - AppQuestManager

final class AppQuestManagerTests: AppTestCase {

    private let db = DatabaseConnector.shared
    private let manager = AppQuestManager.shared

    override func setUp() {
        super.setUp()
        loadQuestsSync()
        seedMap("LongFormOSMElements")
    }

    private func pinIDs() -> Set<Int64> { Set(manager.fetchQuestsFromDB().map(\.id)) }

    func testOnlyUnansweredElementsBecomePins() {
        XCTAssertEqual(pinIDs(), [121949, 409777, 409776, 409893, 900101], "900001 is fully answered, so it has no pin")
    }

    func testEachPinIsPlacedAtItsElementsLocation() throws {
        let units = manager.fetchQuestsFromDB()
        let kerb = try XCTUnwrap(units.first { $0.id == 900101 })
        XCTAssertEqual(kerb.coordinateInfo.latitude, db.getNode(id: 900101)?.latitude ?? -1, accuracy: 1e-9)
        let sidewalk = try XCTUnwrap(units.first { $0.id == 121949 })
        let center = try XCTUnwrap(db.getCenterForWay(id: 121949))
        XCTAssertEqual(sidewalk.coordinateInfo.latitude, center.latitude, accuracy: 1e-9)
        XCTAssertFalse(sidewalk.isHidden)
        XCTAssertEqual((sidewalk.displayUnit.parent as? LongElementQuest)?.elementType, "Sidewalks")
        XCTAssertEqual((kerb.displayUnit.parent as? LongElementQuest)?.elementType, "Kerbs")
    }

    func testHiddenElementsHaveNoPin() {
        var items = manager.fetchQuestsFromDB()
        HiddenQuestManager.shared.hideQuest(elementId: "121949-1", elementName: "Sidewalk 121949", items: &items)
        XCTAssertFalse(pinIDs().contains(121949))
        HiddenQuestManager.shared.removeAllHiddenQuests()
        XCTAssertTrue(pinIDs().contains(121949))
    }

    func testElementsWithAnUnsyncedAnswerAreHeldBackUntilItSyncs() {
        db.createChangeset(id: 121949, questType: "Sidewalks", type: .way, originalTags: [:], tags: ["a": "b"], version: 1, iconName: "i")
        db.createChangeset(id: 900101, questType: "Kerbs", type: .node, originalTags: [:], tags: ["a": "b"], version: 1, iconName: "i")
        XCTAssertFalse(pinIDs().contains(121949))
        XCTAssertFalse(pinIDs().contains(900101))
        XCTAssertTrue(pinIDs().contains(409776), "other elements are unaffected")
    }

    func testTurningAQuestTypeOffRemovesItsPins() {
        var repo = QuestsRepository.shared.allQuests
        repo[0].isDefault = false   // Sidewalks
        QuestsRepository.shared.allQuests = repo
        XCTAssertEqual(pinIDs(), [409893, 900101])
        XCTAssertEqual(QuestsRepository.shared.applicableQuests.count, 2)
    }

    func testAMissingQuestDefinitionYieldsNoPins() {
        QuestsRepository.shared.allQuests = []
        XCTAssertTrue(manager.fetchQuestsFromDB().isEmpty)
    }

    func testRecheckingASingleElement() {
        XCTAssertEqual(manager.getUpdatedQuest(elementId: "121949")?.id, 121949)
        XCTAssertEqual(manager.getUpdatedQuest(elementId: "900101")?.id, 900101, "nodes work too")
        XCTAssertNil(manager.getUpdatedQuest(elementId: "900001"), "fully answered -> no pin")
        XCTAssertNil(manager.getUpdatedQuest(elementId: "424242"), "not in the database")
        XCTAssertNil(manager.getUpdatedQuest(elementId: "not-a-number"))
    }

    func testAnElementBecomesCompleteOnceItsLastAnswerIsStored() {
        XCTAssertNotNil(manager.getUpdatedQuest(elementId: "121949"))
        _ = db.addWayTags(id: 121949, tags: ["footway": "sidewalk", "highway": "footway", "ext:text_entry": "x",
                                             "ext:component:quest_type-MultipleChoice": "choice_1", "ext:surface": "asphalt",
                                             "width": "36", "ext:obstruction": "no"], version: 2, timestamp: Date())
        XCTAssertNil(manager.getUpdatedQuest(elementId: "121949"))
        XCTAssertFalse(pinIDs().contains(121949))
    }

    func testFindingTheQuestForAChangesetAfterAnUndo() {
        let wayChangeset = db.createChangeset(id: 121949, questType: "Sidewalks", type: .way, originalTags: [:], tags: ["a": "b"], version: 1, iconName: "i")!
        let nodeChangeset = db.createChangeset(id: 900101, questType: "Kerbs", type: .node, originalTags: [:], tags: ["a": "b"], version: 1, iconName: "i")!
        let completeChangeset = db.createChangeset(id: 900001, questType: "Sidewalks", type: .way, originalTags: [:], tags: ["a": "b"], version: 1, iconName: "i")!

        XCTAssertEqual(manager.fetchQuestForChangeset(storedChangesetId: wayChangeset.id)?.id, 121949)
        XCTAssertEqual(manager.fetchQuestForChangeset(storedChangesetId: nodeChangeset.id)?.id, 900101)
        XCTAssertNil(manager.fetchQuestForChangeset(storedChangesetId: completeChangeset.id), "nothing left to answer after the undo")
        XCTAssertNil(manager.fetchQuestForChangeset(storedChangesetId: "no-such-changeset"))
    }

    func testAChangesetWhoseElementIsGoneHasNoQuest() {
        let changeset = db.createChangeset(id: 31337, questType: "Sidewalks", type: .way, originalTags: [:], tags: ["a": "b"], version: 1, iconName: "i")!
        XCTAssertNil(manager.fetchQuestForChangeset(storedChangesetId: changeset.id))
    }
}

// MARK: - QuestsRepository & annotation types

final class QuestsRepositoryTests: AppTestCase {

    func testQuestDefinitionsLoadedFromTheWorkspaceFixture() {
        let workspace = loadQuestsSync()
        let repo = QuestsRepository.shared
        XCTAssertEqual(workspace?.id, 222)
        XCTAssertEqual(repo.allQuests.count, 3)
        XCTAssertEqual(repo.longQuestModels.count, 3, "MapView reloads the saved definitions from disk when it appears")
        XCTAssertEqual(repo.featurePresets.map(\.name), ["Bench", "Power Pole"])
        XCTAssertTrue(repo.customIcons.isEmpty)
        XCTAssertEqual(repo.recencyPeriodDays, 36500)
        XCTAssertEqual(repo.allQuests.map(\.questId), ["1", "2", "3"])
        XCTAssertEqual(repo.displayQuests.count, 3)
        XCTAssertEqual(repo.displayCoordQuests.count, 3)
        for placed in repo.displayCoordQuests {
            XCTAssertEqual(placed.coordinateInfo.latitude, 47.6062, accuracy: 0.11)
            XCTAssertEqual(placed.coordinateInfo.longitude, -122.3321, accuracy: 0.11)
            XCTAssertFalse(placed.isHidden)
        }
    }

    func testReloadingAWorkspaceReplacesTheQuestList() {
        loadQuestsSync()
        loadQuestsSync()
        XCTAssertEqual(QuestsRepository.shared.allQuests.count, 3, "quests are replaced, not appended")
    }

    func testQuestLookupsByTypeAndQueryIgnoreCaseWhereTheyShould() {
        QuestsRepository.shared.longQuestModels = (try? JSONDecoder().decode(Workspace.self, from: MockHTTP.fixture("WorkspaceDetailsWithQuests")).longFormQuest?.elements) ?? []
        let repo = QuestsRepository.shared
        XCTAssertEqual(repo.questQueryForElementType("sidewalks"), "ways with (highway=footway and footway=sidewalk)")
        XCTAssertEqual(repo.questQueryForElementType("KERBS"), "nodes with (barrier=kerb)")
        XCTAssertNil(repo.questQueryForElementType("benches"))
        XCTAssertEqual(repo.questElementForQuery("nodes with (barrier=kerb)")?.elementType, "Kerbs")
        XCTAssertNil(repo.questElementForQuery("nodes with (nothing=here)"))
    }

    func testLongFormDefinitionsCanBeReloadedFromDisk() throws {
        let elements = try XCTUnwrap(try JSONDecoder().decode(Workspace.self, from: MockHTTP.fixture("WorkspaceDetailsWithQuests")).longFormQuest?.elements)
        try FileStorageManager.shared.save(questModels: elements, to: "unit-test-reload")
        addTeardownBlock { try? FileStorageManager.shared.delete(fileName: "unit-test-reload") }

        QuestsRepository.shared.loadLongQuests(from: "unit-test-reload")
        XCTAssertEqual(QuestsRepository.shared.longQuestModels.count, 3)

        QuestsRepository.shared.longQuestModels = []
        QuestsRepository.shared.loadLongQuests(from: "does-not-exist")
        XCTAssertTrue(QuestsRepository.shared.longQuestModels.isEmpty, "a missing file leaves the list alone")
    }

    func testAQuestTypeIsOnByDefaultAndTheChoiceIsRemembered() {
        let quest = LongElementQuest(questId: "42", questQuery: "ways with (a=b)", elementType: "X", elementTypeIcon: nil)
        var applicable = ApplicableQuest(quest: quest, questId: "unit-test-q")
        XCTAssertTrue(applicable.isDefault)
        applicable.toggleIsDefault()
        XCTAssertFalse(applicable.isDefault)
        XCTAssertFalse(ApplicableQuest(quest: quest, questId: "unit-test-q").isDefault, "a new instance reads the stored choice")
        applicable.isDefault = true
        XCTAssertTrue(ApplicableQuest(quest: quest, questId: "unit-test-q").isDefault)
    }

    func testAnnotationsExposeTheirDisplayUnit() {
        let unit = DisplayUnit(title: "T", description: "D", id: "7-1", parent: nil, sheetSize: .LONGFORM)
        let annotation = DisplayUnitAnnotation(id: "7-1", coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 2))
        XCTAssertNil(annotation.title)
        XCTAssertNil(annotation.subtitle)
        annotation.displayUnit = unit
        XCTAssertEqual(annotation.title, "T")
        XCTAssertEqual(annotation.subtitle, "D")
        XCTAssertTrue(annotation.isEqual(DisplayUnitAnnotation(id: "7-1", coordinate: CLLocationCoordinate2D(latitude: 9, longitude: 9))), "identity is the id alone")
        XCTAssertFalse(annotation.isEqual(DisplayUnitAnnotation(id: "8-1", coordinate: annotation.coordinate)))
        XCTAssertFalse(annotation.isEqual("not an annotation"))
        XCTAssertEqual(annotation.hash, DisplayUnitAnnotation(id: "7-1", coordinate: .init()).hash)
        XCTAssertEqual(Set([annotation, DisplayUnitAnnotation(id: "7-1", coordinate: .init())]).count, 1)
    }

    func testDisplayUnitsWithCoordinatesCompareByIdVisibilityAndLocation() {
        let unit = DisplayUnit(title: "T", description: "D", id: "7-1", parent: nil, sheetSize: nil)
        let a = DisplayUnitWithCoordinate(displayUnit: unit, coordinateInfo: CLLocationCoordinate2D(latitude: 1, longitude: 2), id: 7, isHidden: false)
        let same = DisplayUnitWithCoordinate(displayUnit: unit, coordinateInfo: CLLocationCoordinate2D(latitude: 1, longitude: 2), id: 7, isHidden: false)
        XCTAssertEqual(a, same)
        XCTAssertNotEqual(a, DisplayUnitWithCoordinate(displayUnit: unit, coordinateInfo: a.coordinateInfo, id: 8, isHidden: false))
        XCTAssertNotEqual(a, DisplayUnitWithCoordinate(displayUnit: unit, coordinateInfo: a.coordinateInfo, id: 7, isHidden: true))
        XCTAssertNotEqual(a, DisplayUnitWithCoordinate(displayUnit: unit, coordinateInfo: CLLocationCoordinate2D(latitude: 1, longitude: 3), id: 7, isHidden: false))
        XCTAssertEqual(a.location.coordinate.latitude, 1)
        XCTAssertEqual(a.annotation.id, "7-1")
        XCTAssertEqual(a.annotation.displayUnit, unit)
    }

    func testDisplayUnitEqualityIgnoresItsParent() {
        let a = DisplayUnit(title: "T", description: "D", id: "1", parent: nil, sheetSize: .LONGFORM)
        XCTAssertEqual(a, DisplayUnit(title: "T", description: "D", id: "1", parent: LongElementQuest(), sheetSize: .LONGFORM))
        XCTAssertNotEqual(a, DisplayUnit(title: "T2", description: "D", id: "1", parent: nil, sheetSize: .LONGFORM))
        XCTAssertNotEqual(a, DisplayUnit(title: "T", description: "D2", id: "1", parent: nil, sheetSize: .LONGFORM))
        XCTAssertNotEqual(a, DisplayUnit(title: "T", description: "D", id: "2", parent: nil, sheetSize: .LONGFORM))
        XCTAssertNotEqual(a, DisplayUnit(title: "T", description: "D", id: "1", parent: nil, sheetSize: .MEDIUM))
    }

    func testClustersAreEqualWhenTheirMembersSitAtTheSamePlaces() {
        func cluster(_ id: String, at c: CLLocationCoordinate2D, members: [CLLocationCoordinate2D]) -> CluserableDisplayUnitAnnotation {
            let cluster = CluserableDisplayUnitAnnotation(id: id, coordinate: c)
            cluster.memberAnnotations = members.map { DisplayUnitAnnotation(id: UUID().uuidString, coordinate: $0) }
            return cluster
        }
        let p = CLLocationCoordinate2D(latitude: 1, longitude: 1), q = CLLocationCoordinate2D(latitude: 2, longitude: 2)
        let a = cluster("c1", at: p, members: [p, q])
        XCTAssertTrue(a.isEqual(a))
        XCTAssertTrue(a.isEqual(cluster("other-id", at: p, members: [p, q])))
        XCTAssertFalse(a.isEqual(cluster("c1", at: q, members: [p, q])), "different centre")
        XCTAssertFalse(a.isEqual(cluster("c1", at: p, members: [p])), "different member count")
        XCTAssertFalse(a.isEqual(cluster("c1", at: p, members: [q, p])), "different member order")
        XCTAssertFalse(a.isEqual(DisplayUnitAnnotation(id: "c1", coordinate: p)))
    }
}

// MARK: - Hidden quests

final class HiddenQuestManagerTests: AppTestCase {

    private let manager = HiddenQuestManager.shared

    private func items() -> [DisplayUnitWithCoordinate] {
        [1, 2, 3].map { id in
            DisplayUnitWithCoordinate(displayUnit: DisplayUnit(title: "", description: "\(id)", id: "\(id)-1", parent: nil, sheetSize: nil),
                                      coordinateInfo: CLLocationCoordinate2D(latitude: Double(id), longitude: 0), id: Int64(id), isHidden: false)
        }
    }

    func testHidingAnElementMarksItAndRemembersIt() {
        var list = items()
        manager.hideQuest(elementId: "2-1", elementName: "Two", items: &list)
        XCTAssertEqual(list.map(\.isHidden), [false, true, false])
        XCTAssertEqual(manager.hiddenQuests.map(\.id), [2])
        XCTAssertEqual(manager.hiddenQuests.first?.name, "Two")
    }

    func testHidingTheSameElementTwiceStoresItOnce() {
        var list = items()
        manager.hideQuest(elementId: "2-1", elementName: "Two", items: &list)
        manager.hideQuest(elementId: "2-9", elementName: "Two again", items: &list)
        XCTAssertEqual(manager.hiddenQuests.count, 1)
    }

    func testAnUnknownOrMalformedElementIdChangesNothing() {
        var list = items()
        manager.hideQuest(elementId: "99-1", elementName: "x", items: &list)
        manager.hideQuest(elementId: "abc", elementName: "x", items: &list)
        manager.hideQuest(elementId: "", elementName: "x", items: &list)
        XCTAssertTrue(manager.hiddenQuests.isEmpty)
        XCTAssertTrue(list.allSatisfy { !$0.isHidden })
    }

    func testHiddenElementsArePersistedAcrossLoads() {
        var list = items()
        manager.hideQuest(elementId: "1-1", elementName: "One", items: &list)
        manager.hideQuest(elementId: "3-1", elementName: "Three", items: &list)
        manager.hiddenQuests = []
        manager.loadHiddenQuests()
        XCTAssertEqual(manager.hiddenQuests.map(\.id), [1, 3])
    }

    func testLoadingWithNothingStoredLeavesTheListAsIs() {
        manager.hiddenQuests = [HiddenQuest(id: 5, name: "kept")]
        UserDefaults.standard.removeObject(forKey: "hiddenElements")
        manager.loadHiddenQuests()
        XCTAssertEqual(manager.hiddenQuests.map(\.id), [5])
    }

    func testUnhidingByOffsetAndAll() {
        var list = items()
        for id in 1...3 { manager.hideQuest(elementId: "\(id)-1", elementName: "n\(id)", items: &list) }
        manager.removeQuest(atOffsets: IndexSet(integer: 1))
        XCTAssertEqual(manager.hiddenQuests.map(\.id), [1, 3])
        manager.hiddenQuests = []
        manager.loadHiddenQuests()
        XCTAssertEqual(manager.hiddenQuests.map(\.id), [1, 3], "the removal was persisted")

        manager.removeAllHiddenQuests()
        XCTAssertTrue(manager.hiddenQuests.isEmpty)
        manager.loadHiddenQuests()
        XCTAssertTrue(manager.hiddenQuests.isEmpty)
    }
}

// MARK: - Surfaces & localized strings

final class SurfaceTests: XCTestCase {

    private let allRawValues = ["asphalt", "concrete", "concrete:plates", "concrete:lanes", "fine_gravel", "paving_stones", "compacted", "dirt",
                                "mud", "sett", "unhewn_cobblestone", "grass_paver", "wood", "woodchips", "metal", "gravel", "pebblestone", "grass",
                                "sand", "rock", "clay", "artificial_turf", "tartan", "paved", "unpaved", "ground", "earth", "chipseal", "metal_grid",
                                "soil", "none", "unknown"]

    func testEverySurfaceHasATitleAndAnIcon() {
        for raw in allRawValues {
            let surface = try! XCTUnwrap(Surface(rawValue: raw), raw)
            if surface == .none || surface == .unknown {
                XCTAssertEqual(surface.iconResId, "", raw)
            } else {
                XCTAssertFalse(surface.titleResId.isEmpty, "\(raw) has no title")
                XCTAssertTrue(surface.iconResId.hasPrefix("surface_"), "\(raw) icon: \(surface.iconResId)")
            }
        }
        XCTAssertNil(Surface(rawValue: "lava"))
    }

    func testSynonymsShareTheirCanonicalPresentation() {
        XCTAssertEqual(Surface.chipseal.iconResId, Surface.asphalt.iconResId)
        XCTAssertEqual(Surface.earth.iconResId, Surface.dirt.iconResId)
        XCTAssertEqual(Surface.soil.titleResId, Surface.dirt.titleResId)
        XCTAssertEqual(Surface.metalGrid.iconResId, Surface.metal.iconResId)
        XCTAssertEqual(Surface.none.titleResId, "")
        XCTAssertEqual(Surface.unknown.titleResId, "unknown")
    }

    func testOnlyRealSurfacesAreSelectableForAWay() {
        XCTAssertTrue(SELECTABLE_WAY_SURFACES.contains("asphalt"))
        XCTAssertTrue(SELECTABLE_WAY_SURFACES.contains("paved"))
        XCTAssertFalse(SELECTABLE_WAY_SURFACES.contains("chipseal"), "synonyms are not selectable")
        XCTAssertFalse(SELECTABLE_WAY_SURFACES.contains("unknown"))
        XCTAssertEqual(SELECTABLE_WAY_SURFACES.count, 23)
        for raw in SELECTABLE_WAY_SURFACES { XCTAssertNotNil(Surface(rawValue: raw), "\(raw) must be a known Surface") }
    }

    func testLocalizedStringsFallBackToTheirKeyWhenUntranslated() {
        XCTAssertEqual(LocalizedStrings.select.localized, NSLocalizedString("Select", comment: ""))
        XCTAssertFalse(LocalizedStrings.questSurfaceValueAsphalt.localized.isEmpty)
        XCTAssertEqual(LocalizedStrings.dontShowAgain.rawValue, "dont_show_again")
        XCTAssertFalse(LocalizedStrings.questKerbHeightTitle.localized.isEmpty)
    }
}
