/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import EditorHistoryPlugin
import Lexical
import LexicalInlineImagePlugin
import LexicalLinkPlugin
import LexicalListPlugin
import UIKit

class ViewController: UIViewController, UIToolbarDelegate {

  var lexicalView: LexicalView?
    var expandableLexicalView: ExpandableLexicalView?
  weak var toolbar: UIToolbar?
  weak var hierarchyView: UIView?
  private let editorStatePersistenceKey = "editorState"

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

      makeUIKitVersion()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    if let lexicalView, let toolbar, let hierarchyView {
      let safeAreaInsets = self.view.safeAreaInsets
      let hierarchyViewHeight = 300.0

      toolbar.frame = CGRect(
        x: 0,
        y: safeAreaInsets.top,
        width: view.bounds.width,
        height: 44)
      lexicalView.frame = CGRect(
        x: 0,
        y: toolbar.frame.maxY,
        width: view.bounds.width,
        height: view.bounds.height - toolbar.frame.maxY - safeAreaInsets.bottom - hierarchyViewHeight)
      hierarchyView.frame = CGRect(
        x: 0,
        y: lexicalView.frame.maxY,
        width: view.bounds.width,
        height: hierarchyViewHeight)
    }
  }

  func persistEditorState() {
    guard let editor = lexicalView?.editor else {
      return
    }

    let currentEditorState = editor.getEditorState()

    // turn the editor state into stringified JSON
    guard let jsonString = try? currentEditorState.toJSON() else {
      return
    }

    UserDefaults.standard.set(jsonString, forKey: editorStatePersistenceKey)
  }

  func restoreEditorState() {
    guard let editor = lexicalView?.editor else {
      return
    }

    guard let jsonString = UserDefaults.standard.value(forKey: editorStatePersistenceKey) as? String else {
      return
    }

    // turn the JSON back into a new editor state
    guard let newEditorState = try? EditorState.fromJSON(json: jsonString, editor: editor) else {
      return
    }

    // install the new editor state into editor
    try? editor.setEditorState(newEditorState)
  }

  func setUpExportMenu() {
    let menuItems = OutputFormat.allCases.map { outputFormat in
      UIAction(
        title: "Export \(outputFormat.title)",
        handler: { [weak self] action in
          self?.showExportScreen(outputFormat)
        })
    }
    let menu = UIMenu(title: "Export as…", children: menuItems)
    let barButtonItem = UIBarButtonItem(title: "Export", style: .plain, target: nil, action: nil)
    barButtonItem.menu = menu
    navigationItem.rightBarButtonItem = barButtonItem
  }

  func showExportScreen(_ type: OutputFormat) {
    guard let editor = lexicalView?.editor else { return }
    let vc = ExportOutputViewController(editor: editor, format: type)
    navigationController?.pushViewController(vc, animated: true)
  }

  func position(for bar: UIBarPositioning) -> UIBarPosition {
    return .top
  }
}

extension ViewController {
    func makeUIKitVersion() {
      let editorHistoryPlugin = EditorHistoryPlugin()
      let toolbarPlugin = ToolbarPlugin(viewControllerForPresentation: self, historyPlugin: editorHistoryPlugin)
      let toolbar = toolbarPlugin.toolbar
      toolbar.delegate = self

      let hierarchyPlugin = NodeHierarchyViewPlugin()
      let hierarchyView = hierarchyPlugin.hierarchyView

      let listPlugin = ListPlugin()
      let imagePlugin = InlineImagePlugin()

      let linkPlugin = LinkPlugin()

      let theme = Theme()
      theme.indentSize = 16.0
      theme.link = [
        .foregroundColor: UIColor.systemBlue
      ]

        let editorConfig = EditorConfig(theme: theme, plugins: [toolbarPlugin, listPlugin, hierarchyPlugin, imagePlugin, linkPlugin, editorHistoryPlugin, CustomMentionsPlugin()])
      let lexicalView = LexicalView(editorConfig: editorConfig, featureFlags: FeatureFlags())

      // Create expandable wrapper with max 8 lines
      let expandableLexicalView = ExpandableLexicalView(lexicalView: lexicalView, maxLines: 8)

      linkPlugin.lexicalView = lexicalView

      self.lexicalView = lexicalView
      self.expandableLexicalView = expandableLexicalView
      self.toolbar = toolbar
      self.hierarchyView = hierarchyView

      // Load the custom JSON data instead of restoring from UserDefaults
      loadCustomEditorState()

      view.addSubview(expandableLexicalView)
//      view.addSubview(toolbar)
//      view.addSubview(hierarchyView)
      
      // Setup Auto Layout constraints instead of frames
      setupAutoLayoutConstraints()

      navigationItem.title = "Lexical"
      setUpExportMenu()
    }
    
    func setupAutoLayoutConstraints() {
        guard let expandableLexicalView = expandableLexicalView else { return }
        
        NSLayoutConstraint.activate([
            expandableLexicalView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            expandableLexicalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            expandableLexicalView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            expandableLexicalView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func unescapeServerString(_ input: String) -> String {
        var unescaped = input

        // 1. Remove the outer literal quotes if they exist (e.g., """ "..." """ -> "...")
        if unescaped.hasPrefix("\"") && unescaped.hasSuffix("\"") && unescaped.count >= 2 {
            unescaped = String(unescaped.dropFirst().dropLast())
        }
        
        // 2. Unescape the JSON-specific escapes (e.g., \" to ", \\ to \)
        unescaped = unescaped.replacingOccurrences(of: "\\\"", with: "\"")
        unescaped = unescaped.replacingOccurrences(of: "\\\\", with: "\\")
        
        return unescaped
    }
    
    func loadCustomEditorState() {
        guard let editor = lexicalView?.editor else {
            return
        }
        
        // Get the same JSON data used in SwiftUI version
        let jsonString = unescapeServerString(LexicalTestData.communityLexicalText)
        
        // Create EditorState from JSON and set it
        do {
            let newEditorState = try EditorState.fromJSON(json: jsonString, editor: editor)
            try editor.setEditorState(newEditorState)
            
            // Update expandable view content after loading
            expandableLexicalView?.updateContent()
        } catch {
            print("Error loading custom editor state: \(error)")
            // Fall back to empty state if JSON parsing fails
        }
    }
}
