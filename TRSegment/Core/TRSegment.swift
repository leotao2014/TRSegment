//
//  TRSegment.swift
//  TRSegment
//
//  Created by leotao on 2020/9/20.
//

import UIKit
import Foundation

protocol TRSegmentDelegate: class {
    func segment(_ segment: TRAbstractSegment, didClick index: UInt)
    func segment(_ segment: TRAbstractSegment, didSelect index: UInt)
}

extension TRSegmentDelegate {
    func segment(_ segment: TRAbstractSegment, didClick index: UInt) {}
    func segment(_ segment: TRAbstractSegment, didSelect index: UInt) {}
}

class TRAbstractSegment: UIView {
    weak var delegate: TRSegmentDelegate?
    
    private var delegates: NSHashTable = NSHashTable<AnyObject>(options: [.weakMemory])
    
    func add(delegate: TRSegmentDelegate) {
        delegates.add(delegate)
    }
    
    func makeSelected(at index: UInt, animated: Bool = false) {}
}

extension TRAbstractSegment: TRSegmentDelegate {
    func segment(_ segment: TRAbstractSegment, didClick index: UInt) {
        delegate?.segment(self, didClick: index)
        delegates.allObjects.forEach { (delegate) in
            (delegate as? TRSegmentDelegate)?.segment(self, didClick: index)
        }
    }
    
    func segment(_ segment: TRAbstractSegment, didSelect index: UInt) {
        delegate?.segment(self, didSelect: index)
        delegates.allObjects.forEach { (delegate) in
            (delegate as? TRSegmentDelegate)?.segment(self, didSelect: index)
        }
    }
}

class TRSegment: TRAbstractSegment {
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = self.config.bounces
        
        return scrollView
    }()
    
    private lazy var indicator: UIView = {
        let view = UIView()
        if config.indicator.cornerRadius > 0 {
            view.layer.cornerRadius = config.indicator.cornerRadius
        }
        
        view.backgroundColor = config.indicator.backgroundColor
        
        return view
    }()
    
    private var config: Config
    private var btns: [UIButton] = []
    private var selectedBtn: UIButton?
    private var initialSelectedIndex: UInt
    
    convenience init(titles: [String], selecteIndex: UInt = 0) {
        self.init(titles: titles, selectedIndex: selecteIndex, config: nil)
    }
    
    convenience init(titles: [String], config: Config) {
        self.init(titles: titles, selectedIndex: 0, config: config)
    }
        
    required init(titles: [String], selectedIndex: UInt, config: Config?) {
        self.initialSelectedIndex = selectedIndex
        if let cg = config {
            self.config = cg
        } else {
            self.config = Config()
        }
        
        super.init(frame: .zero)
        
        addSubview(scrollView)
        addSubview(indicator)
        btns = titles.map { (title) -> UIButton in
            return self.createBtn(title: title)
        }
        
        btns.forEach { (btn) in
            scrollView.addSubview((btn))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: self.contentWidth, height: 0)
    }

    override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
        return .zero
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard btns.count > 0 else {
            return
        }
                
        btns.enumerated().forEach { (index, btn) in
            let left: CGFloat
            if index == 0 {
                left = config.insets.left
            } else {
                let last = btns[index - 1]
                left = last.frame.maxX + config.insets.between
            }
            
            let size = btn.titleLabel?.intrinsicContentSize ?? CGSize.zero
            btn.tag = index
            btn.frame = CGRect(x: left, y: 0, width: size.width, height: size.height)
        }
        
        let scrollViewHeight = btns.first?.frame.height ?? 0
        let scrollViewTop = (self.bounds.height - scrollViewHeight) * 0.5
        scrollView.frame = CGRect(x: 0, y: scrollViewTop, width: self.bounds.width, height: scrollViewHeight)
        
        let contentWidth = btns.last?.frame.maxX ?? 0 + config.insets.right
        scrollView.contentSize = CGSize(width: contentWidth, height: scrollViewHeight)
        
        indicator.frame = indicatorFrame()
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if let _ = self.window, self.selectedBtn == nil {
            makeSelected(at: self.initialSelectedIndex)
        }
    }
    
    override func makeSelected(at index: UInt, animated: Bool = false) {
        if let btn = self.selectedBtn, index == btn.tag {
            return
        }
        
        guard index < self.btns.count else {
            return
        }
        
        let btn = self.btns[Int(index)]
        makeSelcted(btn: btn, animated: animated)
        segment(self, didSelect: index)
    }
}

