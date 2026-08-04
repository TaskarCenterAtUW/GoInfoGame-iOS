//
//  LongElementQuest.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 25/02/25.
//

import Foundation
import osmparser
import SwiftUI
import CoreLocation

struct LazyView<Content: View>: View, QuestForm {
    var action: (([String : String]) -> Void)?
    
    typealias AnswerClass = [String: String]
    
    let build: () -> Content

    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }

    var body: Content {
        build()
    }
}

class LongElementQuest: QuestBase, Quest {
    var polylines: [CLLocationCoordinate2D]?
    
    var id: Int64
    
    var type: osmparser.ElementType
    
    var iconName: String {
        if let iconName = elementTypeIcon {
            return iconName
        } else {
            let lowercasedElementType = elementType.lowercased()
            
            switch lowercasedElementType {
            case "sidewalks":
                return "sidewalk_surface"
            case "crossings":
                return "pedestrian"
            case "kerb":
                return "kerb_type"
            default:
                return "notes"
            }
        }
    }

    
    var title: String = ""
    
    var filter: String {
        return QuestsRepository.shared.questQueryForElementType(elementType) ?? _internalQueryString!
    }
        
    var wikiLink: String = ""
    
    private(set) var elementType: String = ""

    private(set) var elementTypeIcon: String?

    var tags: [String: String]?

    
    var changesetComment: String = ""
    
    typealias AnswerClass = [String:String]
    
    var form:  AnyView {
        get{
            return AnyView(self.internalForm as! LongForm)
        }
    }
    
    var _internalExpression: ElementFilterExpression?

    var _internalQueryString: String?

    var filterExpression: ElementFilterExpression? {
        if(_internalExpression != nil){
            return _internalExpression
        }
        else {
            let longQuestQuery = self._internalQueryString
            var filter = ""

            if let longQuestQuery = longQuestQuery {
                filter = longQuestQuery + " and !ext:gig_complete"
            } else {
                filter = " and !ext:gig_complete"
            }
            _internalExpression = try? filter.toElementFilterExpression()
            return _internalExpression
        }
    }

    /// The quest_query alone, without the `!ext:gig_complete` exclusion — used only
    /// by `isApplicable` to re-check a completed element against the recency period.
    /// `ext:gig_last_updated` is written as "yyyy-MM-ddXXX" (a timezone suffix), which
    /// the shared filter DSL's date parser can't read (it requires a whole-string
    /// "yyyy-MM-dd" match), so that comparison is done here in Swift instead of by
    /// folding it into `filterExpression`'s query string.
    private var _internalBaseExpression: ElementFilterExpression?
    private var baseFilterExpression: ElementFilterExpression? {
        if let _internalBaseExpression { return _internalBaseExpression }
        _internalBaseExpression = try? _internalQueryString?.toElementFilterExpression()
        return _internalBaseExpression
    }

    private static let gigDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-ddXXX"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    /// Before the "XXX" timezone suffix was added, `ext:gig_last_updated` was
    /// written as a bare "yyyy-MM-dd" — kept so elements completed by older app
    /// versions still parse.
    private static let legacyGigDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    /// `DateFormatter.date(from:)` requires the whole string to match its pattern,
    /// so trying the current format first and falling back to the legacy one is
    /// unambiguous — a value can only ever satisfy one of the two.
    private static func parseGigDate(_ value: String) -> Date? {
        gigDateFormatter.date(from: value) ?? legacyGigDateFormatter.date(from: value)
    }

