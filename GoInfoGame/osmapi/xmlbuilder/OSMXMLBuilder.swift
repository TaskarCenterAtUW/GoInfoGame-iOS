//
//  OSMXMLBuilder.swift
//  osmapi
//
//  Created by Naresh Devalapally on 1/22/24.
//

import Foundation
// Builder class for some of the things
class OSMXMLBuilder {
    private var xmlString: String
    private var nodeName: String
    private var attributes:[String:String] = [:]
    private var children: [OSMPayload] = []
    
        init(rootName: String) {
            xmlString = ""
            nodeName = rootName
        }

    func addAttribute(name:String, value:String){
        self.attributes[name] = value
    }
    
    func addChild(element: OSMPayload){
        children.append(element)
    }
    
    private func addTagStart() {
        xmlString += "<"
    }
    private func addTagEnd() {
        xmlString += ">"
    }
    private func addNodeEnd() {
        xmlString += "</\(nodeName)>"
    }
    
    private func addAttributeString() {
        // Try iterator some time
        let attributeMap = attributes.map { (key: String, value: String) in
            "\(key) = \"\(value)\""
        }.joined(separator: " ")
        xmlString += attributeMap
    }
    
        func buildXML() -> String {
            addTagStart()
            xmlString += nodeName+" "
            if(attributes.count > 0){
               addAttributeString()
            }
            if(children.count > 0){
                addTagEnd()
                children.forEach { element in
                    xmlString += element.toPayload()
                    xmlString += "\n"
                }
                
                addNodeEnd()
            }
            else {
                xmlString += "/>"
            }
            return xmlString
        }
}
