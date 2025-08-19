//
//  CustomTabNode.swift
//  LexicalPlayground
//
//  Created by Luis Garcia on 8/19/25.
//

import Foundation
import Lexical

public class CustomTabNode: TextNode {
    
    public required init(text: String?, key: NodeKey?) {
        // Convert tab character to spaces for display
        let displayText = (text == "\t") ? "    " : (text ?? "    ")
        super.init(text: displayText, key: key)
    }
    
    override public class func getType() -> NodeType {
        .tab
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        // After decoding, if the text is a tab character, convert to spaces
        if getText_dangerousPropertyAccess() == "\t" {
            setText_dangerousPropertyAccess("    ")
        }
    }
    
    override public func clone() -> Self {
        Self(text: getText_dangerousPropertyAccess(), key: key)
    }
}

public func createCustomTabNode(text: String = "\t") -> TextNode {
    return CustomTabNode(text: text, key: nil)
}