    /// True when `tags` represents an element that should still be treated as
    /// "answered, nothing to do" — i.e. not just marked `ext:gig_complete=yes`, but
    /// also still within its `recency_period` freshness window (if one is
    /// configured at all). Shared by `isApplicable` (bulk quest matching) and
    /// MapView's tap-to-open freshness re-check, so both agree on the same element
    /// at the same moment — without this, a stale-but-complete element could show
    /// up as a pin (via `isApplicable`) but still get rejected as "already
    /// answered" the instant it's tapped.
    static func isStillConsideredComplete(tags: [String: String]) -> Bool {
        // Key presence only — matches the original `!ext:gig_complete` filter
        // (NotHasKey), which never looked at the tag's value either. Checking for
        // an exact "yes" here would incorrectly treat any element completed with a
        // different value (a legacy write, another app version/platform) as never
        // answered at all.
        guard tags.keys.contains("ext:gig_complete") else { return false }
        guard let recencyDays = QuestsRepository.shared.recencyPeriodDays else { return true }
        guard let lastUpdatedString = tags["ext:gig_last_updated"],
              let lastUpdatedDate = parseGigDate(lastUpdatedString)
        else { return true } // marked complete but undated/unparseable — stay conservative

        let daysSinceUpdate = Calendar.current.dateComponents([.day], from: lastUpdatedDate, to: Date()).day ?? 0
        return daysSinceUpdate <= recencyDays
    }

    /// Matches the quest_query's own tag/element-type conditions regardless of
    /// completion state, then separately gates on `isStillConsideredComplete` — so
    /// a completed element that's gone stale past its `recency_period` qualifies
    /// again, instead of being excluded forever.
    func isApplicable(element: Element) -> Bool {
        guard let baseFilterExpression,
              (baseFilterExpression.includesElementType(elementType: .node) && element is Node)
                  || (baseFilterExpression.includesElementType(elementType: .way) && element is Way),
              baseFilterExpression.matches(element: element)
        else { return false }

        return !Self.isStillConsideredComplete(tags: element.tags)
    }
    
    var displayUnit: DisplayUnit {
        let uid = String(self.id)
        return DisplayUnit(title: self.title, description: "", id: "\(uid)-\(questId)",parent: self,sheetSize: .LONGFORM)
    }
    
    var questAnswersSelected: (([String:String]) -> Void)? = nil
    
    var annotationCoordinate: CLLocationCoordinate2D? {
          didSet {
              updateForm()
          }
      }
    
    private func updateForm() {
          self.internalForm = LongForm(
            elementName: elementType, questID: questId, query: _internalQueryString, tags: tags, action: { [self] tags in
                self.questAnswersSelected?(tags)
            }, coordinate: annotationCoordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
          )
      }

    init(questId: String, questQuery:String, elementType: String, elementTypeIcon: String?) {
        id = -1
        type = .node
        super.init()
        self._internalQueryString = questQuery
        self.elementType = elementType
        self.elementTypeIcon = elementTypeIcon
        self.internalForm = LazyView(LongForm(elementName: elementType, questID: questId,query: questQuery, tags: self.tags, action: { [self] tags in
//            self.onAnswer(answer: tags)
            self.questAnswersSelected?(tags)
        }))
    }

    override init() {
        id = -1
        type = .node
        super.init()

        self.internalForm = LongForm(elementName: elementType, tags: tags, action: { [self] tags in
//            self.onAnswer(answer: tags)
            self.questAnswersSelected?(tags)
        })
    }


    func onAnswer(answer: [String : String]) {
        self.updateTags(id: id, questType: elementType, tags: answer, type: type, iconName: iconName)
    }

    func fetchLatestTagsIfNeeded() async -> [String: String]? {
        await DatasyncManager.shared.fetchLatestTags(id: id, isWay: type == .way)
    }

    var questId: String {
        return String(self.id)
    }
    
    func copyWithElement(element: Element) -> any Quest {
        let questId = String(element.id)
        let quest = LongElementQuest(questId: questId, questQuery: _internalQueryString!, elementType: elementType, elementTypeIcon: elementTypeIcon)
        if let way = element as? Way {
            quest.polylines = way.polyline.compactMap { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
            }
        }
        quest.id = element.id
        quest.type = element.type
        quest.tags = element.tags
        return quest
    }
}
