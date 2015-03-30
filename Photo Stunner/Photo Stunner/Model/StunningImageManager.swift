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

@objc class StunningImageManager : ImageManager {
    
    override init () {
        var index = Int (arc4random_uniform (UInt32 (photos.count)))
        self.image = photos[index];
    }
    
    override func addImage (image: UIImage!, forTime time: CMTime, completion: ((CMTime, UIImage!) -> Void)!) {
        super.addImage (self.image, forTime: time, completion: completion);
    }
    
    private var image : UIImage?
    
}
