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
        player = myPlayer
        
        myPlayer.addPeriodicTimeObserver(forInterval: CMTime.init(value: 1, timescale: 60), queue: .main, using: { [weak self] _ in
            self?.trimView.currentValue =  myPlayer.normalizedPosition
            if myPlayer.normalizedPosition == 1.0 {
                myPlayer.seekWithZeroTolerance(toNormalizedPosition: self?.trimView.startValue ?? 0.0)
                
                // Если сразу вызвать Play() - то он не сработает
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                    myPlayer.play()
                })
            }
            
        })
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = playerView.bounds
        playerView.layer.addSublayer(playerLayer)
        player?.play()
        
        trimView.videoAsset = asset
        trimView.panOnThumbnailsMovesCurrentPositionIndicator = true
        trimView.endInteracting = {
            self.updateValues()
            self.player?.play()
        }
        trimView.beginInteracting = {
            self.player?.pause()
        }
        
        trimView.currentTimeDidChange = { currentValue in
            self.player?.seekWithZeroTolerance(toNormalizedPosition: currentValue)
        }
    }
    
    func updateValues() {
        label.text = "start = \(trimView.startValue)\n end = \(trimView.endValue)\n currnt = \(trimView.currentValue)"
        guard let duration = player?.currentItem?.duration else { return }
        player?.seek(to: CMTime(seconds: duration.seconds * Double(trimView.currentValue), preferredTimescale: duration.timescale), toleranceBefore: .zero, toleranceAfter: .zero)
    }
}

extension AVPlayer {
    
    func seekWithZeroTolerance(toNormalizedPosition normalizedPosition: Double) {
        guard let duration = currentItem?.duration else { return }
        seek(to: CMTime(seconds: duration.seconds * normalizedPosition, preferredTimescale: duration.timescale), toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    func seek(toNormalizedPosition normalizedPosition: Double, toleranceBefore: CMTime, toleranceAfter: CMTime) {
        guard let duration = currentItem?.duration else { return }
        seek(to: CMTime(seconds: duration.seconds * normalizedPosition, preferredTimescale: duration.timescale), toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter)
    }
    
    var normalizedPosition: Double {
        guard let duration = currentItem?.duration.seconds, let time = currentItem?.currentTime().seconds else { return 0.0 }
        let progress = (time / duration)
        return progress
    }
}
