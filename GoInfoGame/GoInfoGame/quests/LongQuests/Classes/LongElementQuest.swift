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

    /// Set by `QuestSheetView.init` before opening the form. A multi-select batch
    /// can contain elements with different existing answers for the same question,
    /// and this element's own `tags` (used for prefill) can't represent that — so
    /// the form must start blank rather than misleadingly show only the first
    /// selected element's state, which the user could then unintentionally apply
    /// to every other element in the batch by leaving it untouched.
    var isMultiSelectMode: Bool = false


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
    private var _internalBaseExpression: ElementFilterExpression?
    private var baseFilterExpression: ElementFilterExpression? {
        if let _internalBaseExpression { return _internalBaseExpression }
        _internalBaseExpression = try? _internalQueryString?.toElementFilterExpression()
        return _internalBaseExpression
    }

    /// True when `tags`/`lastEditedAt` represent an element that should still be
    /// treated as "answered, nothing to do" — i.e. every currently-applicable
    /// question in this element's long form already has an answer reflected in
    /// `tags`, and (if a `recency_period` is configured) the element's native OSM
    /// edit timestamp is still within its freshness window. Using the element's
    /// own `timestamp` (rather than a app-managed tag) means an edit made by
    /// anyone, through any tool, counts toward freshness — not just an edit made
    /// through this app's long form. Shared by `isApplicable` (bulk quest
    /// matching) and MapView's tap-to-open freshness re-check, so both agree on
    /// the same element at the same moment — without this, a stale-but-complete
    /// element could show up as a pin (via `isApplicable`) but still get rejected
    /// as "already answered" the instant it's tapped.
    func isStillConsideredComplete(tags: [String: String], lastEditedAt: Date) -> Bool {
        guard let longFormElement = QuestsRepository.shared.questElementForQuery(_internalQueryString ?? "") else {
            // No quest definition resolvable for this query — there's no way to
            // verify completeness, so don't claim it. The app no longer treats
            // ext:gig_complete as meaningful in either direction.
            return false
        }
        guard longFormElement.isFullyAnswered(tags: tags) else { return false }
        guard let recencyDays = QuestsRepository.shared.recencyPeriodDays else { return true }

        // Calendar-day difference, not elapsed-hours: dateComponents([.day], from:to:)
        // anchors to lastEditedAt's exact time-of-day, so an edit from yesterday
        // evening checked this morning (< 24 elapsed hours) would otherwise compute
        // 0 days, not 1 — silently keeping a stale element hidden under a small
        // recency_period. Diffing start-of-day for both sides gives a true calendar-
        // date difference, matching the old ext:gig_last_updated tag's semantics
        // (it stored a date-only string, with no time-of-day component at all).
        let calendar = Calendar.current
        let daysSinceUpdate = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: lastEditedAt),
            to: calendar.startOfDay(for: Date())
        ).day ?? 0
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

        let lastEditedAt = Date(timeIntervalSince1970: TimeInterval(element.timestampEdited))
        return !isStillConsideredComplete(tags: element.tags, lastEditedAt: lastEditedAt)
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
            elementName: elementType, questID: questId, query: _internalQueryString, tags: tags,
            isMultiSelectMode: isMultiSelectMode,
            action: { [self] tags in
                self.questAnswersSelected?(tags)
            }, coordinate: annotationCoordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
          )
      }

    /// Replaces `tags` with a freshly-fetched set (e.g. from `fetchLatestTagsIfNeeded`)
    /// and rebuilds `form` from them. `annotationCoordinate` is set synchronously when
    /// the sheet opens, capturing whatever `tags` held at that moment — for a partially
    /// answered element that's still applicable, the live server fetch that follows
    /// needs this to actually reach the form, otherwise the prefill silently shows
    /// whatever (possibly stale) tags the element had before the sheet's freshness
    /// check ran.
    func refreshTags(_ tags: [String: String]) {
        self.tags = tags
        updateForm()
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

    func fetchLatestTagsIfNeeded() async -> (tags: [String: String], timestamp: Date)? {
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
