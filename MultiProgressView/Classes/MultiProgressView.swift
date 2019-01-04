//
//  MGSegmentedProgressBar.swift
//  MultiProgressView
//
//  Created by Mac Gallagher on 6/15/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit

open class MultiProgressView: UIView {
    public var dataSource: MultiProgressViewDataSource? {
        didSet {
            reloadData()
        }
    }
    
    public var cornerRadius: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    public var borderColor: UIColor? = .black {
        didSet {
            layer.borderColor = borderColor?.cgColor
        }
    }
    
    public var trackInset: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var trackBackgroundColor: UIColor? = .white {
        didSet {
            track.backgroundColor = trackBackgroundColor
        }
    }
    
    public var trackBorderColor: UIColor? = .black {
        didSet {
            track.layer.borderColor = trackBorderColor?.cgColor
        }
    }
    
    public var trackBorderWidth: CGFloat = 0 {
        didSet {
            track.layer.borderWidth = trackBorderWidth
        }
    }
    
    public var trackTitleLabel: UILabel? {
        return label
    }
    
    private var label: UILabel?
    
    public var trackTitleEdgeInsets: UIEdgeInsets = .zero {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var trackTitleAlignment: AlignmentType = .center {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var trackImageView: UIImageView? {
        return imageView
    }
    
    private var imageView: UIImageView?
    
    public var lineCap: LineCapType = .round {
        didSet {
            setNeedsLayout()
        }
    }
    
    private let track: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()
    
    private var progressBarSections: [ProgressViewSection] = []
    private var numberOfSections: Int = 0
    private var currentSteps: [Int] = []
    private var totalSteps: Int = 0
    private var totalRemainingSteps: Int {
        return totalSteps - totalProgress()
    }
    
    //MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        backgroundColor = .white
        clipsToBounds = true
        addSubview(track)
    }
    
    //MARK: - Layout
    
    private var progressBarConstraints = [NSLayoutConstraint]() {
        didSet {
            NSLayoutConstraint.deactivate(oldValue)
            NSLayoutConstraint.activate(progressBarConstraints)
        }
    }
    
    private var labelConstraints = [NSLayoutConstraint]() {
        didSet {
            NSLayoutConstraint.deactivate(oldValue)
            NSLayoutConstraint.activate(labelConstraints)
        }
    }
    
    private var imageViewConstaints = [NSLayoutConstraint]() {
        didSet {
            NSLayoutConstraint.deactivate(oldValue)
            NSLayoutConstraint.activate(imageViewConstaints)
        }
    }
    
    private var barSectionConstraints = [[NSLayoutConstraint]]()
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        progressBarConstraints = track.anchorToSuperview(withCapType: lineCap, padding: trackInset)
        labelConstraints = trackTitleLabel?.anchorToSuperview(withAlignment: trackTitleAlignment, insets: trackTitleEdgeInsets) ?? []
        imageViewConstaints = imageView?.anchorToSuperview() ?? []
        
        for (index, bar) in progressBarSections.enumerated() {
            layoutBar(bar, section: index)
        }
        
        if let imageView = imageView {
            track.sendSubviewToBack(imageView)
        }
        applyCornerRadius()
    }

    private func layoutBar(_ bar: ProgressViewSection, section: Int) {
        if totalSteps <= 0 { return }
        
        NSLayoutConstraint.deactivate(barSectionConstraints[section])
        var barConstraints = [NSLayoutConstraint]()
        
        if section == 0 {
            barConstraints.append(contentsOf: bar.anchor(top: track.topAnchor, left: track.leftAnchor, bottom: track.bottomAnchor))
        } else {
            barConstraints.append(contentsOf: bar.anchor(top: track.topAnchor, left: progressBarSections[section - 1].rightAnchor, bottom: track.bottomAnchor))
        }
        
        let widthMultiplier = CGFloat(currentSteps[section]) / CGFloat(totalSteps)
        let widthConstraint = bar.widthAnchor.constraint(equalTo: track.widthAnchor, multiplier: widthMultiplier)
        barConstraints.append(widthConstraint)
        
        NSLayoutConstraint.activate(barConstraints)
        barSectionConstraints[section] = barConstraints
    }
    
    private func applyCornerRadius() {
        switch lineCap {
        case .round:
            layer.cornerRadius = cornerRadius == 0 ? bounds.height / 2 : cornerRadius
            track.layer.cornerRadius = cornerRadius == 0 ? bounds.height / 2 : cornerRadius
        case .butt, .square:
            layer.cornerRadius = 0
            track.layer.cornerRadius = 0
        }
    }
    
    //MARK: - Data Source
    
    public func reloadData() {
        guard let dataSource = dataSource else { return }
        numberOfSections = dataSource.numberOfSections(in: self)
        totalSteps = dataSource.numberOfUnits(in: self)
        
        progressBarSections.forEach({ $0.removeFromSuperview() })
        progressBarSections.removeAll()
        currentSteps.removeAll()
        barSectionConstraints.removeAll()

        for index in 0..<numberOfSections {
            configureSection(index)
        }
    }
    
    private func configureSection(_ section: Int) {
        guard let dataSource = dataSource else { return }
        let bar = dataSource.progressView(self, viewForSection: section)
        progressBarSections.insert(bar, at: section)
        track.addSubview(bar)
        currentSteps.insert(0, at: section)
        barSectionConstraints.insert([], at: section)
    }
    
    //MARK: - Main Methods
    
    public func setTitle(_ title: String?) {
        createTitleLabelIfNeeded()
        label?.text = title
    }
    
    public func setAttributedTitle(_ title: NSAttributedString?) {
        createTitleLabelIfNeeded()
        label?.attributedText = title
    }
    
    private func createTitleLabelIfNeeded() {
        guard trackTitleLabel == nil else { return }
        let title = UILabel()
        track.insertSubview(title, at: 0)
        label = title
    }
    
    public func setTrackImage(_ image: UIImage?) {
        guard let image = image else { return }
        createTrackImageViewIfNeeded()
        imageView?.image = image
    }
    
    private func createTrackImageViewIfNeeded() {
        guard imageView == nil else { return }
        let iv = UIImageView()
        track.addSubview(iv)
        imageView = iv
    }
    
    public func progress(forSection section: Int) -> Int {
        return currentSteps[section]
    }
    
    public func totalProgress() -> Int {
        return currentSteps.reduce(0) { $0 + $1 }
    }
    
    public func setProgress(section: Int, to units: Int) {
        currentSteps[section] = max(0, min(units, totalRemainingSteps + currentSteps[section]))
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    public func advance(by units: Int = 1, section: Int) {
        setProgress(section: section, to: currentSteps[section] + units)
    }

    public func resetProgress() {
        for section in 0..<progressBarSections.count {
            setProgress(section: section, to: 0)
        }
    }
}
