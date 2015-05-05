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
    var mediaManager : MediaManager?
    
    private var onceToken : dispatch_once_t = 0
    private var playerLayer : AVPlayerLayer = AVPlayerLayer()
    private var player : AVPlayer?
    private var saveBarButtonItem : UIBarButtonItem!
    private var savingBarButtonItem : UIBarButtonItem!
    private var savedBarButtonItem : UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect

        self.playbackView.layer.addSublayer(self.playerLayer)
        
        // title
        let title = NSLocalizedString("PreviewViewController title", comment: "")
        self.title = title
        
        // save
        let saveString = NSLocalizedString("PreviewViewController save", comment: "")
        self.saveBarButtonItem = UIBarButtonItem(title: saveString, style: UIBarButtonItemStyle.Plain, target: self, action:"handleUIControlEventTouchUpInside:")
        self.navigationItem.rightBarButtonItem = saveBarButtonItem
        
        // saving
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        self.savingBarButtonItem = UIBarButtonItem(customView:activityIndicatorView)
        
        // saved
        let savedString = NSLocalizedString("PreviewViewController saved", comment: "")
        self.savedBarButtonItem = UIBarButtonItem(title: savedString, style: UIBarButtonItemStyle.Plain, target: self, action:"handleUIControlEventTouchUpInside:")
        self.savedBarButtonItem.enabled = false
    }
    
    override func viewDidLayoutSubviews() {
        self.playerLayer.frame = self.playbackView.bounds
    }
    
    override func viewWillAppear(animated: Bool) {
        dispatch_once(&self.onceToken, { () -> Void in
            self.createComposition { (composition) -> Void in
                self.player = AVPlayer(playerItem: AVPlayerItem(asset: composition))
                self.playerLayer.player = self.player
                self.player!.play()
            }
        });
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.player?.pause()
    }
    
    func handleUIControlEventTouchUpInside(sender : AnyObject) {
        
        self.navigationItem.rightBarButtonItem = self.savingBarButtonItem
        (self.savingBarButtonItem.customView as UIActivityIndicatorView).startAnimating()
        
        self.createVideo { (video) -> Void in
            assert (NSFileManager.defaultManager().fileExistsAtPath(video.path!))
            assert (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(video.path))
            UISaveVideoAtPathToSavedPhotosAlbum(video.path, self, "video:didFinishSavingWithError:contextInfo:", nil)
        }
    }
    
    func video(video: NSString, didFinishSavingWithError:NSError, contextInfo:UnsafePointer<Void>) {
        (self.savingBarButtonItem.customView as UIActivityIndicatorView).stopAnimating()
        self.navigationItem.rightBarButtonItem = self.savedBarButtonItem
    }
    
    private func createVideo(completion: (video: NSURL) -> Void) {
        self.createComposition { (composition) -> Void in
            
            let exportSession = AVAssetExportSession(asset:composition, presetName:AVAssetExportPresetHighestQuality)
            exportSession.outputURL = NSURL (fileURLWithPath:self.freshTempFilePath())
            exportSession.outputFileType = AVFileTypeQuickTimeMovie
            
            exportSession.exportAsynchronouslyWithCompletionHandler({ () -> Void in
                if exportSession.status == AVAssetExportSessionStatus.Completed {
                    var asset : AVAsset = AVAsset.assetWithURL(exportSession.outputURL) as AVAsset
                    
                    assert(asset.playable)
                    assert(asset.readable)
                    assert(NSFileManager.defaultManager().fileExistsAtPath(exportSession.outputURL.path!))
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completion(video : exportSession.outputURL)
                    });
                    
                } else {
                    assert (false)
                }
            })
        }
    }
    
    private func createComposition(completion:(composition: AVComposition) -> Void) {
        let composition = AVMutableComposition()
        let dict = NSMutableDictionary()
        var currentStartTime = kCMTimeZero
        
        // find starting times for all videos
        for key in self.mediaManager!.sortedVideoKeys() {
            let timeRange = key as NSValue
            let timeRangeValue = timeRange.CMTimeRangeValue
            
            dict[timeRange] = NSValue(CMTime:currentStartTime)
            currentStartTime = CMTimeAdd (currentStartTime, timeRangeValue.duration)
        }
        
        // insert videos into composition
        // the for loop shouldn't have to insert the tracks using sortedVideoKeys() (as opposed to allVideoKeys)
        // but AVMutableComposition doesn't seem to work if they're not put in order
        // also the completion handlers are not guaranteed to be called in order
        // so technically this code could potentially be buggy because of that,
        // but I don't feel like fixing it since it's AVMutableComposition's fault in the first place
        for key in self.mediaManager!.sortedVideoKeys() {
            self.mediaManager!.retrieveVideoForKey(key, completion: { (key, video) -> Void in
                let startTime = (dict[key as NSValue] as NSValue).CMTimeValue
                
                var error : NSError?
                composition.insertTimeRange(CMTimeRangeMake(kCMTimeZero, video.duration), ofAsset: video, atTime: startTime, error: &error)
                assert(error == nil)
                
                dict.removeObjectForKey(key)
                if dict.count == 0 {
                    completion(composition:composition)
                }
            })
        }
    }
    
    private func freshTempFilePath() -> String {
        let fileManager = NSFileManager.defaultManager()
        var filePath : NSString? = nil
        
        do {
            
            var random = arc4random();
            var fileName = NSString(format: "%d.mov", random)
            filePath = NSTemporaryDirectory().stringByAppendingPathComponent(fileName)
            
        } while (fileManager.fileExistsAtPath(filePath!))
        
        return filePath!
    }
}
