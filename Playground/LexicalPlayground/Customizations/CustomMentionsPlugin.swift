//
//  CustomMentionsPlugin.swift
//  LexicalPlayground
//
//  Created by Luis Garcia on 8/19/25.
//

import Foundation
import Lexical
import LexicalListPlugin
import LexicalLinkPlugin
import UIKit

extension NodeType {
    static let customMention = NodeType(rawValue: "mention")
    static let tab = NodeType(rawValue: "tab")
}

// MARK: - Custom Mentions Plugin

/// Custom MentionsPlugin that handles your specific mention node structure and tab nodes
public class CustomMentionsPlugin: Plugin {
    
    public init() {}
    
    public func setUp(editor: Editor) {
        do {
            // Register our custom mention node to handle the "mention" type in your JSON
            try editor.registerNode(nodeType: NodeType.customMention, class: CustomMentionNode.self)
            
            // Register our custom tab node to handle the "tab" type in your JSON
            try editor.registerNode(nodeType: NodeType.tab, class: CustomTabNode.self)
        } catch {
            print("Error registering CustomMentionNode or CustomTabNode: \(error)")
        }
    }
    
    public func tearDown() {
        // No cleanup needed for this simple plugin
    }
}
