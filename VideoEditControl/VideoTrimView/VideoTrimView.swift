//
//  VideoTrimView.swift
//  VideoEditControl
//
//  Created by Алексей Воронов on 15.10.2019.
//  Copyright © 2019 Алексей Воронов. All rights reserved.
//

import UIKit
import AVFoundation

class VideoTrimView: UIView {
    
    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var leftConstraint: NSLayoutConstraint!
    @IBOutlet weak private var rightConstraint: NSLayoutConstraint!
    @IBOutlet weak private var leftPin: UIView!
    @IBOutlet weak private var rightPin: UIView!
    @IBOutlet weak private var thubnailsView: UIView!
    @IBOutlet weak private var playPinView: UIView!
    @IBOutlet weak private var playPinConstraint: NSLayoutConstraint!
    
    var currentValue: Double {
        get { ((playPinConstraint.constant - leftPin.bounds.width) / (thubnailsView.bounds.width - playPinView.bounds.width)).dbl }
        set {
            if userInteracting { return }
            playPinConstraint.constant = newValue.cg * (thubnailsView.bounds.width - playPinView.bounds.width) + leftPin.bounds.width
            checkValues()
        }
    }
    
    var startValue: Double = 0.0
    var endValue: Double = 1.0
    
    var minimumDurationValue: Float = 0.1
    
    var videoAsset: AVAsset?
    
    var scrollOnField: Bool = false
    
    var currentTimeDidChange: Block<Double>?
    var beginInteracting: VoidBlock?
    var endInteracting: VoidBlock?
    
    private var userInteracting: Bool = false
    
    init(frame: CGRect, asset: AVAsset, scrollOnField: Bool = false, beginInteracting: @escaping () -> (), endInteracting: @escaping () -> ()) {
        self.videoAsset = asset
        self.beginInteracting = beginInteracting
        self.endInteracting = endInteracting
        self.scrollOnField = scrollOnField
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        xibSetup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutIfNeeded()
        setup()
    }
    
    private func xibSetup() {
        Bundle.main.loadNibNamed("VideoTrimView", owner: self, options: nil)
        addSubview(mainView)
        mainView.frame = self.bounds
        mainView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    private func setup() {
        playPinView.layer.cornerRadius = 5
        playPinView.layer.shadowColor = UIColor.black.cgColor
        playPinView.layer.shadowRadius = 5
        playPinView.layer.shadowOpacity = 0.3
        thubnailsView.layer.masksToBounds = true
        
        leftPin.roundCorners(corners: [.topLeft, .bottomLeft], radius: 7)
        rightPin.roundCorners(corners: [.topRight, .bottomRight], radius: 7)
        
        let dragRightPinGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(dragRightPin))
        rightPin.addGestureRecognizer(dragRightPinGestureRecognizer)
        
        let dragLeftPinGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(dragLeftPin))
        leftPin.addGestureRecognizer(dragLeftPinGestureRecognizer)
        
        let dragPlayPinGesture = UIPanGestureRecognizer(target: self, action: #selector(dragPlayPin))
        if scrollOnField {
            self.addGestureRecognizer(dragPlayPinGesture)
        } else {
            playPinView.addGestureRecognizer(dragPlayPinGesture)
        }
        
        guard let videoTrack = videoAsset?.tracks.first else { return }
        addThubnailViews(in: self.thubnailsView, track: videoTrack)
    }
    
    private func countValues() {
        startValue = (leftConstraint.constant / (thubnailsView.bounds.width - playPinView.bounds.width)).dbl
        endValue = (1 - rightConstraint.constant / (thubnailsView.bounds.width - playPinView.bounds.width)).dbl
    }
    
    private func checkValues() {
        countValues()
        if currentValue < startValue {
            currentTimeDidChange?(startValue + 0.001)
        } else if currentValue > endValue {
            currentTimeDidChange?(startValue + 0.001)
        }
    }
    
    private var startX: CGFloat = 0
    
    @objc private func dragPlayPin(_ gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: self)
        let tempValue = mainView.bounds.width - (playPinView.bounds.width + rightConstraint.constant + rightPin.bounds.width)
        if gestureRecognizer.state == .began {
            startX = playPinConstraint.constant
            userInteracting = true
            beginInteracting?()
        } else {
            if leftConstraint.constant + leftPin.bounds.width > startX + translation.x {
                playPinConstraint.constant = leftConstraint.constant + leftPin.bounds.width
            } else if tempValue < startX + translation.x {
                playPinConstraint.constant = mainView.bounds.width - (rightConstraint.constant + rightPin.bounds.width + playPinView.bounds.width)
            } else {
                playPinConstraint.constant = startX + translation.x
            }
        }
        
        if gestureRecognizer.state == .ended {
           userInteracting = false
           endInteracting?()
        }
        
