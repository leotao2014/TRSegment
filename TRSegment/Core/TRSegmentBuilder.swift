//
//  TRSegmentBuilder.swift
//  TRSegment
//
//  Created by leotao on 2020/9/20.
//

import UIKit

class TRSegmentBuilder {
    private var titles: [String] = []
    private var config: TRSegment.Config? = nil
    private var selectedIndex: UInt = 0
    private var childVCs: [UIViewController] = []
    private var parentVC: UIViewController?
    
    func set(titles: [String]) -> Self {
        self.titles = titles
        
        return self
    }
    
    func set(config: TRSegment.Config) -> Self {
        self.config = config
        
        return self
    }
    
    func set(childVCs: [UIViewController]) -> Self {
        self.childVCs = childVCs
        
        return self
    }
    
    func set(selectedIndex: UInt) -> Self {
        self.selectedIndex = selectedIndex
        
        return self
    }
    
    func set(parentVC: UIViewController) -> Self {
        self.parentVC = parentVC
        
        return self
    }
    
    func build() -> TRSegmentBinder {
        let segment = TRSegment(titles: self.titles, selectedIndex: self.selectedIndex, config: self.config)
        
        let content = TRSegmentContentView(parentVC: self.parentVC, childVCs: self.childVCs)
        let binder = TRSegmentBinder(segment: segment, content: content)
        
        return binder
    }
}
