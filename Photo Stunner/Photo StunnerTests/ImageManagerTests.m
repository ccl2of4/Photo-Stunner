//
//  ImageManagerTest.m
//  Photo Stunner
//
//  Created by Connor Lirot on 3/28/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "ImageManager.h"

@interface ImageManagerTests : XCTestCase

@property (nonatomic) ImageManager *imageManager;
@property (nonatomic) UIImage *testImage;

@end

@implementation ImageManagerTests

- (void)setUp {
    self.imageManager = [ImageManager new];
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (UIImage *)testImage {
    return [UIImage imageNamed:@"test_image"];
}

#pragma mark -retrieveImageForTime:completion:

- (void)testRetrieveImage1 {
    
    @try {
        [self.imageManager retrieveImageForTime:kCMTimeZero completion:^(CMTime time, UIImage *image) {
            XCTFail ();
        }];
        XCTFail ();
    }
    
    @catch (NSException *e) {}
}

- (void)testRetrieveImage2 {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];

    __weak typeof (self) weakSelf = self;
    [self.imageManager addImage:[self testImage] forTime:kCMTimeZero completion:^(CMTime time, UIImage *image) {
        [weakSelf.imageManager retrieveImageForTime:kCMTimeZero completion:^(CMTime time, UIImage *image) {
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError *error) {
        if (error) {
            XCTFail ();
        }
    }];
}

- (void)testRetrieveImage3 {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    [self.imageManager addImage:[self testImage] forTime:CMTimeMake(1,30) completion:^(CMTime time, UIImage *image) {
        @try {
            [weakSelf.imageManager retrieveImageForTime:kCMTimeZero completion:^(CMTime time, UIImage *image) {}];
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

- (void)testRetrieveImage4 {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    [self.imageManager addImage:[self testImage] forTime:CMTimeMake(5,30) completion:^(CMTime time, UIImage *image) {
        @try {
            [weakSelf.imageManager retrieveImageForTime:CMTimeMake(5,30) completion:^(CMTime time, UIImage *image) {
                [expectation fulfill];
            }];
        }
        @catch (NSException *e) {
        }
    }];
    
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError *error) {
        if (error) {
            XCTFail ();
        }
    }];
}

#pragma mark -retrieveThumbnailImageForTime:completion

- (void)testRetrieveThumbnailImage1 {
    
    @try {
        [self.imageManager retrieveThumbnailImageForTime:kCMTimeZero completion:^(CMTime time, UIImage *image) {
            XCTFail ();
        }];
        XCTFail ();
    }
    
    @catch (NSException *e) {}
}

- (void)testRetrieveThumbnailImage2 {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    [self.imageManager addImage:[self testImage] forTime:kCMTimeZero completion:^(CMTime time, UIImage *image) {
        [weakSelf.imageManager retrieveThumbnailImageForTime:kCMTimeZero completion:^(CMTime time, UIImage *image) {
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError *error) {
        if (error) {
            XCTFail ();
        }
    }];
}

- (void)testRetrieveThumbnailImage3 {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    [self.imageManager addImage:[self testImage] forTime:CMTimeMake(1,30) completion:^(CMTime time, UIImage *image) {
        @try {
            [weakSelf.imageManager retrieveThumbnailImageForTime:kCMTimeZero completion:^(CMTime time, UIImage *image) {}];
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

- (void)testRetrieveThumbnailImage4 {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    [self.imageManager addImage:[self testImage] forTime:CMTimeMake(5,30) completion:^(CMTime time, UIImage *image) {
        @try {
            [weakSelf.imageManager retrieveThumbnailImageForTime:CMTimeMake(5,30) completion:^(CMTime time, UIImage *image) {
                [expectation fulfill];
            }];
        } @catch (NSException *e) {}
    }];
    
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError *error) {
        if (error) {
            XCTFail ();
        }
    }];
}

#pragma mark -removeImageForTime:completion

- (void)testRemoveImage1 {
    
    @try {
        
        [self.imageManager removeImageForTime:kCMTimeZero completion:^(CMTime time) {
            XCTFail ();
        }];
        XCTFail ();
        
    } @catch (NSException *e) {}
}

- (void)testRemoveImage2 {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    [self.imageManager addImage:[self testImage] forTime:kCMTimeZero completion:^(CMTime time, UIImage *image) {
        [weakSelf.imageManager removeImageForTime:kCMTimeZero completion:^(CMTime time) {
            @try {
                [weakSelf.imageManager retrieveImageForTime:kCMTimeZero completion:^(CMTime time, UIImage *image) {}];
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

- (void)testRemoveImage3 {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    [self.imageManager addImage:[self testImage] forTime:kCMTimeZero completion:^(CMTime time, UIImage *image) {
        [weakSelf.imageManager removeImageForTime:kCMTimeZero completion:^(CMTime time) {
            @try {
                [weakSelf.imageManager retrieveThumbnailImageForTime:kCMTimeZero completion:^(CMTime time, UIImage *image) {}];
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

- (void)testRemoveImage4 {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    [self.imageManager addImage:[self testImage] forTime:kCMTimeZero completion:^(CMTime time, UIImage *image) {
        @try {
            [weakSelf.imageManager removeImageForTime:CMTimeMake(1,30) completion:^(CMTime time) {
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

#pragma mark -removeAllImagesWithCompletionBlock:

- (void)testRemoveAllImages1 {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    [self.imageManager removeAllImagesWithCompletionBlock:^{
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError *error) {
        if (error) {
            XCTFail ();
        }
    }];
}

- (void)testRemoveAllImages2 {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    __block NSUInteger addedImages = 0;
    __block NSUInteger failedRetrievals = 0;
    
    NSIndexSet *indices = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 50)];
    [indices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        
        [self.imageManager addImage:[self testImage] forTime:CMTimeMake(idx, 100) completion:^(CMTime time, UIImage *image) {
            
            if (++addedImages == 50) {
                [weakSelf.imageManager removeAllImagesWithCompletionBlock:^{
                    
                    NSIndexSet *indices = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 50)];
                    [indices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                        
                        @try {
                            [weakSelf.imageManager retrieveThumbnailImageForTime:CMTimeMake(idx, 100) completion:^(CMTime time, UIImage *image) {}];
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
    
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError *error) {
        if (error) {
            XCTFail ();
        }
    }];
}

@end
