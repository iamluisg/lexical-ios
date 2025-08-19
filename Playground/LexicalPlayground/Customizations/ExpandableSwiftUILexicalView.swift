//
//  ExpandableSwiftUILexicalView.swift
//  LexicalPlayground
//
//  Created by Luis Garcia on 8/19/25.
//

import SwiftUI
import Lexical

struct ExpandableSwiftUILexicalView: View {
    @Binding var text: String
    @Binding var lexicalJSON: String?
    
    let maxLines: Int
    let isReadOnly: Bool
    let theme: Theme?
    let plugins: [Plugin]
    
    @State private var isExpanded: Bool = false
    @State private var shouldShowButton: Bool = true // Start with button visible since JSON content is long
    @State private var collapsedHeight: CGFloat = 200 // Default collapsed height
    @State private var fullHeight: CGFloat = 600 // Default full height
    
    init(
        text: Binding<String>,
        lexicalJSON: Binding<String?> = .constant(nil),
        maxLines: Int = 8,
        isReadOnly: Bool = false,
        theme: Theme? = nil,
        plugins: [Plugin] = []
    ) {
        self._text = text
        self._lexicalJSON = lexicalJSON
        self.maxLines = maxLines
        self.isReadOnly = isReadOnly
        self.theme = theme
        self.plugins = plugins
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                SwiftUILexicalView(
                    text: $text,
                    lexicalJSON: lexicalJSON?.isEmpty == false ? $lexicalJSON : .constant(nil),
                    isReadOnly: isReadOnly,
                    theme: theme,
                    plugins: plugins.isEmpty ? SwiftUILexicalView.defaultPlugins() : plugins
                )
                .frame(height: currentHeight)
                .clipped()
                .onAppear {
                    // Force button to show for testing - we know the content is long
                    shouldShowButton = true
                    calculateInitialHeights()
                }
                .onChange(of: text) { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        calculateInitialHeights()
                    }
                }
                .onChange(of: lexicalJSON) { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        calculateInitialHeights()
                    }
                }
                
                // Gradient overlay when collapsed
                if shouldShowButton && !isExpanded {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color(UIColor.systemBackground).opacity(0.8),
                            Color(UIColor.systemBackground)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 40)
                    .allowsHitTesting(false)
                }
            }
            
            if shouldShowButton {
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    Text(isExpanded ? "Show less" : "Show more")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.systemBackground))
                }
            }
        }
    }
    
    private var currentHeight: CGFloat {
        return isExpanded ? fullHeight : collapsedHeight
    }
    
    private func calculateInitialHeights() {
        // Calculate line height based on theme or default font
        let finalTheme = theme ?? SwiftUILexicalView.defaultTheme()
        let font = finalTheme.text?[.font] as? UIFont ?? UIFont.systemFont(ofSize: 16)
        let lineHeight = font.lineHeight
        
        // Calculate collapsed height (maxLines * lineHeight + padding)
        collapsedHeight = lineHeight * CGFloat(maxLines) + 32
        
        // Set a reasonable full height - this could be dynamic in the future
        fullHeight = collapsedHeight * 3 // Allow for much more content
    }
}