// MARK: Layout
extension TRSegment {
    var contentWidth: CGFloat {
        if btns.count == 0 {
            return 0.0
        }
        
        var allBtnWidth: CGFloat = config.insets.left
        btns.forEach { (btn) in
            allBtnWidth += config.insets.between
            allBtnWidth += (btn.titleLabel?.intrinsicContentSize.width ?? 0)
        }
        
        allBtnWidth += config.insets.right
        
        return allBtnWidth
    }
    
    func indicatorFrame() -> CGRect {
        guard let selectedBtn = self.selectedBtn else { return .zero }
        
        let indicatorWidth = config.indicator.additionalWidth + config.indicator.percentage * selectedBtn.frame.width
        let indicatorLeft = selectedBtn.frame.midX - indicatorWidth * 0.5
        let indicatorHeight = config.indicator.height
        let indicatorTop: CGFloat
        
        switch config.indicator.position {
        case .belowTitle(let margin):
            indicatorTop = scrollView.frame.maxY + margin
        case .nextToTheBottom(let margin):
            indicatorTop = self.bounds.height - indicatorHeight - margin
        }
        
        let frame = CGRect(x: indicatorLeft, y: indicatorTop, width: indicatorWidth, height: indicatorHeight)
        return frame
    }
}

// MARK: Helper
extension TRSegment {
    private func createBtn(title: String) -> UIButton {
        let btn = UIButton()
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(self.config.title.colorForNormal, for: .normal)
        btn.setTitleColor(self.config.title.colorForSelected, for: .selected)
        btn.titleLabel?.font = self.config.title.fontForNormal
        btn.addTarget(self, action: #selector(onClick(btn:)), for: .touchUpInside)
        
        return btn
    }
}

// MARK: Actions
extension TRSegment {
    @objc func onClick(btn: UIButton) {
        makeSelcted(btn: btn, animated: true)
    }
}

extension TRSegment {
    func makeSelcted(btn: UIButton, animated: Bool = false) {
        guard btn != self.selectedBtn else {
            return
        }
        
        
        segment(self, didClick: UInt(btn.tag))
        segment(self, didSelect: UInt(btn.tag))
        
        makeBtnSelected(btn: self.selectedBtn, selected: false)
        self.selectedBtn?.isSelected = false

        makeBtnSelected(btn: btn, selected: true)
        btn.isSelected = true
        
        self.selectedBtn = btn
        
        if animated {
            let nextFrame = self.indicatorFrame()
            UIView.animate(withDuration: 0.25) {
                self.indicator.frame = nextFrame
            }
        } else {
            indicator.frame = indicatorFrame()
        }
    }
    
    private func makeBtnSelected(btn: UIButton?, selected: Bool) {
        guard let btn = btn else { return }
        
        let btnCenter = btn.center.x
        btn.titleLabel?.font = selected ? config.title.fontForSelected : config.title.fontForNormal
        btn.bounds.size = btn.titleLabel?.intrinsicContentSize ?? .zero
        btn.center.x = btnCenter
    }
}

extension TRSegment {
    struct Config {
        var title = Title()
        var indicator = Indicator()
        var insets = Insets()
        var bounces = false
    }
}

extension TRSegment.Config {
    struct Insets {
        var left: CGFloat = 10
        var right: CGFloat = 10
        var between: CGFloat = 10
    }
    
    struct Title {
        var colorForSelected = UIColor.cyan
        var colorForNormal = UIColor.black
        var fontForSelected = UIFont.systemFont(ofSize: 17, weight: .medium)
        var fontForNormal = UIFont.systemFont(ofSize: 17)
    }
    
    struct Indicator {
        var height: CGFloat = 2
        var backgroundColor = UIColor.blue
        var additionalWidth: CGFloat = 0
        var percentage: CGFloat = 1.0
        var cornerRadius: CGFloat = 0
        var position = Position.nextToTheBottom(margin: 0)
    }
}

extension TRSegment.Config.Indicator {
    enum Position {
        case belowTitle(margin: CGFloat)
        case nextToTheBottom(margin: CGFloat)
    }
}
