//
//  ViewController.swift
//  VideoEditControl
//
//  Created by Алексей Воронов on 13.10.2019.
//  Copyright © 2019 Алексей Воронов. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class ViewController: UIViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.setup()
    }
    
    func setup() {
        let label = UILabel(frame: CGRect(x: 0, y: 40, width: 375, height: 100))
        label.numberOfLines = 3
        self.view.addSubview(label)
        
        let url = Bundle.main.url(forResource: "video", withExtension: "mp4")!
        let asset = AVAsset(url: url)
        
        let controlView = VideoTrimControl(asset: asset, frame: CGRect(x: 0, y: 200, width: 375, height: 60), valueChanged: { startValue, endValue, currentValue in
            label.text = "start: \(startValue)\n end: \(endValue)\n current: \(currentValue)"
        })
        self.view.addSubview(controlView)
        
        let controlView2 = VideoTrimControl(asset: asset, frame: CGRect(x: 10, y: 300, width: 355, height: 40), valueChanged: { startValue, endValue, currentValue in
            label.text = "start: \(startValue)\n end: \(endValue)\n current: \(currentValue)"
        })
        self.view.addSubview(controlView2)
        
        let controlView3 = VideoTrimControl(asset: asset, frame: CGRect(x: 20, y: 400, width: 275, height: 130), valueChanged: { startValue, endValue, currentValue in
            label.text = "start: \(startValue)\n end: \(endValue)\n current: \(currentValue)"
        })
        self.view.addSubview(controlView3)
    }
}

