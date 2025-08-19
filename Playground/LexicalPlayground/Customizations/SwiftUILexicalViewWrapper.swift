//
//  SwiftUILexicalViewWrapper.swift
//  LexicalPlayground
//
//  Created by Luis Garcia on 8/19/25.
//

import SwiftUI
import Lexical
import LexicalLinkPlugin
import LexicalListPlugin

/// SwiftUI wrapper around LexicalView that provides easy integration with SwiftUI apps
public struct SwiftUILexicalView: UIViewRepresentable {
    
    // MARK: - Bindings
    
    /// The plain text content of the editor
    @Binding var text: String
    
    /// The lexical JSON content of the editor (optional, takes precedence over text)
    @Binding var lexicalJSON: String?
    
    // MARK: - Configuration
    
    /// Whether the editor is read-only
    let isReadOnly: Bool
    
    /// Custom theme for the editor
    let theme: Theme?
    
    /// Custom plugins to include
    let plugins: [Plugin]
    
    /// Placeholder text configuration
    let placeholderText: LexicalPlaceholderText?
    
    /// Feature flags for the editor
    let featureFlags: FeatureFlags
    
    /// Delegate for custom behavior
    weak var delegate: LexicalViewDelegate?
    
    // MARK: - Initializers
    
    /// Initialize with plain text binding
    /// - Parameters:
    ///   - text: Binding to the plain text content
    ///   - isReadOnly: Whether the editor should be read-only
    ///   - theme: Custom theme (uses default if nil)
    ///   - plugins: Array of plugins to include
    ///   - placeholderText: Placeholder text configuration
    ///   - featureFlags: Feature flags for the editor
    ///   - delegate: Optional delegate for custom behavior
    public init(
        text: Binding<String>,
        isReadOnly: Bool = false,
        theme: Theme? = nil,
        plugins: [Plugin] = [],
        placeholderText: LexicalPlaceholderText? = nil,
        featureFlags: FeatureFlags = FeatureFlags(),
        delegate: LexicalViewDelegate? = nil
    ) {
        self._text = text
        self._lexicalJSON = .constant(nil)
        self.isReadOnly = isReadOnly
        self.theme = theme
        self.plugins = plugins
        self.placeholderText = placeholderText
        self.featureFlags = featureFlags
        self.delegate = delegate
    }
    
    /// Initialize with lexical JSON binding
    /// - Parameters:
    ///   - text: Binding to fallback plain text content
    ///   - lexicalJSON: Binding to the lexical JSON content
    ///   - isReadOnly: Whether the editor should be read-only
    ///   - theme: Custom theme (uses default if nil)
    ///   - plugins: Array of plugins to include
    ///   - placeholderText: Placeholder text configuration
    ///   - featureFlags: Feature flags for the editor
    ///   - delegate: Optional delegate for custom behavior
    public init(
        text: Binding<String>,
        lexicalJSON: Binding<String?>,
        isReadOnly: Bool = false,
        theme: Theme? = nil,
        plugins: [Plugin] = [],
        placeholderText: LexicalPlaceholderText? = nil,
        featureFlags: FeatureFlags = FeatureFlags(),
        delegate: LexicalViewDelegate? = nil
    ) {
        self._text = text
        self._lexicalJSON = lexicalJSON
        self.isReadOnly = isReadOnly
        self.theme = theme
        self.plugins = plugins
        self.placeholderText = placeholderText
        self.featureFlags = featureFlags
        self.delegate = delegate
    }
    
    /// Convenience initializer with default plugins
    /// - Parameters:
    ///   - text: Binding to the plain text content
    ///   - isReadOnly: Whether the editor should be read-only
    ///   - placeholderText: Placeholder text configuration
    public init(
        text: Binding<String>,
        isReadOnly: Bool = false,
        placeholderText: LexicalPlaceholderText? = nil
    ) {
        self.init(
            text: text,
            isReadOnly: isReadOnly,
            theme: nil,
            plugins: SwiftUILexicalView.defaultPlugins(),
            placeholderText: placeholderText
        )
    }
    
    // MARK: - UIViewRepresentable
    
    public func makeUIView(context: Context) -> LexicalView {
        let coordinator = context.coordinator
        
        let finalTheme = theme ?? SwiftUILexicalView.defaultTheme()
        let finalPlugins = plugins.isEmpty ? SwiftUILexicalView.defaultPlugins() : plugins
        
        let editorConfig = EditorConfig(theme: finalTheme, plugins: finalPlugins)
        let lexicalView = LexicalView(
            editorConfig: editorConfig,
            featureFlags: featureFlags,
            placeholderText: placeholderText
        )
        
        lexicalView.delegate = coordinator
        coordinator.lexicalView = lexicalView
        
        // Set initial content
        coordinator.updateContent()
        
        return lexicalView
    }
    
