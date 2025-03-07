///
/// MIT License
///
/// Copyright (c) 2020 Mac Gallagher
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in all
/// copies or substantial portions of the Software.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
/// SOFTWARE.
///

import UIKit

@objc
public protocol MultiProgressViewDataSource: AnyObject {
  func numberOfSections(in progressView: MultiProgressView) -> Int
  func progressView(_ progressView: MultiProgressView,
                    viewForSection section: Int) -> ProgressViewSection
}

@objc
public protocol MultiProgressViewDelegate: AnyObject {
  @objc
  optional func progressView(_ progressView: MultiProgressView, didTapSectionAt index: Int)
}

@IBDesignable
open class MultiProgressView: UIView, ProgressViewSectionDelegate {

  @IBOutlet public weak var dataSource: MultiProgressViewDataSource? {
    didSet {
      reloadData()
    }
  }

  @IBOutlet public weak var delegate: MultiProgressViewDelegate?

  @IBInspectable public var my_cornerRadius: CGFloat = 0 {
    didSet {
      updateCornerRadius()
    }
  }

  @IBInspectable public var borderWidth: CGFloat = 0 {
    didSet {
      layer.borderWidth = borderWidth
    }
  }

  @IBInspectable public var borderColor: UIColor? = .black {
    didSet {
      layer.borderColor = borderColor?.cgColor
    }
  }

  @IBInspectable public var trackInset: CGFloat = 0 {
    didSet {
      setNeedsLayout()
    }
  }

  @IBInspectable public var trackBackgroundColor: UIColor? = .clear {
    didSet {
      track.backgroundColor = trackBackgroundColor
    }
  }

  @IBInspectable public var trackBorderColor: UIColor? = .black {
    didSet {
      track.layer.borderColor = trackBorderColor?.cgColor
    }
  }

  @IBInspectable public var trackBorderWidth: CGFloat = 0 {
    didSet {
      track.layer.borderWidth = trackBorderWidth
    }
  }

  public var trackTitleLabel: UILabel {
    return label
  }

  private var label = UILabel()

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

  public var trackImageView: UIImageView {
    return imageView
  }

  private var imageView = UIImageView()

  public var lineCap: LineCapType = .square {
    didSet {
      setNeedsLayout()
    }
  }

  public var totalProgress: Float {
    return currentProgress.reduce(0) { $0 + $1 }
  }

  lazy var track: UIView = {
    let view = UIView()
    view.layer.masksToBounds = true
    view.addSubview(trackTitleLabel)
    view.addSubview(trackImageView)
    return view
  }()

  /// A map containing the sections of the progress view.
  /// The key is the section and the value is the section's index in the progress view.
  var progressViewSections: [ProgressViewSection: Int] = [:]

  var trackTitleLabelConstraints = [NSLayoutConstraint]() {
    didSet {
      NSLayoutConstraint.deactivate(oldValue)
      NSLayoutConstraint.activate(trackTitleLabelConstraints)
    }
  }

  private var numberOfSections: Int = 0
  private var currentProgress: [Float] = []

  private var layoutProvider: LayoutProvidable = LayoutProvider.shared

  // MARK: - Initialization

  override public init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  convenience init(layoutProvider: LayoutProvidable) {
    self.init(frame: .zero)
    self.layoutProvider = layoutProvider
  }

  private func initialize() {
    layer.masksToBounds = true
    addSubview(track)
  }

  // MARK: - Layout

  override open func layoutSubviews() {
    super.layoutSubviews()
    track.frame = layoutProvider.trackFrame(self)
    trackTitleLabelConstraints = layoutProvider.anchorToSuperview(trackTitleLabel,
                                                                  withAlignment: trackTitleAlignment,
                                                                  insets: trackTitleEdgeInsets)
    imageView.frame = layoutProvider.trackImageViewFrame(self)
    track.sendSubviewToBack(imageView)
    layoutSections()
    updateCornerRadius()
  }

  private func layoutSections() {
    for (section, index) in progressViewSections {
      section.frame = layoutProvider.sectionFrame(self, section: index)
      track.bringSubviewToFront(section)
    }
  }

  func updateCornerRadius() {
    layer.cornerRadius = layoutProvider.cornerRadius(self)
    track.layer.cornerRadius = layoutProvider.trackCornerRadius(self)
  }

  // MARK: - Data Source

  public func reloadData() {
    guard let dataSource = dataSource else { return }
    numberOfSections = dataSource.numberOfSections(in: self)

    progressViewSections.keys.forEach { $0.removeFromSuperview() }
    progressViewSections.removeAll()
    currentProgress.removeAll()

    for index in 0..<numberOfSections {
      configureSection(withDataSource: dataSource, index)
    }
  }

  private func configureSection(withDataSource dataSource: MultiProgressViewDataSource,
                                _ section: Int) {
    let bar = dataSource.progressView(self, viewForSection: section)
    bar.delegate = self
    progressViewSections[bar] = section
    track.addSubview(bar)
    currentProgress.insert(0, at: section)
  }

  // MARK: - Getter/Setter Methods

  public func setTitle(_ title: String?) {
    label.text = title
  }

  public func setAttributedTitle(_ title: NSAttributedString?) {
    label.attributedText = title
  }

  public func setTrackImage(_ image: UIImage?) {
    imageView.image = image
  }

  public func progress(forSection section: Int) -> Float {
    return currentProgress[section]
  }

  // MARK: - Main Methods

  public func setProgress(section: Int, to progress: Float) {
    currentProgress[section] = max(0, min(progress, 1 - totalProgress + currentProgress[section]))
    setNeedsLayout()
    layoutIfNeeded()
  }

  public func resetProgress() {
    for section in 0..<progressViewSections.count {
      setProgress(section: section, to: 0)
    }
  }

  // MARK: - ProgressViewSectionDelegate

  func didTapSection(_ section: ProgressViewSection) {
    if let index = progressViewSections[section] {
      delegate?.progressView?(self, didTapSectionAt: index)
    }
  }
}
