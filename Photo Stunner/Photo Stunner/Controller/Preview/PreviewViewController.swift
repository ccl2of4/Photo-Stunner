//
//  PreviewViewController.swift
//  Photo Stunner
//
//  Created by Connor Lirot on 4/2/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

import UIKit
import AVFoundation

class PreviewViewController: UIViewController {
    @IBOutlet weak var playbackView: UIView!
    
    var mediaManager : MediaManager? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.playerLayer = AVPlayerLayer ()
        self.playbackView.layer.addSublayer (self.playerLayer)
        
        var barButtonItem = UIBarButtonItem (title:"Save", style: UIBarButtonItemStyle.Plain, target: self, action:"handleUIControlEventTouchUpInside:")
        self.navigationItem.rightBarButtonItem = barButtonItem
    }
    
    override func viewDidLayoutSubviews() {
        self.playerLayer!.frame = self.playbackView.bounds
    }
    
    override func viewDidAppear(animated: Bool) {
        self.createComposition { (composition) -> Void in
            var player = AVPlayer (playerItem : AVPlayerItem (asset : composition))
            self.player = self.player (composition)
            self.playerLayer!.player = self.player
            self.player!.play ()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func handleUIControlEventTouchUpInside(sender : AnyObject) {
        self.createVideo { (video) -> Void in
            assert (NSFileManager.defaultManager().fileExistsAtPath(video.path!))
            assert (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(video.path))
            UISaveVideoAtPathToSavedPhotosAlbum(video.path, self, nil, nil)
        }
    }
    
    private func createVideo (completion : (video : NSURL) -> Void) {
        self.createComposition { (composition) -> Void in
            var exportSession = self.exportSession (composition)
            exportSession.exportAsynchronouslyWithCompletionHandler({ () -> Void in
                if exportSession.status == AVAssetExportSessionStatus.Completed {
                    var asset : AVAsset = AVAsset.assetWithURL(exportSession.outputURL) as AVAsset
                    assert (asset.playable)
                    assert (asset.readable)
                    assert (NSFileManager.defaultManager().fileExistsAtPath(exportSession.outputURL.path!))
                    completion (video : exportSession.outputURL)
                } else {
                    assert (false)
                }
            })
        }
    }
    
    private var onceToken : dispatch_once_t = 0
    
    private var playerLayer : AVPlayerLayer? = nil
    
    private var player : AVPlayer? = nil
    
    private func player (asset : AVAsset) -> AVPlayer {
        var player = AVPlayer (playerItem : AVPlayerItem (asset : asset))
        player.actionAtItemEnd = AVPlayerActionAtItemEnd.Pause
        return player
    }
    
    private func freshTempFilePath () -> String {
        var fileManager = NSFileManager.defaultManager()
        var filePath : NSString? = nil

        do {
        
            var random = arc4random();
            var fileName = NSString (format: "%d.mov", random)
            filePath = NSTemporaryDirectory().stringByAppendingPathComponent(fileName)
        
        } while (fileManager.fileExistsAtPath(filePath!))
            
        return filePath!
    }
    
    private func exportSession (asset : AVAsset) -> AVAssetExportSession {
        var exportSession = AVAssetExportSession (asset: asset, presetName: AVAssetExportPresetHighestQuality)
        exportSession.outputURL = NSURL (fileURLWithPath:self.freshTempFilePath())
        exportSession.outputFileType = AVFileTypeQuickTimeMovie
        return exportSession
    }
    
    private func createComposition (completion: (composition : AVComposition) -> Void) {
        var composition = AVMutableComposition ()
        var dict = NSMutableDictionary ()
        var start = kCMTimeZero
        
        // figure out where stuff goes in
        for key in self.mediaManager!.sortedVideoKeys() {
            if let timeRange = key as? NSValue {
                var timeRangeValue = timeRange.CMTimeRangeValue
                dict[timeRange] = NSValue (CMTime:start)
                start = CMTimeAdd (start, timeRangeValue.duration)
            } else {
                assert (false)
            }
        }
        
        // put stuff in
        for key in self.mediaManager!.sortedVideoKeys () {
            self.mediaManager?.retrieveVideoForKey(key, completion: { (key, video) -> Void in
                if let timeRange = key as? NSValue {
                    if let startTime = dict[timeRange] as? NSValue {
                        var startTimeValue = startTime.CMTimeValue
                        var error : NSErrorPointer = nil
                        composition.insertTimeRange(CMTimeRangeMake(kCMTimeZero, video.duration), ofAsset: video, atTime: startTimeValue, error:error)
                        
                        dict.removeObjectForKey(timeRange)
                        if dict.count == 0 {
                            completion (composition:composition)
                        }
                    } else {
                        assert (false)
                    }
                } else {
                    assert (false)
                }
            })
        }
    }
}
