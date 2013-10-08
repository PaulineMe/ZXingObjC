/*
 * Copyright 2012 ZXing authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "RSSExpandedInternalTestCase.h"

@implementation RSSExpandedInternalTestCase

- (void)testFindFinderPatterns {
  NSString *path = @"Resources/blackbox/rssexpanded-1/2.png";
  ZXImage *image = [[ZXImage alloc] initWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:path withExtension:nil]];
  ZXBinaryBitmap *binaryMap = [[ZXBinaryBitmap alloc] initWithBinarizer:[[ZXGlobalHistogramBinarizer alloc] initWithSource:[[ZXCGImageLuminanceSource alloc] initWithZXImage:image]]];
  NSInteger rowNumber = binaryMap.height / 2;
  ZXBitArray *row = [binaryMap blackRow:rowNumber row:nil error:nil];
  NSMutableArray *previousPairs = [NSMutableArray array];

  ZXRSSExpandedReader *rssExpandedReader = [[ZXRSSExpandedReader alloc] init];
  ZXExpandedPair *pair1 = [rssExpandedReader retrieveNextPair:row previousPairs:previousPairs rowNumber:rowNumber];
  [previousPairs addObject:pair1];
  ZXRSSFinderPattern *finderPattern = pair1.finderPattern;
  STAssertNotNil(finderPattern, @"Expected finderPattern to be non-nil");
  STAssertEquals(finderPattern.value, (NSInteger)0, @"Expected finderPattern to equal 0");

  ZXExpandedPair *pair2 = [rssExpandedReader retrieveNextPair:row previousPairs:previousPairs rowNumber:rowNumber];
  [previousPairs addObject:pair2];
  finderPattern = pair2.finderPattern;
  STAssertNotNil(finderPattern, @"Expected finderPattern to be non-nil");
  STAssertEquals(finderPattern.value, (NSInteger)1, @"Expected finderPattern to equal 1");

  ZXExpandedPair *pair3 = [rssExpandedReader retrieveNextPair:row previousPairs:previousPairs rowNumber:rowNumber];
  [previousPairs addObject:pair3];
  finderPattern = pair3.finderPattern;
  STAssertNotNil(finderPattern, @"Expected finderPattern to be non-nil");
  STAssertEquals(finderPattern.value, (NSInteger)1, @"Expected finderPattern to equal 1");

  if ([rssExpandedReader retrieveNextPair:row previousPairs:previousPairs rowNumber:rowNumber]) {
    //   the previous was the last pair
    STFail(@"Error expected");
  }
}

- (void)testRetrieveNextPairPatterns {
  NSString *path = @"Resources/blackbox/rssexpanded-1/3.png";
  ZXImage *image = [[ZXImage alloc] initWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:path withExtension:nil]];
  ZXBinaryBitmap *binaryMap = [[ZXBinaryBitmap alloc] initWithBinarizer:[[ZXGlobalHistogramBinarizer alloc] initWithSource:[[ZXCGImageLuminanceSource alloc] initWithZXImage:image]]];
  NSInteger rowNumber = binaryMap.height / 2;
  ZXBitArray *row = [binaryMap blackRow:rowNumber row:nil error:nil];
  NSMutableArray *previousPairs = [NSMutableArray array];

  ZXRSSExpandedReader *rssExpandedReader = [[ZXRSSExpandedReader alloc] init];
  ZXExpandedPair *pair1 = [rssExpandedReader retrieveNextPair:row previousPairs:previousPairs rowNumber:rowNumber];
  [previousPairs addObject:pair1];
  ZXRSSFinderPattern *finderPattern = pair1.finderPattern;
  STAssertNotNil(finderPattern, @"Expected finderPattern to be non-nil");
  STAssertEquals(finderPattern.value, (NSInteger)0, @"Expected finderPattern to equal 0");

  ZXExpandedPair *pair2 = [rssExpandedReader retrieveNextPair:row previousPairs:previousPairs rowNumber:rowNumber];
  [previousPairs addObject:pair2];
  finderPattern = pair2.finderPattern;
  STAssertNotNil(finderPattern, @"Expected finderPattern to be non-nil");
  STAssertEquals(finderPattern.value, (NSInteger)0, @"Expected finderPattern to equal 0");
}

- (void)testDecodeCheckCharacter {
  NSString *path = @"Resources/blackbox/rssexpanded-1/3.png";
  ZXImage *image = [[ZXImage alloc] initWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:path withExtension:nil]];
  ZXBinaryBitmap *binaryMap = [[ZXBinaryBitmap alloc] initWithBinarizer:[[ZXGlobalHistogramBinarizer alloc] initWithSource:[[ZXCGImageLuminanceSource alloc] initWithZXImage:image]]];
  ZXBitArray *row = [binaryMap blackRow:binaryMap.height / 2 row:nil error:nil];

  NSMutableArray *startEnd = [@[@145, @243] mutableCopy];//image pixels where the A1 pattern starts (at 124) and ends (at 214)
  NSInteger value = 0;// A
  ZXRSSFinderPattern *finderPatternA1 = [[ZXRSSFinderPattern alloc] initWithValue:value startEnd:startEnd start:[startEnd[0] intValue] end:[startEnd[1] intValue] rowNumber:(NSInteger)image.height / 2];
  //{1, 8, 4, 1, 1};
  ZXRSSExpandedReader *rssExpandedReader = [[ZXRSSExpandedReader alloc] init];
  ZXDataCharacter *dataCharacter = [rssExpandedReader decodeDataCharacter:row pattern:finderPatternA1 isOddPattern:YES leftChar:YES];

  STAssertEquals(dataCharacter.value, (NSInteger)98, @"Expected dataCharacter.value to equal 98");
}

- (void)testDecodeDataCharacter {
  NSString *path = @"Resources/blackbox/rssexpanded-1/3.png";
  ZXImage *image = [[ZXImage alloc] initWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:path withExtension:nil]];
  ZXBinaryBitmap *binaryMap = [[ZXBinaryBitmap alloc] initWithBinarizer:[[ZXGlobalHistogramBinarizer alloc] initWithSource:[[ZXCGImageLuminanceSource alloc] initWithZXImage:image]]];
  ZXBitArray *row = [binaryMap blackRow:binaryMap.height / 2 row:nil error:nil];

  NSMutableArray *startEnd = [NSMutableArray arrayWithObjects:@145, @243, nil];//image pixels where the A1 pattern starts (at 124) and ends (at 214)
  NSInteger value = 0;// A
  ZXRSSFinderPattern *finderPatternA1 = [[ZXRSSFinderPattern alloc] initWithValue:value startEnd:startEnd start:[startEnd[0] intValue] end:[startEnd[1] intValue] rowNumber:(NSInteger)image.height / 2];
  //{1, 8, 4, 1, 1};
  ZXRSSExpandedReader *rssExpandedReader = [[ZXRSSExpandedReader alloc] init];
  ZXDataCharacter *dataCharacter = [rssExpandedReader decodeDataCharacter:row pattern:finderPatternA1 isOddPattern:YES leftChar:NO];

  STAssertEquals(dataCharacter.value, (NSInteger)19, @"Expected dataCharacter.value to equal 19");
  STAssertEquals(dataCharacter.checksumPortion, (NSInteger)1007, @"Expected dataCharacter.checksumPortion to equal 1007");
}

@end
