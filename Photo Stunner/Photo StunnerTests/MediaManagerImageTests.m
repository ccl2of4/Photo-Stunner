//
//  MediaManagerImageTests.m
//  Photo Stunner
//
//  Created by Connor Lirot on 3/28/15.
//  Copyright (c) 2015 Connor Lirot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "MediaManager.h"

@interface MediaManagerImageTests : XCTestCase

@property (nonatomic) MediaManager *imageManager;
@property (nonatomic) UIImage *testImage;

@end

@implementation MediaManagerImageTests

- (void)setUp {
    self.imageManager = [MediaManager new];
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (UIImage *)testImage {
    return [UIImage imageNamed:@"test_image"];
}

- (void)testRetrieveImageNotAdded {
    
    @try {
        [self.imageManager retrieveImageForKey:@0 completion:^(id key, UIImage *image) {
            XCTFail ();
        }];
        XCTFail ();
    }
    
    @catch (NSException *e) {}
}

- (void)testRetrieveImageNotAdded2 {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    [self.imageManager addImage:[self testImage] forKey:@0 completion:^(id key, UIImage *image) {
        @try {
            [weakSelf.imageManager retrieveImageForKey:@1 completion:^(id key, UIImage *image) {}];
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

- (void)testRetrieveImageAdded {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];

    __weak typeof (self) weakSelf = self;
    [self.imageManager addImage:[self testImage] forKey:@1 completion:^(id key, UIImage *image) {
        [weakSelf.imageManager retrieveImageForKey:@1 completion:^(id key, UIImage *image) {
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError *error) {
        if (error) {
            XCTFail ();
        }
    }];
}

- (void)testRetrieveImageAdded2 {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    [self.imageManager addImage:[self testImage] forKey:@10 completion:^(id key, UIImage *image) {
        [weakSelf.imageManager retrieveImageForKey:@10 completion:^(id key, UIImage *image) {
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError *error) {
        if (error) {
            XCTFail ();
        }
    }];
}


- (void)testRetrieveThumbnailImageNotAdded {
    
    @try {
        [self.imageManager retrieveThumbnailImageForKey:@0 completion:^(id key, UIImage *image) {
            XCTFail ();
        }];
        XCTFail ();
    }
    
    @catch (NSException *e) {}
}

- (void)testRetrieveThumbnailImageNotAdded2 {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    [self.imageManager addImage:[self testImage] forKey:@1 completion:^(id key, UIImage *image) {
        @try {
            [weakSelf.imageManager retrieveThumbnailImageForKey:@0 completion:^(id key, UIImage *image) {}];
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

- (void)testRetrieveThumbnailImageAdded {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    [self.imageManager addImage:[self testImage] forKey:@0 completion:^(id key, UIImage *image) {
        [weakSelf.imageManager retrieveThumbnailImageForKey:@0 completion:^(id key, UIImage *image) {
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError *error) {
        if (error) {
            XCTFail ();
        }
    }];
}

- (void)testRetrieveThumbnailImageAdded2 {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    [self.imageManager addImage:[self testImage] forKey:@1 completion:^(id key, UIImage *image) {
        [weakSelf.imageManager retrieveThumbnailImageForKey:@1 completion:^(id key, UIImage *image) {
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError *error) {
        if (error) {
            XCTFail ();
        }
    }];
}

- (void)testRemoveImageNotAdded {
    @try {
        [self.imageManager removeImageForKey:@1 completion:^(id key) {
            XCTFail ();
        }];
        XCTFail ();
        
    } @catch (NSException *e) {}
}

- (void)testRemoveImageNotAdded2 {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    [self.imageManager addImage:[self testImage] forKey:@1 completion:^(id key, UIImage *image) {
        @try {
            [weakSelf.imageManager removeImageForKey:@0 completion:^(id key) {
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

- (void)testRetrieveRemovedImage {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    [self.imageManager addImage:[self testImage] forKey:@0 completion:^(id key, UIImage *image) {
        [weakSelf.imageManager removeImageForKey:@0 completion:^(id key) {
            @try {
                [weakSelf.imageManager retrieveImageForKey:@0 completion:^(id key, UIImage *image) {}];
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

- (void)testRetrieveRemovedThumbnailImage {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    [self.imageManager addImage:[self testImage] forKey:@0 completion:^(id key, UIImage *image) {
        [weakSelf.imageManager removeImageForKey:@0 completion:^(id key) {
            @try {
                [weakSelf.imageManager retrieveThumbnailImageForKey:@0 completion:^(id key, UIImage *image) {}];
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

- (void)testRemoveAllImagesNoneAdded {
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

- (void)testRetrieveRemovedImages {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    
    __weak typeof (self) weakSelf = self;
    __block NSUInteger addedImages = 0;
    __block NSUInteger failedRetrievals = 0;
    
    NSIndexSet *indices = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 50)];
    [indices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        
        [self.imageManager addImage:[self testImage] forKey:@(idx) completion:^(id key, UIImage *image) {
            
            if (++addedImages == 50) {
                [weakSelf.imageManager removeAllImagesWithCompletionBlock:^{
                    
                    NSIndexSet *indices = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 50)];
                    [indices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                        
                        @try {
                            [weakSelf.imageManager retrieveThumbnailImageForKey:@(idx) completion:^(id key, UIImage *image) {}];
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