        currentTimeDidChange?(currentValue)
    }
    
    @objc private func dragRightPin(_ gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: self)
        let minDistance = thubnailsView.bounds.width * minimumDurationValue.cg
        let tempValue = mainView.bounds.width - (leftConstraint.constant + rightPin.bounds.width + leftPin.bounds.width + playPinView.bounds.width + minDistance)
        if  gestureRecognizer.state == .began {
            startX = rightConstraint.constant
            userInteracting = true
            beginInteracting?()
        } else {
            if startX - translation.x > tempValue {
                rightConstraint.constant = tempValue
            } else if startX - translation.x < 0 {
                rightConstraint.constant = 0
            } else {
                rightConstraint.constant = startX - translation.x
                countValues()
                currentTimeDidChange?(currentValue)
            }
        }
        keepPlayPinInField()
        if gestureRecognizer.state == .ended {
            countValues()
            userInteracting = false
            endInteracting?()
        }
        
    }
    
    @objc private func dragLeftPin(_ gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: self)
        let minDistance = thubnailsView.bounds.width * minimumDurationValue.cg
        let tempValue = mainView.bounds.width - (rightConstraint.constant + rightPin.bounds.width + leftPin.bounds.width + playPinView.bounds.width + minDistance)
        if  gestureRecognizer.state == .began {
            startX = leftConstraint.constant
            userInteracting = true
            beginInteracting?()
        } else {
            if startX + translation.x > tempValue {
                leftConstraint.constant = tempValue
            } else if startX + translation.x < 0 {
                leftConstraint.constant = 0
            } else {
                countValues()
                currentTimeDidChange?(currentValue)
                leftConstraint.constant = startX + translation.x
            }
        }
        keepPlayPinInField()
        if gestureRecognizer.state == .ended {
            countValues()
            userInteracting = false
            endInteracting?()
        }
    }
    
    private func keepPlayPinInField() {
        if playPinConstraint.constant < leftPin.bounds.width + leftConstraint.constant {
            playPinConstraint.constant = leftPin.bounds.width + leftConstraint.constant
        } else if playPinConstraint.constant > mainView.bounds.width - (rightConstraint.constant + rightPin.bounds.width + playPinView.bounds.width) {
            playPinConstraint.constant = mainView.bounds.width - (rightConstraint.constant + rightPin.bounds.width + playPinView.bounds.width)
        }
    }
    
    private func addThubnailViews(in thubnailView: UIView, track: AVAssetTrack) {
        let views = createThumbnailViews(in: thubnailView.bounds.size, track: track)
        views.forEach(){ thubnailView.addSubview($0) }
    }
    
    private func getThumbnailFrameSizeRatio(track: AVAssetTrack) -> CGFloat {
        let size = track.naturalSize
        return  size.width / size.height
    }
    
    private func getCountOfThubnails(in size: CGSize, track: AVAssetTrack) -> Int {
        let ratio = getThumbnailFrameSizeRatio(track: track)
        let width = size.height * ratio
        return Int(ceil(size.width / width))
    }
    
    private func getThubnailSize(in size: CGSize, track: AVAssetTrack) -> CGSize {
        let ratio = getThumbnailFrameSizeRatio(track: track)
        let width = size.height * ratio
        return CGSize(width: width, height: size.height)
    }
    
    private func createThumbnailViews(in size: CGSize, track: AVAssetTrack) -> [UIImageView] {
        let count = getCountOfThubnails(in: size, track: track)
        let thubnailSize = getThubnailSize(in: size, track: track)
        
        guard let asset = track.asset else { return [] }
        let images = getImagesFromAsset(asset: asset, count: count)
        
        var thubnailViews: [UIImageView] = []
        for i in 0..<count  {
            let frame = CGRect(x: CGFloat(i) * thubnailSize.width, y: 0, width: thubnailSize.width, height: thubnailSize.height)
            let thubnailView = UIImageView(frame: frame)
            thubnailView.image = images[i]
            thubnailView.layer.zPosition = -1
            thubnailViews.append(thubnailView)
        }
        
        return thubnailViews
    }
    
    private func getImagesFromAsset(asset: AVAsset, count: Int) -> [UIImage] {
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        guard let videoTrack = asset.tracks.first else { return [] }
        let trackDuration = videoTrack.timeRange.duration
        let thubnailDuration = trackDuration.seconds / Double(count)
        var images: [UIImage] = []
        
        for i in 0..<count {
            do {
                let image = try imageGenerator.copyCGImage(at: CMTime(seconds: thubnailDuration * Double(i), preferredTimescale: trackDuration.timescale), actualTime: nil)
                images.append(UIImage(cgImage: image))
            } catch {
                assert(false, "imageGenerator failure")
            }
        }
        return images
    }
}
