//
//  ViewController.swift
//  TRSegment
//
//  Created by leotao on 2020/9/20.
//

import UIKit
import SnapKit

class ViewController: UIViewController {
    
    lazy var binder: TRSegmentBinder = {
        var config = TRSegment.Config()
        config.indicator.percentage = 0.8
        config.indicator.height = 4
        config.indicator.cornerRadius = 2
        
        let vc1 = ViewController1()
        let vc2 = ViewController2()
        let vc3 = ViewController3()
        
        return TRSegmentBuilder()
            .set(titles: ["测试1", "hell world", "你好"])
            .set(config: config)
            .set(parentVC: self)
            .set(childVCs: [vc1, vc2, vc3])
            .build()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        self.view.addSubview(binder.segment)
        self.view.addSubview(binder.content)
        
        binder.segment.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            maker.height.equalTo(55)
        }
        
        binder.content.snp.makeConstraints { (maker) in
            maker.left.right.bottom.equalToSuperview()
            maker.top.equalTo(binder.segment.snp.bottom)
        }
        
        binder.segment.delegate = self
        binder.content.delegate = self
    }
}

extension ViewController: TRSegmentDelegate {
    func segment(_ segment: TRAbstractSegment, didSelect index: UInt) {
        print(#function)
    }
}

extension ViewController: TRSegmentContentViewDelegate {
    func segmentContentView(_ contentView: TRAbstractSegmentContentView, didSelectedIndex index: UInt) {
        print(#function)
    }
}

