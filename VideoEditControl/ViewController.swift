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
        
        myPlayer.addPeriodicTimeObserver(forInterval: CMTime.init(value: 1, timescale: 60), queue: .main, using: { [weak self] time in
            guard self?.player.assertingNonNil?.rate != 0 else { return }
            // ставить в контрол текущую позицию
            
            if let durationCM = myPlayer.currentItem?.duration {
                let duration = CMTimeGetSeconds(durationCM), time = CMTimeGetSeconds(time)
                
                if time > duration * Float64(self.trimView.endValue) {
                    self.player?.seek(to: CMTime(seconds: duration * Double(self.trimView.startValue), preferredTimescale: durationCM.timescale), toleranceBefore: .zero, toleranceAfter: .zero)
                }
                
                if time < duration * Float64(self.trimView.startValue) - 0.1 {
                    self.player?.seek(to: CMTime(seconds: duration * Double(self.trimView.startValue), preferredTimescale: durationCM.timescale), toleranceBefore: .zero, toleranceAfter: .zero)
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
        
        trimView.currentTimeDidChange = { time in
            let pos = (self.player?.currentItem?.duration.seconds).assertNonNilOrDefaultValue * time.dbl
            self.player?.seek(to: CMTime(seconds: pos, preferredTimescale: self.player?.currentItem?.duration.timescale ?? 0), toleranceBefore: .zero, toleranceAfter: .zero)
        }
    }
    
    func updateValues() {
        label.text = "start = \(trimView.startValue)\n end = \(trimView.endValue)\n currnt = \(trimView.currentValue)"
        guard let duration = player?.currentItem?.duration else { return }
        self.player?.seek(to: CMTime(seconds: duration.seconds * Double(self.trimView.currentValue), preferredTimescale: duration.timescale), toleranceBefore: .zero, toleranceAfter: .zero)
    }
}

extension AVPlayer {
    
    func seekWithZeroTolerance(to normalizedPosition: Double) {
        
    }
    
    func seek(to normalizedPosition: Double, toleranceBefore: CMTime, toleranceAfter: CMTime) {
        
    }
    
    var normalizedPosition: Double { currentTime() / d }
}
