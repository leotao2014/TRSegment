//
//  TRSegmentContentView.swift
//  TRSegment
//
//  Created by leotao on 2020/9/20.
//

import UIKit

protocol TRSegmentContentViewDelegate: class {
    func segmentContentView(_ contentView: TRAbstractSegmentContentView, progress: CGFloat, originalIndex: UInt, targetIndex: UInt)
    func segmentContentView(_ contentView: TRAbstractSegmentContentView, didSelectedIndex index: UInt)
    func segmentContentViewWillBeginDragging(_ contentView: TRAbstractSegmentContentView)
    func segmentContentViewDidEndDecelerating(_ contentView: TRAbstractSegmentContentView)
}

extension TRSegmentContentViewDelegate {
    func segmentContentView(_ contentView: TRAbstractSegmentContentView, progress: CGFloat, originalIndex: UInt, targetIndex: UInt) {}
    func segmentContentView(_ contentView: TRAbstractSegmentContentView, didSelectedIndex index: UInt) {}
    func segmentContentViewWillBeginDragging(_ contentView: TRAbstractSegmentContentView) {}
    func segmentContentViewDidEndDecelerating(_ contentView: TRAbstractSegmentContentView) {}
}

class TRAbstractSegmentContentView: UIView {
    weak var delegate: TRSegmentContentViewDelegate?
    
    private var delegates: NSHashTable = NSHashTable<AnyObject>(options: [.weakMemory])
    
    func add(delegate: TRSegmentDelegate) {
        delegates.add(delegate)
    }
    
    func makeSelected(at index: UInt) {}
}

extension TRAbstractSegmentContentView: TRSegmentContentViewDelegate {
    private var allDelegates: [TRSegmentContentViewDelegate] {
        var all: [TRSegmentContentViewDelegate] = []
        if let ds = (delegates.allObjects as? [TRSegmentContentViewDelegate]) {
            all.append(contentsOf: ds)
        }
        
        if let dl = delegate {
            all.append(dl)
        }
        
        return all
    }
    
    func segmentContentView(_ contentView: TRAbstractSegmentContentView, progress: CGFloat, originalIndex: UInt, targetIndex: UInt) {
        allDelegates.forEach { (delegate) in
            delegate.segmentContentView(contentView, progress: progress, originalIndex: originalIndex, targetIndex: targetIndex)
        }
    }
    
    func segmentContentView(_ contentView: TRAbstractSegmentContentView, didSelectedIndex index: UInt) {
        allDelegates.forEach { (delegate) in
            delegate.segmentContentView(contentView, didSelectedIndex: index)
        }
    }
    
    func segmentContentViewWillBeginDragging(_ contentView: TRAbstractSegmentContentView) {
        allDelegates.forEach { (delegate) in
            delegate.segmentContentViewWillBeginDragging(contentView)
        }
    }
    
    func segmentContentViewDidEndDecelerating(_ contentView: TRAbstractSegmentContentView) {
        allDelegates.forEach { (delegate) in
            delegate.segmentContentViewDidEndDecelerating(contentView)
        }
    }
}



class TRSegmentContentView: TRAbstractSegmentContentView {
    private weak var parentVC: UIViewController?
    private var childVCs: [UIViewController]
    
    private var startOffsetX: CGFloat = 0
    private var isScrolling = false
    private var previousCVC: UIViewController?
    private var selectedIndex: UInt = UInt.max
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        scrollView.bounces = self.bounces
        
        return scrollView
    }()
    
    var bounces: Bool = false {
        didSet {
            scrollView.bounces = bounces
        }
    }
    
    init(parentVC: UIViewController?, childVCs: [UIViewController]) {
        self.parentVC = parentVC
        self.childVCs = childVCs
        
        super.init(frame: .zero)
        
        addSubview(scrollView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        scrollView.frame = self.bounds
        
        let width = scrollView.bounds.width * CGFloat(self.childVCs.count)
        scrollView.contentSize = CGSize(width: width, height: scrollView.bounds.height)
        
        if self.selectedIndex < self.childVCs.count {
            scrollView.contentOffset.x = scrollView.bounds.width * CGFloat(self.selectedIndex)
        }
        
        guard let parentVC = self.parentVC else { return }
        
        let childVCWidth = scrollView.bounds.width
        let childVCHeight = scrollView.bounds.height
       
        childVCs.enumerated().forEach { (index, vc) in
            if parentVC.children.contains(vc) {
                vc.view.frame = CGRect(x: CGFloat(index) * childVCWidth, y: 0, width: childVCWidth, height: childVCHeight)
            }
        }
    }
    
    override func makeSelected(at index: UInt) {
        guard index < self.childVCs.count else {
            return
        }
        
        guard index != self.selectedIndex else {
            return
        }
        
        self.selectedIndex = index
        self.scrollView.contentOffset.x = CGFloat(index) * self.scrollView.bounds.width
        
        let childVC: UIViewController = childVCs[Int(index)]
        var needTransition = false
        if let pre = previousCVC, childVC != pre {
            needTransition = true
        }
        
        if needTransition {
            previousCVC?.beginAppearanceTransition(false, animated: false)
        }
        
        var firstAdd = false
        if let parentVC = parentVC, parentVC.contains(childVC) == false {
            parentVC.addChild(childVC)
            firstAdd = true
        }
        
        childVC.beginAppearanceTransition(true, animated: false)
        
        if firstAdd {
            scrollView.addSubview(childVC.view)
            childVC.view.frame = CGRect(x: CGFloat(index) * self.scrollView.bounds.width, y: 0, width: self.scrollView.bounds.width, height: self.scrollView.bounds.height)
        }
        
        if needTransition {
            previousCVC?.endAppearanceTransition()
        }
        
        childVC.endAppearanceTransition()
        
        if firstAdd {
            childVC.didMove(toParent: parentVC)
        }
        
        previousCVC = childVC
        
        segmentContentView(self, didSelectedIndex: UInt(index))
    }
}

extension TRSegmentContentView: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        startOffsetX = scrollView.contentOffset.x
        isScrolling = true
        
        segmentContentViewWillBeginDragging(self)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isScrolling = false
        let index: Int = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        makeSelected(at: UInt(index))
        segmentContentViewDidEndDecelerating(self)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isScrolling == false {
            return
        }
        
        var progress: CGFloat = 0.0
        var originalIndex: Int = 0
        var targetIndex: Int = 0
        
        let currentOffsetX: CGFloat = scrollView.contentOffset.x
        let scrollViewW: CGFloat = scrollView.bounds.size.width
        if currentOffsetX > startOffsetX {
            progress = currentOffsetX / scrollViewW - floor(currentOffsetX / scrollViewW);
            originalIndex = Int(currentOffsetX / scrollViewW);
            targetIndex = originalIndex + 1;
            if targetIndex >= childVCs.count {
                progress = 1;
                targetIndex = originalIndex;
            }
            if currentOffsetX - startOffsetX == scrollViewW {
                progress = 1;
                targetIndex = originalIndex;
            }
        } else {
            progress = 1 - (currentOffsetX / scrollViewW - floor(currentOffsetX / scrollViewW));
            targetIndex = Int(currentOffsetX / scrollViewW);
            originalIndex = targetIndex + 1;
            if originalIndex >= childVCs.count {
                originalIndex = childVCs.count - 1;
            }
        }
        
        segmentContentView(self, progress: progress, originalIndex: UInt(originalIndex), targetIndex: UInt(targetIndex))
    }
}
