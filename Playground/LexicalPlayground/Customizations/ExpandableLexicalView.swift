//
//  ExpandableLexicalView.swift
//  LexicalPlayground
//
//  Created by Luis Garcia on 8/19/25.
//

import UIKit
import Lexical

class ExpandableLexicalView: UIView {
    
    // MARK: - Properties
    
    private let lexicalView: LexicalView
    private let maxLines: Int
    private var isExpanded: Bool = false
    
    private var heightConstraint: NSLayoutConstraint!
    private var collapsedHeight: CGFloat = 0
    private var fullHeight: CGFloat = 0
    
    private lazy var expandButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Show more", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.addTarget(self, action: #selector(toggleExpansion), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var gradientView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Initialization
    
    init(lexicalView: LexicalView, maxLines: Int = 8) {
        self.lexicalView = lexicalView
        self.maxLines = maxLines
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupView() {
        addSubview(lexicalView)
        addSubview(gradientView)
        addSubview(expandButton)
        
        lexicalView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create height constraint for lexicalView with lower priority to avoid conflicts
        heightConstraint = lexicalView.heightAnchor.constraint(equalToConstant: 200)
        heightConstraint.priority = UILayoutPriority(999) // High but not required
        
        // Setup constraints - button always at bottom
        NSLayoutConstraint.activate([
            // Lexical view takes available space minus button area
            lexicalView.topAnchor.constraint(equalTo: topAnchor),
            lexicalView.leadingAnchor.constraint(equalTo: leadingAnchor),
            lexicalView.trailingAnchor.constraint(equalTo: trailingAnchor),
            heightConstraint,
            
            // Gradient overlay at bottom of lexical view
            gradientView.leadingAnchor.constraint(equalTo: leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: lexicalView.bottomAnchor),
            gradientView.heightAnchor.constraint(equalToConstant: 40),
            
            // Button pinned to bottom of container
            expandButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            expandButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            expandButton.heightAnchor.constraint(equalToConstant: 32),
            
            // Ensure minimum space between lexical view and button
            expandButton.topAnchor.constraint(greaterThanOrEqualTo: lexicalView.bottomAnchor, constant: 8)
        ])
        
        // Setup gradient overlay
        setupGradientOverlay()
        
        // Calculate heights after a brief delay to ensure content is loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.calculateHeights()
        }
    }
    
    private func setupGradientOverlay() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.systemBackground.withAlphaComponent(0.8).cgColor,
            UIColor.systemBackground.cgColor
        ]
        gradientLayer.locations = [0, 0.5, 1]
        gradientView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradient frame
        if let gradientLayer = gradientView.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = gradientView.bounds
        }
        
        // Recalculate heights if needed
        if fullHeight == 0 && bounds.width > 0 {
            calculateHeights()
        }
    }
    
    // MARK: - Height Calculations
    
    private func calculateHeights() {
        guard bounds.width > 0 && bounds.height > 0 else { return }
        
        // Calculate line height from the font
        let theme = lexicalView.editor.getTheme()
        let font = theme.text?[.font] as? UIFont ?? UIFont.systemFont(ofSize: 16)
        let lineHeight = font.lineHeight
        
        // Account for button space (button height + padding)
        let buttonAreaHeight: CGFloat = 32 + 16 // button height + top/bottom padding
        
        // Calculate collapsed height (maxLines * lineHeight + text padding)
        let textInsets = lexicalView.textView.textContainerInset
        collapsedHeight = (lineHeight * CGFloat(maxLines)) + textInsets.top + textInsets.bottom + 16
        
        // Calculate full content height - account for available space minus button area
        let availableHeight = bounds.height - buttonAreaHeight
        let containerSize = CGSize(width: bounds.width, height: .greatestFiniteMagnitude)
        let padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        let contentHeight = lexicalView.calculateTextViewHeight(for: containerSize, padding: padding)
        
        // Full height should not exceed available space
        fullHeight = min(contentHeight, availableHeight)
        
        updateViewState()
    }
    
    private func updateViewState() {
        let shouldShowButton = fullHeight > collapsedHeight + 20 // Add some tolerance
        
        if shouldShowButton {
            expandButton.isHidden = false
            gradientView.isHidden = isExpanded
            
            let targetHeight = isExpanded ? fullHeight : collapsedHeight
            expandButton.setTitle(isExpanded ? "Show less" : "Show more", for: .normal)
            
            // Ensure minimum height to prevent constraint conflicts
            heightConstraint.constant = max(targetHeight, 100)
        } else {
            expandButton.isHidden = true
            gradientView.isHidden = true
            heightConstraint.constant = max(fullHeight, 100) // Minimum height
        }
    }
    
    // MARK: - Actions
    
    @objc private func toggleExpansion() {
        isExpanded.toggle()
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut) {
            self.updateViewState()
            self.layoutIfNeeded()
        }
    }
    
    // MARK: - Public Methods
    
    func updateContent() {
        // Recalculate when content changes
        DispatchQueue.main.async {
            self.calculateHeights()
        }
    }
    
    // Expose the underlying LexicalView for external access
    var underlyingLexicalView: LexicalView {
        return lexicalView
    }
}
