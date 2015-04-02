//
//  MediaManagerVideoTests.m
//  Photo Stunner
//
//  Created by Connor Lirot on 3/28/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "MediaManager.h"

@interface MediaManagerVideoTests : XCTestCase

@property (nonatomic) MediaManager *mediaManager;
@property (nonatomic) AVAsset *testVideo;

@end

@implementation MediaManagerVideoTests

- (void)setUp {
    self.mediaManager = [MediaManager new];
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (AVAsset *)testVideo {
    NSString *filePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"1.mp4"];
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:filePath]];
    assert ([asset isReadable]);
    assert ([asset isPlayable]);
    return asset;
}

- (void)testRetrieveVideoNotAdded {
    
    @try {
        [self.mediaManager retrieveVideoForKey:@0 completion:^(id key, AVAsset *video) {
            XCTFail ();
        }];
        XCTFail ();
    }
    
    @catch (NSException *e) {}
}

- (void)testRetrieveVideoNotAdded2 {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    [self.mediaManager addVideo:[self testVideo] forKey:@0 completion:^(id key, AVAsset *video) {
        @try {
            [weakSelf.mediaManager retrieveVideoForKey:@1 completion:^(id key, AVAsset *video) {}];
        }
        @catch (NSException *e) {
            [expectation fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError *error) {
        if (error) {
            XCTFail ();
        }
    }];
}

- (void)testRetrieveVideoAdded {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    [self.mediaManager addVideo:[self testVideo] forKey:@1 completion:^(id key, AVAsset *video) {
        [weakSelf.mediaManager retrieveVideoForKey:@1 completion:^(id key, AVAsset *video) {
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError *error) {
        if (error) {
            XCTFail ();
        }
    }];
}

- (void)testRetrieveVideoAdded2 {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    [self.mediaManager addVideo:[self testVideo] forKey:@10 completion:^(id key, AVAsset *video) {
        [weakSelf.mediaManager retrieveVideoForKey:@10 completion:^(id key, AVAsset *video) {
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError *error) {
        if (error) {
            XCTFail ();
        }
    }];
}


- (void)testRetrieveVideoThumbnailImageNotAdded {
    
    @try {
        [self.mediaManager retrieveVideoThumbnailImageForKey:@0 completion:^(id key, UIImage *image) {
            XCTFail ();
        }];
        XCTFail ();
    }
    
    @catch (NSException *e) {}
}

- (void)testRetrieveVideoThumbnailImageNotAdded2 {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    [self.mediaManager addVideo:[self testVideo] forKey:@1 completion:^(id key, AVAsset *video) {
        @try {
            [weakSelf.mediaManager retrieveVideoThumbnailImageForKey:@0 completion:^(id key, UIImage *image) {}];
        } @catch (NSException *e) {
            [expectation fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError *error) {
        if (error) {
            XCTFail ();
        }
    }];
}

- (void)testRetrieveVideoThumbnailImageAdded {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    [self.mediaManager addVideo:[self testVideo] forKey:@0 completion:^(id key, AVAsset *video) {
        [weakSelf.mediaManager retrieveVideoThumbnailImageForKey:@0 completion:^(id key, UIImage *image) {
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError *error) {
        if (error) {
            XCTFail ();
        }
    }];
}

- (void)testRetrieveVideoThumbnailImageAdded2 {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    [self.mediaManager addVideo:[self testVideo] forKey:@1 completion:^(id key, AVAsset *video) {
        [weakSelf.mediaManager retrieveVideoThumbnailImageForKey:@1 completion:^(id key, UIImage *image) {
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError *error) {
        if (error) {
            XCTFail ();
        }
    }];
}

- (void)testRemoveVideoNotAdded {
    @try {
        [self.mediaManager removeVideoForKey:@1 completion:^(id key) {
            XCTFail ();
        }];
        XCTFail ();
        
    } @catch (NSException *e) {}
}

- (void)testRemoveVideoNotAdded2 {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    [self.mediaManager addVideo:[self testVideo] forKey:@1 completion:^(id key, AVAsset *video) {
        @try {
            [weakSelf.mediaManager removeVideoForKey:@0 completion:^(id key) {
            }];
        } @catch (NSException *e) {
            [expectation fulfill];
        }
    }];
    
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError *error) {
        if (error) {
            XCTFail ();
        }
    }];
}

- (void)testRetrieveRemovedVideo {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    [self.mediaManager addVideo:[self testVideo] forKey:@0 completion:^(id key, AVAsset *video) {
        [weakSelf.mediaManager removeVideoForKey:@0 completion:^(id key) {
            @try {
                [weakSelf.mediaManager retrieveVideoForKey:@0 completion:^(id key, AVAsset *video) {}];
            } @catch (NSException *e) {
                [expectation fulfill];
            }
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError *error) {
        if (error) {
            XCTFail ();
        }
    }];
}

- (void)testRetrieveRemovedVideoThumbnailImage {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    [self.mediaManager addVideo:[self testVideo] forKey:@0 completion:^(id key, AVAsset *video) {
        [weakSelf.mediaManager removeVideoForKey:@0 completion:^(id key) {
            @try {
                [weakSelf.mediaManager retrieveVideoThumbnailImageForKey:@0 completion:^(id key, UIImage *image) {}];
            } @catch (NSException *e) {
                [expectation fulfill];
            }
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError *error) {
        if (error) {
            XCTFail ();
        }
    }];
}

- (void)testRemoveAllVideoNoneAdded {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    [self.mediaManager removeAllImagesWithCompletionBlock:^{
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError *error) {
        if (error) {
            XCTFail ();
        }
    }];
}

- (void)testRetrieveRemovedVideos {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    __block NSUInteger addedImages = 0;
    __block NSUInteger failedRetrievals = 0;
    
    static const NSUInteger testLength = 50;
    
    NSIndexSet *indices = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, testLength)];
    [indices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        
        [self.mediaManager addVideo:[self testVideo] forKey:@(idx) completion:^(id key, AVAsset *video) {
            
            if (++addedImages == testLength) {
                [weakSelf.mediaManager removeAllVideosWithCompletionBlock:^{
                    
                    NSIndexSet *indices = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, testLength)];
                    [indices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                        
                        @try {
                            [weakSelf.mediaManager retrieveVideoThumbnailImageForKey:@(idx) completion:^(id key, UIImage *image) {}];
                        } @catch (NSException *e) {
                            if (++failedRetrievals == addedImages) {
                                [expectation fulfill];
                            }
                        }
                    }];
                }];
            }
        }];
    }];
    
    [self waitForExpectationsWithTimeout:15 handler:^(NSError *error) {
        if (error) {
            XCTFail ();
        }
    }];
}

@end
