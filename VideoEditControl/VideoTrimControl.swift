//
//  VideoTrimControl.swift
//  VideoEditControl
//
//  Created by Алексей Воронов on 13.10.2019.
//  Copyright © 2019 Алексей Воронов. All rights reserved.
//

import UIKit
import AVFoundation


class VideoTrimControl: UIView {
    
    let videoAsset: AVAsset
    
    var leftPin: UIView?
    var leftBackground: UIView?
    
    var rightPin: UIView?
    var rightBackground: UIView?
    
    var currentPlayPin: UIView?
    
    var currentValue: CGFloat = 0.0
    var startValue: CGFloat = 0.0
    var endValue: CGFloat = 1.0
    
    let valueChanged: (CGFloat, CGFloat, CGFloat) -> ()
    
    init(asset: AVAsset, frame: CGRect, valueChanged: @escaping (CGFloat, CGFloat, CGFloat) -> ()) {
        self.videoAsset = asset
        self.valueChanged = valueChanged
        super.init(frame: frame)
        self.setup()
        self.setupPins()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 5
        self.layer.borderColor = UIColor.gray.cgColor
        self.layer.borderWidth = 1

        addThubnailViews(in: self, track: videoAsset.tracks.first!)
        
        let darkView = UIView()
        darkView.backgroundColor = UIColor(white: 0.0, alpha: 0.1)
        darkView.frame = self.bounds
        self.addSubview(darkView)
        
        leftBackground = UIView(frame: CGRect(x: 0, y: 0, width: 57, height: self.bounds.height))
        leftBackground!.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        self.addSubview(leftBackground!)
        
        leftPin = UIView(frame: CGRect(x: 50, y: 0, width: 20, height: self.bounds.height))
        leftPin!.backgroundColor = UIColor.init(white: 0.45, alpha: 1.0)
        leftPin!.layer.cornerRadius = 5
        leftPin!.layer.borderColor = UIColor.init(white: 1.0, alpha: 1.0).cgColor
        leftPin!.layer.borderWidth = 8
        leftPin!.layer.shadowColor = UIColor.black.cgColor
        leftPin!.layer.shadowRadius = 6
        leftPin!.layer.shadowOpacity = 0.4
        leftPin!.layer.zPosition = 5
        self.addSubview(leftPin!)
        
        rightBackground = UIView(frame: CGRect(x: 257, y: 0, width: 118, height: self.bounds.height))
        rightBackground!.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        self.addSubview(rightBackground!)
        
        rightPin = UIView(frame: CGRect(x: 250, y: 0, width: 20, height: self.bounds.height))
        rightPin!.backgroundColor = UIColor.init(white: 0.45, alpha: 1.0)
        rightPin!.layer.cornerRadius = 5
        rightPin!.layer.borderColor = UIColor.init(white: 1.0, alpha: 1.0).cgColor
        rightPin!.layer.borderWidth = 8
        rightPin!.layer.shadowColor = UIColor.black.cgColor
        rightPin!.layer.shadowRadius = 6
        rightPin!.layer.shadowOpacity = 0.4
        rightPin!.layer.zPosition = 5
        self.addSubview(rightPin!)
        
        currentPlayPin = UIView(frame: CGRect(x: 250, y: 0, width: 10, height: self.bounds.height))
        currentPlayPin!.backgroundColor = UIColor.init(white: 1.0, alpha: 1.0)
        currentPlayPin!.layer.cornerRadius = 5
        currentPlayPin!.layer.shadowColor = UIColor.black.cgColor
        currentPlayPin!.layer.shadowRadius = 6
        currentPlayPin!.layer.shadowOpacity = 0.3
        currentPlayPin!.layer.zPosition = 10
        self.addSubview(currentPlayPin!)
        
        
        let dragRightPinGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(dragRightPin))
        rightPin!.addGestureRecognizer(dragRightPinGestureRecognizer)
        
