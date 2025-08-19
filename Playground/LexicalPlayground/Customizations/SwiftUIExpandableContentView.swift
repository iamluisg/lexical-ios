//
//  SwiftUIExpandableContentView.swift
//  LexicalPlayground
//
//  Created by Luis Garcia on 8/19/25.
//

import SwiftUI

struct SwiftUIContentView: View {
    @State private var text: String
    @State private var lexicalJSON: String?
    
    init(initialText: String, initialJSON: String?) {
        self._text = State(initialValue: initialText)
        self._lexicalJSON = State(initialValue: initialJSON)
    }
    
    var body: some View {
        ExpandableSwiftUILexicalView(
            text: $text,
            lexicalJSON: $lexicalJSON,
            maxLines: 8,
            isReadOnly: false,
            theme: nil,
            plugins: SwiftUILexicalView.defaultPlugins()
        )
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
