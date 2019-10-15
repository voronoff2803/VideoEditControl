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
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftPin: UIView!
    @IBOutlet weak var rightPin: UIView!
    @IBOutlet weak var thubnailsView: UIView!
    @IBOutlet weak var playPinView: UIView!
    @IBOutlet weak var playPinConstraint: NSLayoutConstraint!
    
    var currentValue: CGFloat = 0.0
    var startValue: CGFloat = 0.0
    var endValue: CGFloat = 1.0
    
    let videoAsset: AVAsset
    
    let valueChanged: (CGFloat, CGFloat, CGFloat) -> ()
    
    init(frame: CGRect, asset: AVAsset, valueChanged: @escaping (CGFloat, CGFloat, CGFloat) -> ()) {
        self.videoAsset = asset
        self.valueChanged = valueChanged
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func xibSetup() {
        Bundle.main.loadNibNamed("VideoTrimView", owner: self, options: nil)
        addSubview(mainView!)
        mainView.frame = self.bounds
        mainView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    override func draw(_ rect: CGRect) {
        setup()
    }
    
    func setup() {
        playPinView.layer.cornerRadius = 5
        playPinView.layer.shadowColor = UIColor.black.cgColor
        playPinView.layer.shadowRadius = 5
        playPinView.layer.shadowOpacity = 0.3
        thubnailsView.layer.masksToBounds = true
        
        leftPin.roundCorners(corners: [.topLeft, .bottomLeft], radius: 7)
        rightPin.roundCorners(corners: [.topRight, .bottomRight], radius: 7)
        
        addThubnailViews(in: self.thubnailsView, track: videoAsset.tracks.first!)
        
        let dragRightPinGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(dragRightPin))
        rightPin.addGestureRecognizer(dragRightPinGestureRecognizer)
        
        let dragLeftPinGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(dragLeftPin))
        leftPin.addGestureRecognizer(dragLeftPinGestureRecognizer)
        
        let dragPlayPinGesture = UIPanGestureRecognizer(target: self, action: #selector(dragPlayPin))
        playPinView.addGestureRecognizer(dragPlayPinGesture)
    }
    
    func countValues() {
        startValue = leftConstraint.constant / (mainView.bounds.width - (rightPin.bounds.width + playPinView.bounds.width))
        endValue = 1 - rightConstraint.constant / (mainView.bounds.width - (leftPin.bounds.width + playPinView.bounds.width))
        currentValue = (playPinConstraint.constant - leftPin.bounds.width) / (mainView.bounds.width - (leftPin.bounds.width + rightPin.bounds.width + playPinView.bounds.width))
        valueChanged(startValue, endValue, currentValue)
    }
    
    var startX: CGFloat = 0
    
    @objc func dragPlayPin(_ gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: self)
        let tempValue = mainView.bounds.width - (playPinView.bounds.width + rightConstraint.constant + rightPin.bounds.width)
        switch gestureRecognizer.state {
        case .began:
            startX = playPinConstraint.constant
        default:
            if leftConstraint.constant + leftPin.bounds.width > startX + translation.x {
                playPinConstraint.constant = leftConstraint.constant + leftPin.bounds.width
            } else if tempValue < startX + translation.x {
                playPinConstraint.constant = mainView.bounds.width - (rightConstraint.constant + rightPin.bounds.width + playPinView.bounds.width)
            } else {
                playPinConstraint.constant = startX + translation.x
            }
        }
        countValues()
    }
    
    @objc func dragRightPin(_ gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: self)
        let tempValue = mainView.bounds.width - (leftConstraint.constant + rightPin.bounds.width + leftPin.bounds.width + playPinView.bounds.width)
        switch gestureRecognizer.state {
        case .began:
            startX = rightConstraint.constant
        default:
            if startX - translation.x > tempValue {
                rightConstraint.constant = mainView.bounds.width - (leftConstraint.constant + rightPin.bounds.width + leftPin.bounds.width + playPinView.bounds.width)
            } else if startX - translation.x < 0 {
                rightConstraint.constant = 0
            } else {
                rightConstraint.constant = startX - translation.x
            }
        }
        keepPlayPinInField()
        countValues()
    }
    
    @objc func dragLeftPin(_ gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: self)
        let tempValue = mainView.bounds.width - (rightConstraint.constant + rightPin.bounds.width + leftPin.bounds.width + playPinView.bounds.width)
        switch gestureRecognizer.state {
        case .began:
            startX = leftConstraint.constant
        default:
            if startX + translation.x > tempValue {
                leftConstraint.constant = mainView.bounds.width - (rightConstraint.constant + rightPin.bounds.width + leftPin.bounds.width + playPinView.bounds.width)
            } else if startX + translation.x < 0 {
                leftConstraint.constant = 0
            } else {
                leftConstraint.constant = startX + translation.x
            }
        }
        keepPlayPinInField()
        countValues()
    }
    
    func keepPlayPinInField() {
        if playPinConstraint.constant < leftPin.bounds.width + leftConstraint.constant {
            playPinConstraint.constant = leftPin.bounds.width + leftConstraint.constant
        } else if playPinConstraint.constant > mainView.bounds.width - (rightConstraint.constant + rightPin.bounds.width + playPinView.bounds.width) {
            playPinConstraint.constant = mainView.bounds.width - (rightConstraint.constant + rightPin.bounds.width + playPinView.bounds.width)
        }
    }
    
    func addThubnailViews(in thubnailView: UIView, track: AVAssetTrack) {
        
        let views = createThumbnailViews(in: thubnailView.bounds.size, track: track)
        views.forEach(){ thubnailView.addSubview($0) }
    }
    
    func getThumbnailFrameSizeRatio(track: AVAssetTrack) -> CGFloat {
        let size = track.naturalSize
        return  size.width / size.height
    }
    
    func getCountOfThubnails(in size: CGSize, track: AVAssetTrack) -> Int {
        let ratio = getThumbnailFrameSizeRatio(track: track)
        let width = size.height * ratio
        return Int(ceil(size.width / width))
    }
    
    func getThubnailSize(in size: CGSize, track: AVAssetTrack) -> CGSize {
        let ratio = getThumbnailFrameSizeRatio(track: track)
        let width = size.height * ratio
        return CGSize(width: width, height: size.height)
    }
    
    func createThumbnailViews(in size: CGSize, track: AVAssetTrack) -> [UIImageView] {
        let count = getCountOfThubnails(in: size, track: track)
        let thubnailSize = getThubnailSize(in: size, track: track)
        
        let images = getImagesFromAsset(asset: track.asset!, count: count)
        
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
    
    func getImagesFromAsset(asset: AVAsset, count: Int) -> [UIImage] {
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        let trackDuration = asset.tracks.first!.timeRange.duration
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