        let dragLeftPinGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(dragLeftPin))
        leftPin!.addGestureRecognizer(dragLeftPinGestureRecognizer)
        
        let dragPlayPinGesture = UIPanGestureRecognizer(target: self, action: #selector(dragPlayPin))
        currentPlayPin!.addGestureRecognizer(dragPlayPinGesture)
    }
    
    func setCurrentPlayValue(_ value: CGFloat) {
        currentValue = value
        
        let width = self.bounds.width
        currentPlayPin!.center.x = currentValue * (width - 50) + 25.0
        
        keepPlayPinInField()
    }
    
    var startX: CGFloat = 0
    
    @objc func dragRightPin(_ gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: self)
        
        switch gestureRecognizer.state {
        case .began:
            startX = rightPin!.frame.origin.x
        default:
            if leftPin!.frame.origin.x + 30 > startX + translation.x {
                rightPin!.frame.origin.x = leftPin!.frame.origin.x + 30
            } else if bounds.width - 20 < startX + translation.x {
                rightPin!.frame.origin.x = bounds.width - 20
            } else {
                rightPin!.frame.origin.x = startX + translation.x
            }
        }
        countValues()
        setupBackgrounds()
        keepPlayPinInField()
    }
    
    @objc func dragPlayPin(_ gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: self)
        
        switch gestureRecognizer.state {
        case .began:
            startX = currentPlayPin!.frame.origin.x
        default:
            if rightPin!.frame.origin.x - 10 < startX + translation.x {
                currentPlayPin!.frame.origin.x = rightPin!.frame.origin.x - 10
            } else if leftPin!.frame.origin.x + 20 > startX + translation.x {
                currentPlayPin!.frame.origin.x = leftPin!.frame.origin.x + 20
            } else {
                currentPlayPin!.frame.origin.x = startX + translation.x
            }
        }
        countValues()
    }
    
    @objc func dragLeftPin(_ gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: self)
        
        switch gestureRecognizer.state {
        case .began:
            startX = leftPin!.frame.origin.x
        default:
            if rightPin!.frame.origin.x - 30 < startX + translation.x {
                leftPin!.frame.origin.x = rightPin!.frame.origin.x - 30
            } else if 0 > startX + translation.x {
                leftPin!.frame.origin.x = 0
            } else {
                leftPin!.frame.origin.x = startX + translation.x
            }
        }
        countValues()
        setupBackgrounds()
        keepPlayPinInField()
    }
    
    func keepPlayPinInField() {
        if rightPin!.frame.origin.x - 10 < currentPlayPin!.frame.origin.x {
            currentPlayPin!.frame.origin.x = rightPin!.frame.origin.x - 10
        } else if leftPin!.frame.origin.x + 20 > currentPlayPin!.frame.origin.x {
            currentPlayPin!.frame.origin.x = leftPin!.frame.origin.x + 20
        }
    }
    
    func countValues() {
        let width = self.bounds.width
        
        startValue = (leftPin!.center.x - 10.0) / width
        endValue = (rightPin!.center.x + 10.0) / width
        currentValue = (currentPlayPin!.center.x - 25.0) / (width - 50)
        
        valueChanged(startValue, endValue, currentValue)
    }
    
    func setupPins() {
        let width = self.bounds.width
        
        leftPin!.center.x = startValue * width + 10
        rightPin!.center.x = endValue * width - 10
        currentPlayPin!.center.x = currentValue * (width - 50) + 25.0
        
        setupBackgrounds()
    }
    
    func setupBackgrounds() {
        leftBackground!.frame = CGRect(x: 0, y: 0, width: leftPin!.center.x, height: self.bounds.height)
        rightBackground!.frame = CGRect(x: rightPin!.center.x, y: 0, width: bounds.width - rightPin!.center.x, height: self.bounds.height)
    }
    
    func addThubnailViews(in view: UIView, track: AVAssetTrack) {
        let views = createThumbnailViews(in: view.bounds.size, track: track)
        
        views.forEach(){ view.addSubview($0) }
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
