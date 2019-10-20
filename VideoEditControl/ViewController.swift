//
//  ViewController.swift
//  VideoEditControl
//
//  Created by Алексей Воронов on 13.10.2019.
//  Copyright © 2019 Алексей Воронов. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVPlayerItemOutputPushDelegate {
    
    @IBOutlet weak var trimView: VideoTrimView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var playerView: UIView!
    
    var player: AVPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    func setup() {
        guard let url = Bundle.main.url(forResource: "video", withExtension: "mp4") else { return }
        let asset = AVAsset(url: url)
        

        let myPlayer = AVPlayer(url: url)
        self.player = myPlayer
        
        myPlayer.addPeriodicTimeObserver(forInterval: CMTime.init(value: 1, timescale: 60), queue: .main, using: { time in
            if let durationCM = myPlayer.currentItem?.duration {
                let duration = CMTimeGetSeconds(durationCM), time = CMTimeGetSeconds(time)
                
                if time > duration * Float64(self.trimView.endValue) {
                    self.player?.seek(to: CMTime(seconds: duration * Double(self.trimView.startValue) + 0.25, preferredTimescale: durationCM.timescale))
                }
                
                if time < duration * Float64(self.trimView.startValue) {
                    self.player?.seek(to: CMTime(seconds: duration * Double(self.trimView.startValue), preferredTimescale: durationCM.timescale))
                }
                
                let progress = (time / duration)
                self.trimView.setCurrentValue(CGFloat(progress))
            }
        })
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = playerView.bounds
        playerView.layer.addSublayer(playerLayer)
        player?.play()
        
        trimView.videoAsset = asset
        trimView.scrollOnField = true
        trimView.endInteracting = {
            self.updateValues()
            self.player?.play()
        }
        trimView.beginInteracting = {
            self.player?.pause()
        }
    }
    
    func updateValues() {
        label.text = "start = \(trimView.startValue)\n end = \(trimView.endValue)\n currnt = \(trimView.currentValue)"
        guard let duration = player?.currentItem?.duration else { return }
        self.player?.seek(to: CMTime(seconds: duration.seconds * Double(self.trimView.currentValue) + 0.25, preferredTimescale: duration.timescale))
    }
}

