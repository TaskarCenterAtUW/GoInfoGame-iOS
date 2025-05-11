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
    var icon: UIImage {get}
    var wikiLink: String {get}
    var changesetComment: String {get}
    var form : AnyView {get}
    var relationData : Element? {get set}
    func onAnswer(answer:AnswerClass)
    var displayUnit: DisplayUnit { get}
    var filterExpression : ElementFilterExpression? { get  }
    var questId: String { get }
    
    func copyWithElement(element: Element) -> any Quest // Not sure.
}

class QuestBase {
   public var internalForm: (any QuestForm)? = nil
    
   private var elementSubmittingToPOSM: ElementSubmittingToPOSM?
    
    func updateUndoTags(changeSet: StoredChangeset) {
        // Convert from ElementType enum to StoredElementEnum
        Task.detached(operation: { @MainActor in
            let storedElementType: StoredElementEnum = changeSet.elementType
            do {
                var result: (result: Bool, version: Int) = (false, -1)
                switch storedElementType {
                case .node:
                    result = try await DatasyncManager.shared.syncNode(node: changeSet.asOSMNode(isUndo: true), exclude_gig_tags: true)
                case .way:
                    result = try await DatasyncManager.shared.syncWay(way: changeSet.asOSMWay(isUndo: true), exclude_gig_tags: true)
                case .unknown:
                    print("❌ Undo failed: Element type not found")
                }
            }
            catch {
                print("❌ Undo failed: \(error)")
            }
        })
    }
    
    // Add a custom implementation
    
   public func updateTags(id: Int64, tags:[String:String], type: ElementType, exclude_gig_tags: Bool = false) {
       
       MapUndoManager.shared.updateTagsHandler = { [weak self] changeset in
           guard let changeSet = changeset else { return }
           
           self?.updateUndoTags(changeSet: changeSet)
       }
       
       
       // Convert from ElementType enum to StoredElementEnum
       let storedElementType: StoredElementEnum = type == .way ? .way : .node
       
       switch (storedElementType){
       case .way:
           elementSubmittingToPOSM = .way
//          _ = DatabaseConnector.shared.addWayTags(id: storedId, tags: tags)
           let way =  DatabaseConnector.shared.getWay(id: Int(id), version: .original)!
           // Create a changeset
           _ = DatabaseConnector.shared.createChangeset(id: Int(id), type: storedElementType, originalTags: way.tags.toDictionary(), tags: tags, version: way.version, nodes: way.nodes)
       case .node:
           elementSubmittingToPOSM = .node
//          _ = DatabaseConnector.shared.addNodeTags(id: storedId, tags: tags)
           let node =  DatabaseConnector.shared.getNode(id: Int(id), version: .original)!
           // Create a changeset
           _ = DatabaseConnector.shared.createChangeset(id: Int(id), type: storedElementType, originalTags: node.tags.toDictionary(), tags: tags, version: node.version, point: node.point)
       case .unknown:
           print("Unknown Stored element type received")
       }
       // Sync using datasyncmanager
       
       // Dismiss sheet after syncing to db
       MapViewPublisher.shared.dismissSheet.send(.syncing)
       
       DatasyncManager.shared.syncDataToOSM(exclude_gig_tags: exclude_gig_tags) { success in
           DispatchQueue.main.async {
               MapViewPublisher.shared.dismissSheet.send(.synced)
               
               switch success {
               case .success(let success):
                   if success {
                       if MapUndoManager.shared.isUndoInProgress {
                           MapUndoManager.shared.finalizeSuccessfulSubmit(id: Int(id), type: type)
                           MapUndoManager.shared.isUndoInProgress = false
                       }

                       MapViewPublisher.shared.dismissSheet.send(.submitted("\(id)"))
                   }
 else {
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
