//
//  QuestProtocols.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/17/24.
//

import Foundation
import UIKit
import SwiftUI
import osmparser
import MapKit

enum ElementSubmittingToPOSM {
    case node, way
}

protocol Quest {
    associatedtype AnswerClass // The class that represents answer
    var title:String {get}
    var filter: String {get}
    var iconName: String {get}
    var wikiLink: String {get}
    var changesetComment: String {get}
    var id: Int64 {get}
    var type: ElementType {get}
    var elementType: String {get}
    var form : AnyView {get}
    func onAnswer(answer:AnswerClass)
    var displayUnit: DisplayUnit { get}
    var filterExpression : ElementFilterExpression? { get  }
    var questId: String { get }
    var polylines: [CLLocationCoordinate2D]? { get }

    func copyWithElement(element: Element) -> any Quest // Not sure.

    /// A genuine protocol requirement (not just an extension method) so a
    /// conformer can override the default filter-expression-based match — e.g.
    /// LongElementQuest does, to let a completed element qualify again once past
    /// its recency period. Without this being a requirement, an override placed
    /// directly on the conforming type would never be reached through `any Quest`
    /// call sites (extension methods use static, not witness-table, dispatch).
    func isApplicable(element: Element) -> Bool
}

class QuestBase {
   public var internalForm: (any QuestForm)? = nil
    
   private var elementSubmittingToPOSM: ElementSubmittingToPOSM?
    
    init () {
        MapUndoManager.shared.updateTagsHandler = { [weak self] changeset in
            guard let changeSet = changeset else { return }
            
            self?.updateUndoTags(changeSet: changeSet)
        }
    }
    
    func updateUndoTags(changeSet: StoredChangeset) {
        // A created-but-undone element never existed before, so there are no
        // "original tags" to restore — undoing it means deleting it outright.
        // This never touches the modify-undo path below, which is unchanged.
        if changeSet.isCreatedElement {
            undoCreatedElement(changeSet: changeSet)
            return
        }

        // Convert from ElementType enum to StoredElementEnum
        Task.detached(operation: { @MainActor in
            MapViewPublisher.shared.dismissSheet.send(.syncing)
            let storedElementType: StoredElementEnum = changeSet.elementType
            let changesetId = changeSet.id
            do {
                var result: (result: Bool, version: Int) = (false, -1)
                switch storedElementType {
                case .node:
                    result = try await DatasyncManager.shared.syncNode(node: changeSet.asOSMNode(isUndo: true), exclude_gig_tags: true, editedTags: changeSet.tags.toDictionary())
                case .way:
                    result = try await DatasyncManager.shared.syncWay(way: changeSet.asOSMWay(isUndo: true), exclude_gig_tags: true, editedTags: changeSet.tags.toDictionary())
                case .unknown:
                    print("❌ Undo failed: Element type not found")
                }
                print("undo result \(result)")
                _ = DatabaseConnector.shared.updateChangesetWithUndoResultSuccess(obj: changesetId)
                MapViewPublisher.shared.dismissSheet.send(.synced)
//                MapViewPublisher.shared.dismissSheet.send(.submitted(""))
                MapViewPublisher.shared.dismissSheet.send(.undoDone(changesetId))
            }
            catch {
                print("❌ Undo failed: \(error)")
                MapViewPublisher.shared.dismissSheet.send(.failed("Failed to Undo changes. Please try again"))
            }
        })
    }

    /// Deletes a feature that was created via Add Feature — only ever reached for
    /// `changeSet.isCreatedElement == true` (nodes only; `AddFeatureView` never
    /// creates ways). Mirrors the local Realm cleanup already used elsewhere when the
    /// server reports an element gone (`DatasyncManager.updateNode2`/`updateWay2`'s
    /// `.deleted` handling): drop the local `StoredNode`, keep the changeset row for
    /// history (marked completed, same as a modify-undo), and tell the map to remove
    /// the pin via the existing `refreshMapAfterSubmission` removal path.
    private func undoCreatedElement(changeSet: StoredChangeset) {
        Task.detached(operation: { @MainActor in
            MapViewPublisher.shared.dismissSheet.send(.syncing)
            let changesetId = changeSet.id
            let elementId = changeSet.elementId
            do {
                _ = try await DatasyncManager.shared.deleteNode(node: changeSet.asOSMNode(isUndo: true))
                DatabaseConnector.shared.deleteNode(id: elementId)
                _ = DatabaseConnector.shared.updateChangesetWithUndoResultSuccess(obj: changesetId)
                MapViewPublisher.shared.dismissSheet.send(.synced)
                MapViewPublisher.shared.dismissSheet.send(.elementRemoved(elementId))
            } catch {
                print("❌ Undo (delete) failed: \(error)")
                MapViewPublisher.shared.dismissSheet.send(.failed("Failed to delete feature. Please try again"))
            }
        })
    }

