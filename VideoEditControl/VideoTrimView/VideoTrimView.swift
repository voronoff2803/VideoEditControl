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
    
    var trackWidth: CGFloat { thubnailsView.bounds.width - playPinView.bounds.width }
    
    var currentValue: Double {
        get { playPinConstraint.constant.normalized(with: leadingEdge.bounds.width ... trackWidth + leadingEdge.bounds.width).dbl }
        set {
            guard userInteracting == false else { return }
            playPinConstraint.constant = newValue.cg.deNormalized(with: 0 ... trackWidth) + leadingEdge.bounds.width
            checkValues()
        }
    }
    
    var startValue: Double { leadingXConstraint.constant.normalized(with: 0 ... trackWidth).dbl }
    var endValue: Double { 1 - trailingConstraint.constant.normalized(with: 0 ... trackWidth).dbl }
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
    
    private func checkValues() {
        let currentValueLagsBegindStartValueForMoreThenNegligibleAmount = startValue - currentValue > 0.002
        if currentValueLagsBegindStartValueForMoreThenNegligibleAmount { currentTimeDidChange?(startValue) }
        if currentValue >= endValue { currentTimeDidChange?(startValue) }
    }
    
    @objc private func dragPlayPin(_ gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: self)
        gestureRecognizer.setTranslation(.zero, in: self)
        
        let tempValue = mainView.bounds.width - (playPinView.bounds.width + trailingConstraint.constant + trailingEdge.bounds.width)
        
        let newPosition = playPinConstraint.constant + translation.x
        
        if gestureRecognizer.state == .began {
            userInteracting = true
            beginInteracting?()
        }
        else {
            if leadingXConstraint.constant + leadingEdge.bounds.width > newPosition {
                playPinConstraint.constant = leadingXConstraint.constant + leadingEdge.bounds.width
            }
            else if tempValue < newPosition {
                playPinConstraint.constant = mainView.bounds.width - (trailingConstraint.constant + trailingEdge.bounds.width + playPinView.bounds.width)
            }
            else {
                playPinConstraint.constant = newPosition
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
        gestureRecognizer.setTranslation(.zero, in: self)
        
        let minDistance = thubnailsView.bounds.width * minimumDurationValue.cg
        let tempValue = mainView.bounds.width - (leadingXConstraint.constant + trailingEdge.bounds.width + leadingEdge.bounds.width + playPinView.bounds.width + minDistance)
        
        let newPosition = trailingConstraint.constant - translation.x
        
        if  gestureRecognizer.state == .began {
            userInteracting = true
            beginInteracting?()
        }
        else {
            if newPosition > tempValue { trailingConstraint.constant = tempValue }
            else if newPosition < 0 { trailingConstraint.constant = 0 }
            else {
                trailingConstraint.constant = newPosition
                currentTimeDidChange?(currentValue)
            }
        }
        
        keepPlayPinInField()
        
        if gestureRecognizer.state == .ended {
            userInteracting = false
            endInteracting?()
        }
    }
    
    @objc private func dragLeftPin(_ gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: self)
        gestureRecognizer.setTranslation(.zero, in: self)
        
        let minDistance = thubnailsView.bounds.width * minimumDurationValue.cg
        let tempValue = mainView.bounds.width - (trailingConstraint.constant + trailingEdge.bounds.width + leadingEdge.bounds.width + playPinView.bounds.width + minDistance)
        
        let newPosition = leadingXConstraint.constant + translation.x
        
        if  gestureRecognizer.state == .began {
            userInteracting = true
            beginInteracting?()
        }
        else {
            if newPosition > tempValue { leadingXConstraint.constant = tempValue }
            else if newPosition < 0 { leadingXConstraint.constant = 0 }
            else {
                currentTimeDidChange?(currentValue)
                leadingXConstraint.constant = newPosition
            }
        }
        
        keepPlayPinInField()
        
        if gestureRecognizer.state == .ended {
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
