//
//  CustomMentionNode.swift
//  LexicalPlayground
//
//  Created by Luis Garcia on 8/19/25.
//

import Foundation
import Lexical
import LexicalListPlugin
import UIKit

public class CustomMentionNode: TextNode {
    enum CodingKeys: String, CodingKey {
        case mentionName
        case mentionedUserId
        case alphaName
        case mode
    }
    
    private var mentionName: String = ""
    private var mentionedUserId: String = ""
    private var alphaName: String = ""
    private var mentionMode: String = "segmented"
    
    public required init(
        mentionName: String,
        mentionedUserId: String,
        alphaName: String,
        mode: String = "segmented",
        text: String?,
        key: NodeKey?
    ) {
        super.init(text: text ?? mentionName, key: key)
        self.mentionName = mentionName
        self.mentionedUserId = mentionedUserId
        self.alphaName = alphaName
        self.mentionMode = mode
    }
    
    override public class func getType() -> NodeType {
        .customMention
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try super.init(from: decoder)
        
        // Handle your specific JSON structure
        self.mentionName = try container.decode(String.self, forKey: .mentionName)
        self.mentionedUserId = try container.decode(String.self, forKey: .mentionedUserId)
        self.alphaName = try container.decode(String.self, forKey: .alphaName)
        self.mentionMode = try container.decodeIfPresent(String.self, forKey: .mode) ?? "segmented"
    }
    
    required init(text: String, key: NodeKey?) {
        super.init(text: text, key: key)
    }
    
    public func getMentionName() -> String {
        let node: CustomMentionNode = getLatest()
        return node.mentionName
    }
    
    public func getMentionedUserId() -> String {
        let node: CustomMentionNode = getLatest()
        return node.mentionedUserId
    }
    
    public func getAlphaName() -> String {
        let node: CustomMentionNode = getLatest()
        return node.alphaName
    }
    
    public func getMentionMode() -> String {
        let node: CustomMentionNode = getLatest()
        return node.mentionMode
    }
    
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.mentionName, forKey: .mentionName)
        try container.encode(self.mentionedUserId, forKey: .mentionedUserId)
        try container.encode(self.alphaName, forKey: .alphaName)
        try container.encode(self.mentionMode, forKey: .mode)
    }
    
    override public func clone() -> Self {
        Self(
            mentionName: mentionName,
            mentionedUserId: mentionedUserId,
            alphaName: alphaName,
            mode: mentionMode,
            text: getText_dangerousPropertyAccess(),
            key: key
        )
    }
    
    override public func getAttributedStringAttributes(theme: Theme) -> [NSAttributedString.Key: Any] {
        var attributeDictionary = super.getAttributedStringAttributes(theme: theme)
        // Style mentions color can be set here
        attributeDictionary[.foregroundColor] = UIColor.systemBlue
        return attributeDictionary
    }
}
