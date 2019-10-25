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
    @IBOutlet weak private var backgroundView: UIView!
    @IBOutlet weak private var leadingXConstraint: NSLayoutConstraint!
    @IBOutlet weak private var trailingConstraint: NSLayoutConstraint!
    @IBOutlet weak private var leadingEdge: UIView!
    @IBOutlet weak private var trailingEdge: UIView!
    @IBOutlet weak private var thubnailsView: ThubnailsView!
    @IBOutlet weak private var playPinView: UIView!
    @IBOutlet weak private var playPinConstraint: NSLayoutConstraint!
    
    var currentValue: Double {
        get {
            return playPinConstraint.constant.normalized(with: leadingEdge.bounds.width ... (thubnailsView.bounds.width - playPinView.bounds.width) + leadingEdge.bounds.width).dbl
        }
        set {
            guard userInteracting == false else { return }
            playPinConstraint.constant = newValue.cg.deNormalized(with: 0 ... (thubnailsView.bounds.width - playPinView.bounds.width)) + leadingEdge.bounds.width
            checkValues()
        }
    }
    
    var startValue: Double = 0.0
    var endValue: Double = 1.0
    var minimumDurationValue: Float = 0.1
    
    var videoAsset: AVAsset?
    
    var panOnThumbnailsMovesCurrentPositionIndicator: Bool = false
    
    var currentTimeDidChange: Block<Double>?
    var beginInteracting: VoidBlock?
    var endInteracting: VoidBlock?
    
    private var userInteracting: Bool = false
    
    init(frame: CGRect, asset: AVAsset, scrollOnField: Bool = false, beginInteracting: @escaping () -> (), endInteracting: @escaping () -> ()) {
        self.videoAsset = asset
        self.beginInteracting = beginInteracting
        self.endInteracting = endInteracting
        self.panOnThumbnailsMovesCurrentPositionIndicator = scrollOnField
        super.init(frame: frame)
        loadThisViewFromNib()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadThisViewFromNib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutIfNeeded()
        setup()
    }
    
    private func loadThisViewFromNib() {
        Bundle.main.loadNibNamed("VideoTrimView", owner: self, options: nil)
        addSubview(mainView)
        mainView.frame = bounds
        
        // COMMENT: вот эта autoresizingMask тут действительно нужна?
        mainView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    private func setup() {
        playPinView.layer.cornerRadius = 5
        playPinView.layer.shadowColor = UIColor.black.cgColor
        playPinView.layer.shadowRadius = 5
        playPinView.layer.shadowOpacity = 0.3
        thubnailsView.layer.masksToBounds = true
        
        leadingEdge.roundCorners(corners: [.topLeft, .bottomLeft], radius: 7)
        trailingEdge.roundCorners(corners: [.topRight, .bottomRight], radius: 7)
        backgroundView.layer.cornerRadius = 7
        
        let dragRightPinGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(dragRightPin))
        trailingEdge.addGestureRecognizer(dragRightPinGestureRecognizer)
        
        let dragLeftPinGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(dragLeftPin))
        leadingEdge.addGestureRecognizer(dragLeftPinGestureRecognizer)
        
        let dragPlayPinGesture = UIPanGestureRecognizer(target: self, action: #selector(dragPlayPin))
        if panOnThumbnailsMovesCurrentPositionIndicator { addGestureRecognizer(dragPlayPinGesture) }
        else { playPinView.addGestureRecognizer(dragPlayPinGesture) }
        
        thubnailsView.videoAsset = videoAsset
    }
    
    private func countValues() {
        startValue = leadingXConstraint.constant.normalized(with: 0 ... (thubnailsView.bounds.width - playPinView.bounds.width)).dbl
        endValue = 1 - trailingConstraint.constant.normalized(with: 0 ... (thubnailsView.bounds.width - playPinView.bounds.width)).dbl
    }
    
    private func checkValues() {
        countValues()
        if currentValue < startValue { currentTimeDidChange?(startValue + 0.005) }
        else if currentValue > endValue { currentTimeDidChange?(startValue + 0.005) }
    }
    
    private var startX: CGFloat = 0
    
    @objc private func dragPlayPin(_ gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: self)
        let tempValue = mainView.bounds.width - (playPinView.bounds.width + trailingConstraint.constant + trailingEdge.bounds.width)
        if gestureRecognizer.state == .began {
            startX = playPinConstraint.constant
            userInteracting = true
            beginInteracting?()
        }
        else {
            if leadingXConstraint.constant + leadingEdge.bounds.width > startX + translation.x {
                playPinConstraint.constant = leadingXConstraint.constant + leadingEdge.bounds.width
            }
            else if tempValue < startX + translation.x {
                playPinConstraint.constant = mainView.bounds.width - (trailingConstraint.constant + trailingEdge.bounds.width + playPinView.bounds.width)
            }
            else {
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
        let tempValue = mainView.bounds.width - (leadingXConstraint.constant + trailingEdge.bounds.width + leadingEdge.bounds.width + playPinView.bounds.width + minDistance)
        
        if  gestureRecognizer.state == .began {
            startX = trailingConstraint.constant
            userInteracting = true
            beginInteracting?()
        }
        else {
            if startX - translation.x > tempValue { trailingConstraint.constant = tempValue }
            else if startX - translation.x < 0 { trailingConstraint.constant = 0 }
            else {
                trailingConstraint.constant = startX - translation.x
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
        let tempValue = mainView.bounds.width - (trailingConstraint.constant + trailingEdge.bounds.width + leadingEdge.bounds.width + playPinView.bounds.width + minDistance)
        
        if  gestureRecognizer.state == .began {
            startX = leadingXConstraint.constant
            userInteracting = true
            beginInteracting?()
        }
        else {
            if startX + translation.x > tempValue { leadingXConstraint.constant = tempValue }
            else if startX + translation.x < 0 { leadingXConstraint.constant = 0 }
            else {
                countValues()
                currentTimeDidChange?(currentValue)
                leadingXConstraint.constant = startX + translation.x
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
        if playPinConstraint.constant < leadingEdge.bounds.width + leadingXConstraint.constant {
            playPinConstraint.constant = leadingEdge.bounds.width + leadingXConstraint.constant
        }
        else if playPinConstraint.constant > mainView.bounds.width - (trailingConstraint.constant + trailingEdge.bounds.width + playPinView.bounds.width) {
            playPinConstraint.constant = mainView.bounds.width - (trailingConstraint.constant + trailingEdge.bounds.width + playPinView.bounds.width)
        }
    }
}
