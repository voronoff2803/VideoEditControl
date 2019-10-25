//
//  AVPlayer+NormalizedPositionAndNormalizedSeek.swift
//  VideoEditControl
//
//  Created by Bogdan Pashchenko on 26.10.2019.
//  Copyright © 2019 Алексей Воронов. All rights reserved.
//

import AVFoundation.AVPlayer

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
        guard currentItem?.status == .readyToPlay, let duration = currentItem?.duration.seconds, let time = currentItem?.currentTime().seconds else { return 0.0 }
        let progress = (time / duration)
        return progress
    }
}
