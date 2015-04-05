//
//  MediaManagerObserver.swift
//  Photo Stunner
//
//  Created by Connor Lirot on 4/4/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

import UIKit

@objc protocol MediaManagerObserverDelegate : NSObjectProtocol {

    // general methods
    optional func mediaManagerContentChanged()
    optional func mediaManagerContentRemoved()
    optional func mediaManagerContentAdded()
    optional func mediaManagerVideosChanged()
    optional func mediaManagerImagesChanged()

    // specific methods
    optional func mediaManagerAddedVideo(key: AnyObject)
    optional func mediaManagerRemovedVideo(key: AnyObject)
    optional func mediaManagerAddedImage(key: AnyObject)
    optional func mediaManagerRemovedImage(key: AnyObject)
}

class MediaManagerObserver : NSObject {
    weak var delegate : MediaManagerObserverDelegate?
    private(set) var mediaManager : MediaManager!
    
    // =======================
    //
    // Life cycle
    //
    // =======================
    init (mediaManager: MediaManager) {
        super.init ()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleNotification:", name: MediaManagerContentChangedNotification, object: mediaManager)
        self.mediaManager = mediaManager

    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    
    // =======================
    //
    // Notification handling
    //
    // =======================
    func handleNotification(notification: NSNotification) {
        assert(MediaManagerContentChangedNotification == notification.name)
        assert(self.mediaManager === notification.object)
        
        let userInfo = notification.userInfo! as NSDictionary
        let key = userInfo[MediaManagerContentKey] as NSValue
        let contentType = userInfo[MediaManagerContentTypeKey] as NSString
        let changeType : UInt32 = (userInfo[MediaManagerContentChangeTypeKey] as NSNumber).unsignedIntValue
        
        if (MediaManagerContentTypeVideo == contentType) {

            if (MediaManagerContentChangeAdd.value == changeType) {
                self.addedVideo(key)
            
            } else if (MediaManagerContentChangeRemove.value == changeType) {
                self.removedVideo(key)
            
            } else { assert(false) }
            
        
        } else if (MediaManagerContentTypeImage == contentType) {
            
            if (MediaManagerContentChangeAdd.value == changeType) {
                self.addedImage(key)
            
            } else if (MediaManagerContentChangeRemove.value == changeType) {
                self.removedImage(key)
            
            } else { assert(false) }
            
       } else { assert(false) }
    }
    
    // =======================
    //
    // Dispatchers
    //
    // =======================
    func addedVideo(key: AnyObject) {
        self.delegate?.mediaManagerContentChanged?()
        self.delegate?.mediaManagerVideosChanged?()
        self.delegate?.mediaManagerContentAdded?()
        self.delegate?.mediaManagerAddedVideo?(key)
    }
    func removedVideo(key: AnyObject) {
        self.delegate?.mediaManagerContentChanged?()
        self.delegate?.mediaManagerVideosChanged?()
        self.delegate?.mediaManagerContentRemoved?()
        self.delegate?.mediaManagerRemovedVideo?(key)
    }
    func addedImage(key: AnyObject) {
        self.delegate?.mediaManagerContentChanged?()
        self.delegate?.mediaManagerImagesChanged?()
        self.delegate?.mediaManagerContentAdded?()
        self.delegate?.mediaManagerAddedImage?(key)
    }
    func removedImage(key: AnyObject) {
        self.delegate?.mediaManagerContentChanged?()
        self.delegate?.mediaManagerImagesChanged?()
        self.delegate?.mediaManagerContentRemoved?()
        self.delegate?.mediaManagerRemovedImage?(key)
    }
}
