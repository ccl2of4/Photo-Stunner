//
//  MediaManagerObserver.swift
//  Photo Stunner
//
//  Created by Connor Lirot on 4/4/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

import UIKit

@objc protocol MediaManagerObserverDelegate : NSObjectProtocol {
    optional func mediaManagerAddedVideo(key: AnyObject)
    optional func mediaManagerRemovedVideo(key: AnyObject)
    optional func mediaManagerAddedImage(key: AnyObject)
    optional func mediaManagerRemovedImage(key: AnyObject)
}

class MediaManagerObserver : NSObject {
    weak var delegate : MediaManagerObserverDelegate?
    private(set) var mediaManager : MediaManager!
    
    init (mediaManager: MediaManager) {
        super.init ()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleNotification:", name: MediaManagerContentChangedNotification, object: mediaManager)
        self.mediaManager = mediaManager

    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func handleNotification(notification: NSNotification) {
        assert(MediaManagerContentChangedNotification == notification.name)
        assert(self.mediaManager === notification.object)
        
        let userInfo = notification.userInfo! as NSDictionary
        let key = userInfo[MediaManagerContentKey] as NSValue
        let contentType = userInfo[MediaManagerContentTypeKey] as NSString
        let changeType : UInt32 = (userInfo[MediaManagerContentChangeTypeKey] as NSNumber).unsignedIntValue
        
        if (MediaManagerContentTypeVideo == contentType) {

            if (MediaManagerContentChangeAdd.value == changeType) {
                self.delegate?.mediaManagerAddedVideo?(key)
            
            } else if (MediaManagerContentChangeRemove.value == changeType) {
                self.delegate?.mediaManagerRemovedVideo?(key)
            
            } else { assert(false) }
            
        
        } else if (MediaManagerContentTypeImage == contentType) {
            
            if (MediaManagerContentChangeAdd.value == changeType) {
                self.delegate?.mediaManagerAddedImage?(key)
            
            } else if (MediaManagerContentChangeRemove.value == changeType) {
                self.delegate?.mediaManagerRemovedImage?(key)
            
            } else { assert(false) }
            
        } else { assert(false) }
    }
}
