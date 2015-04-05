//
//  LOLImageManager.swift
//  Photo Stunner
//
//  Created by Connor Lirot on 3/30/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

import UIKit
import AVFoundation

let photos = [
    UIImage (named:"1.jpg"),
    UIImage (named:"2.jpg")
]

class StunningMediaManager : MediaManager {
    
    override init () {
        var index = Int (arc4random_uniform (UInt32 (photos.count)))
        self.image = photos[index];
    }
    
    override func retrieveThumbnailImageForKey(key: AnyObject!, completion: ((AnyObject!, UIImage!) -> Void)!) {
        super.retrieveThumbnailImageForKey(key, completion: { (key, image) -> Void in
            completion (key, self.image)
        })
    }
    
    override func retrieveVideoThumbnailImageForKey(key: AnyObject!, completion: ((AnyObject!, UIImage!) -> Void)!) {
        super.retrieveVideoThumbnailImageForKey(key, completion: { (key, image) -> Void in
            completion (key, self.image)
        })
    }
    
    private var image : UIImage?
    
}
