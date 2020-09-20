//
//  TRSegmentBinder.swift
//  TRSegment
//
//  Created by leotao on 2020/9/20.
//

import UIKit

class TRSegmentBinder {
    var segment: TRAbstractSegment
    var content: TRAbstractSegmentContentView
    
    init(segment: TRAbstractSegment, content: TRAbstractSegmentContentView) {
        self.segment = segment
        self.content = content
        
        segment.add(delegate: self)
        content.add(delegate: self)
    }
}

extension TRSegmentBinder: TRSegmentDelegate {
    func segment(_ segment: TRAbstractSegment, didSelect index: UInt) {
        self.content.makeSelected(at: index)
    }
}

extension TRSegmentBinder: TRSegmentContentViewDelegate {
    func segmentContentView(_ contentView: TRAbstractSegmentContentView, didSelectedIndex index: UInt) {
        self.segment.makeSelected(at: index, animated: true)
    }
}
