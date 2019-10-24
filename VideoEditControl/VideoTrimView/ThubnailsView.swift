//
//  ThubnailsView.swift
//  VideoEditControl
//
//  Created by Алексей Воронов on 24.10.2019.
//  Copyright © 2019 Алексей Воронов. All rights reserved.
//

import UIKit
import AVFoundation

class ThubnailsView: UIView {
    
    var videoAsset: AVAsset? {
        didSet {
            addThubnailViews()
        }
    }
    
    init(frame: CGRect, videoAsset: AVAsset) {
        self.videoAsset = videoAsset
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func addThubnailViews() {
        guard let track = videoAsset?.tracks.first else { return }
        let views = createThumbnailViews(in: self.bounds.size, track: track)
        views.forEach(){ self.addSubview($0) }
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
        guard let asset = track.asset.assertingNonNil else { return [] }
        
        let count = getCountOfThubnails(in: size, track: track)
        let thubnailSize = getThubnailSize(in: size, track: track)
        
        return getImagesFromAsset(asset: asset, count: count).enumerated().map { (i, image) in
            let frame = CGRect(x: CGFloat(i) * thubnailSize.width, y: 0, width: thubnailSize.width, height: thubnailSize.height)
            let thubnailView = UIImageView(frame: frame)
            thubnailView.image = image
            thubnailView.layer.zPosition = -1
            return thubnailView
        }
    }
    
    private func getImagesFromAsset(asset: AVAsset, count: Int) -> [UIImage] {
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        guard let videoTrack = asset.tracks.first else { return [] }
        let trackDuration = videoTrack.timeRange.duration
        let thubnailDuration = trackDuration.seconds / Double(count)
        var images: [UIImage] = []
        
        for i in 0 ..< count {
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