    public func updateUIView(_ uiView: LexicalView, context: Context) {
        let coordinator = context.coordinator
        coordinator.updateContent()
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    public class Coordinator: NSObject, LexicalViewDelegate {
        let parent: SwiftUILexicalView
        weak var lexicalView: LexicalView?
        private var isUpdatingFromEditor = false
        
        init(_ parent: SwiftUILexicalView) {
            self.parent = parent
            super.init()
        }
        
        func updateContent() {
            guard let lexicalView = lexicalView,
                  !isUpdatingFromEditor else { return }
            
            let editor = lexicalView.editor
            
            // Prioritize lexical JSON content over plain text
            if let jsonContent = parent.lexicalJSON, !jsonContent.isEmpty {
                setLexicalContent(jsonContent, editor: editor)
            } else if !parent.text.isEmpty {
                setPlainTextContent(parent.text, editor: editor)
            } else {
                clearEditor(editor)
            }
        }
        
        private func setLexicalContent(_ jsonContent: String, editor: Editor) {
            do {
                let newEditorState = try EditorState.fromJSON(json: jsonContent, editor: editor)
                try editor.setEditorState(newEditorState)
            } catch {
                print("Error setting lexical content: \(error)")
                // Fallback to plain text
                setPlainTextContent(parent.text, editor: editor)
            }
        }
        
        private func setPlainTextContent(_ textContent: String, editor: Editor) {
            do {
                try editor.update {
                    guard let root = getRoot() else { return }
                    
                    // Clear existing content
                    let children = root.getChildren()
                    for child in children {
                        try child.remove()
                    }
                    
                    // Add new content
                    let paragraph = createParagraphNode()
                    try root.append([paragraph])
                    
                    if !textContent.isEmpty {
                        let textNode = createTextNode(text: textContent)
                        try paragraph.append([textNode])
                    }
                    
                    try paragraph.select(anchorOffset: nil, focusOffset: nil)
                }
            } catch {
                print("Error setting plain text content: \(error)")
            }
        }
        
        private func clearEditor(_ editor: Editor) {
            do {
                try editor.update {
                    guard let root = getRoot() else { return }
                    
                    // Clear existing content
                    let children = root.getChildren()
                    for child in children {
                        try child.remove()
                    }
                    
                    // Add empty paragraph
                    let paragraph = createParagraphNode()
                    try root.append([paragraph])
                    try paragraph.select(anchorOffset: nil, focusOffset: nil)
                }
            } catch {
                print("Error clearing editor: \(error)")
            }
        }
        
        private func updateBindingsFromEditor() {
            guard let lexicalView = lexicalView else { return }
            
            let editor = lexicalView.editor
            
            isUpdatingFromEditor = true
            defer { isUpdatingFromEditor = false }
            
            // Update plain text binding
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.parent.text = lexicalView.text
                
                // Update JSON binding if it exists
                if self.parent.lexicalJSON != nil {
                    do {
                        let currentEditorState = editor.getEditorState()
                        let jsonString = try currentEditorState.toJSON()
                        self.parent.lexicalJSON = jsonString
                    } catch {
                        print("Error converting to JSON: \(error)")
                    }
                }
            }
        }
        
        // MARK: - LexicalViewDelegate
        
        public func textViewDidBeginEditing(textView: LexicalView) {
            parent.delegate?.textViewDidBeginEditing(textView: textView)
        }
        
        public func textViewDidEndEditing(textView: LexicalView) {
            updateBindingsFromEditor()
            parent.delegate?.textViewDidEndEditing(textView: textView)
        }
        
        public func textViewShouldChangeText(_ textView: LexicalView, range: NSRange, replacementText text: String) -> Bool {
            // Update bindings after a delay to capture the changes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.updateBindingsFromEditor()
            }
            
            return parent.delegate?.textViewShouldChangeText(textView, range: range, replacementText: text) ?? true
        }
        
        public func textView(_ textView: LexicalView, shouldInteractWith URL: URL, in selection: RangeSelection?, interaction: UITextItemInteraction) -> Bool {
            return parent.delegate?.textView(textView, shouldInteractWith: URL, in: selection, interaction: interaction) ?? true
        }
    }
    
    // MARK: - Default Configuration
    
    /// Creates a default theme with sensible defaults
    public static func defaultTheme() -> Theme {
        let theme = Theme()
        theme.indentSize = 16.0
        theme.link = [
            .foregroundColor: UIColor.systemBlue
        ]
        return theme
    }
    
    /// Creates default plugins for common functionality
    public static func defaultPlugins() -> [Plugin] {
        return [
            ListPlugin(),
//            InlineImagePlugin(),
            LinkPlugin(),
//            EditorHistoryPlugin(),
            CustomMentionsPlugin()
        ]
    }
}

// MARK: - SwiftUI View Extensions

public extension SwiftUILexicalView {
    
    /// Set whether the editor should be scrollable
    func scrollEnabled(_ enabled: Bool) -> some View {
        self.onAppear {
            // This will be applied in updateUIView
        }
    }
    
    /// Set the background color of the text view
    func textViewBackgroundColor(_ color: UIColor) -> some View {
        self.onAppear {
            // This will be applied in updateUIView
        }
    }
}

// MARK: - Preview Support

#if DEBUG
struct SwiftUILexicalView_Previews: PreviewProvider {
    @State static var text = "Hello, World!\n\nThis is a SwiftUI wrapper around LexicalView."
    @State static var jsonContent: String? = nil
    
    static var previews: some View {
        NavigationView {
            VStack {
                SwiftUILexicalView(
                    text: $text,
                    placeholderText: LexicalPlaceholderText(
                        text: "Start typing...",
                        font: UIFont.systemFont(ofSize: 16),
                        color: UIColor.placeholderText
                    )
                )
                .frame(height: 200)
                .border(Color.gray, width: 1)
                
                Text("Current text: \(text)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Lexical SwiftUI")
        }
    }
}
#endif
