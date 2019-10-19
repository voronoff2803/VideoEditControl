//
//  ViewController.swift
//  VideoEditControl
//
//  Created by Алексей Воронов on 13.10.2019.
//  Copyright © 2019 Алексей Воронов. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    func setup() {
        let label = UILabel(frame: CGRect(x: 0, y: 40, width: 375, height: 100))
        label.numberOfLines = 3
        // COMMENT: лишний self.
        self.view.addSubview(label)
        
        // COMMENT: force-unwrap
        let url = Bundle.main.url(forResource: "video", withExtension: "mp4")!
        let asset = AVAsset(url: url)
        
        let controlView = VideoTrimView(frame: CGRect(x: 0, y: 150, width: 375, height: 70), asset: asset, valueChanged: { start, end, current in
            label.text = "start = \(start)\nend = \(end)\ncurrent = \(current)"
        })
        self.view.addSubview(controlView)
        
        let controlView2 = VideoTrimView(frame: CGRect(x: 0, y: 250, width: 375, height: 170), asset: asset, valueChanged: { start, end, current in
            label.text = "start = \(start)\nend = \(end)\ncurrent = \(current)"
        })
        self.view.addSubview(controlView2)
    }
}