    // Add a custom implementation
    
    public func updateTags(id: Int64, questType: String, tags:[String:String], type: ElementType, iconName: String, exclude_gig_tags: Bool = false) {

       // Convert from ElementType enum to StoredElementEnum
       let storedElementType: StoredElementEnum = type == .way ? .way : .node

       switch (storedElementType){
       case .way:
           elementSubmittingToPOSM = .way
//          _ = DatabaseConnector.shared.addWayTags(id: storedId, tags: tags)
           let way =  DatabaseConnector.shared.getWay(id: Int(id))!
           // Create a changeset
           _ = DatabaseConnector.shared.createChangeset(id: Int(id), questType: questType, type: storedElementType, originalTags: way.tags.toDictionary(), tags: tags, version: way.version, iconName: iconName, nodes: way.nodes)
       case .node:
           elementSubmittingToPOSM = .node
//          _ = DatabaseConnector.shared.addNodeTags(id: storedId, tags: tags)
           let node =  DatabaseConnector.shared.getNode(id: Int(id))!
           // Create a changeset
           _ = DatabaseConnector.shared.createChangeset(id: Int(id), questType: questType, type: storedElementType, originalTags: node.tags.toDictionary(), tags: tags, version: node.version, iconName: iconName, point: CLLocationCoordinate2D(latitude: node.latitude, longitude: node.longitude))
       case .unknown:
           print("Unknown Stored element type received")
       }
       // Sync using datasyncmanager
       
       // Dismiss sheet after syncing to db
       MapViewPublisher.shared.dismissSheet.send(.syncing)
       MapViewPublisher.shared.dismissSheet.send(.syncBackground(Int(id)))
       
       DatasyncManager.shared.syncDataToOSM(exclude_gig_tags: exclude_gig_tags) { success in
           DispatchQueue.main.async {
               MapViewPublisher.shared.dismissSheet.send(.synced)

               switch success {
               case .success(let success):
                   if success {
                       // Only now are the merged tags actually persisted locally —
                       // safe to re-check whether this element still needs answers.
                       MapViewPublisher.shared.dismissSheet.send(.answerSynced(Int(id)))
                   } else {
                       print("Sync failed. Handle accordingly.")
                       MapViewPublisher.shared.dismissSheet.send(.failed("Submission failed. Please try again."))
                   }
               case .failure(let error):
                   print("Error during sync: \(error)")
                   let errorMessage = error.localizedDescription
                   MapViewPublisher.shared.dismissSheet.send(.failed(errorMessage))
               }
           }
       }
    }
}
// Adds default method and implementation
extension Quest {
    
    func isApplicable(element:Element) ->  Bool {
        
        guard let filterExpression = filterExpression else {
            return false
        }
        if((filterExpression.includesElementType(elementType: .node) && element is Node)
           || (filterExpression.includesElementType(elementType: .way) && element is Way)){
            return filterExpression.matches(element: element)
        }
        return false
    }
    
    var filterExpression : ElementFilterExpression? {
        
        return try? filter.toElementFilterExpression() // This is a costly operation
    }
    
}


struct DisplayUnit : Identifiable, Equatable {
    static func == (lhs: DisplayUnit, rhs: DisplayUnit) -> Bool {
        return lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.description == rhs.description &&
        lhs.sheetSize == rhs.sheetSize
    }
    
    let title:String
    let description : String
    let id: String
    let parent: (any Quest)?
    let sheetSize : SheetSize?
}

protocol QuestForm {
    associatedtype AnswerClass
    
    var action: ((_ answer:AnswerClass)->Void)? {get set}
}

//struct DisplayUnitWithCoordinate: Identifiable {
//    let displayUnit: DisplayUnit
//    let coordinateInfo: CLLocationCoordinate2D
//    let id = UUID()
//}
