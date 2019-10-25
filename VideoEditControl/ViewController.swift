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
        if #available(iOS 13.0, *) { overrideUserInterfaceStyle = .light }
    }
    
    func setup() {
        guard let url = Bundle.main.url(forResource: "video", withExtension: "mp4") else { return }
        let asset = AVAsset(url: url)
        
        let myPlayer = AVPlayer(url: url)
        player = myPlayer
        
        myPlayer.addPeriodicTimeObserver(forInterval: CMTime.init(value: 1, timescale: 60), queue: .main, using: { [weak self] _ in
            self?.trimView.currentValue = max(myPlayer.normalizedPosition, 0)
        })
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: .main) { [weak self] _ in
            self?.player?.play()
            self?.player?.seekWithZeroTolerance(toNormalizedPosition: 0)
        }
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = playerView.bounds
        playerView.layer.addSublayer(playerLayer)
        player?.play()
        
        trimView.videoAsset = asset
        trimView.panOnThumbnailsMovesCurrentPositionIndicator = true
        trimView.endInteracting = { [weak self] in
            self?.updateValues()
            self?.player?.play()
        }
        trimView.beginInteracting = { [weak self] in
            self?.player?.pause()
        }
        
        trimView.currentTimeDidChange = { [weak self] currentValue in
            self?.player?.seekWithZeroTolerance(toNormalizedPosition: currentValue)
        }
    }
    
    func updateValues() {
        label.text = "start = \(trimView.startValue)\n end = \(trimView.endValue)\n currnt = \(trimView.currentValue)"
        player?.seek(toNormalizedPosition: trimView.currentValue.dbl, toleranceBefore: .zero, toleranceAfter: .zero)
    }
}
