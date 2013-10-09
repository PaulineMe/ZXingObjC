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

#import <CoreVideo/CoreVideo.h>
#import "ZXCGImageLuminanceSource.h"
#import "ZXImage.h"

@implementation ZXCGImageLuminanceSource

+ (CGImageRef)createImageFromBuffer:(CVImageBufferRef)buffer {
  return [self createImageFromBuffer:buffer
                                left:0
                                 top:0
                               width:CVPixelBufferGetWidth(buffer)
                              height:CVPixelBufferGetHeight(buffer)];
}

+ (CGImageRef)createImageFromBuffer:(CVImageBufferRef)buffer
                               left:(size_t)left
                                top:(size_t)top
                              width:(size_t)width
                             height:(size_t)height {
  size_t bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
  size_t dataWidth = CVPixelBufferGetWidth(buffer);
  size_t dataHeight = CVPixelBufferGetHeight(buffer);

  if (left + width > dataWidth ||
      top + height > dataHeight) {
    [NSException raise:NSInvalidArgumentException format:@"Crop rectangle does not fit within image data."];
  }

  size_t newBytesPerRow = ((width*4+0xf)>>4)<<4;

  CVPixelBufferLockBaseAddress(buffer,0); 

  int8_t *baseAddress = (int8_t *)CVPixelBufferGetBaseAddress(buffer);

  size_t size = newBytesPerRow*height;
  int8_t *bytes = (int8_t*)malloc(size);
  if (newBytesPerRow == bytesPerRow) {
    memcpy(bytes, baseAddress+top*bytesPerRow, size);
  } else {
    for (NSInteger y=0; y<height; y++) {
      memcpy(bytes+y*newBytesPerRow,
             baseAddress+left*4+(top+y)*bytesPerRow,
             newBytesPerRow);
    }
  }
  CVPixelBufferUnlockBaseAddress(buffer, 0);

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
  CGContextRef newContext = CGBitmapContextCreate(bytes,
                                                  width,
                                                  height,
                                                  8,
                                                  newBytesPerRow,
                                                  colorSpace,
                                                  kCGBitmapByteOrder32Little|
                                                  kCGImageAlphaNoneSkipFirst);
  CGColorSpaceRelease(colorSpace);

  CGImageRef result = CGBitmapContextCreateImage(newContext);

  CGContextRelease(newContext);

  free(bytes);

  return result;
}

- (id)initWithZXImage:(ZXImage *)image
                 left:(size_t)left
                  top:(size_t)top
                width:(size_t)width
               height:(size_t)height {
  return [self initWithCGImage:image.cgimage left:(NSInteger)left top:(NSInteger)top width:(NSInteger)width height:(NSInteger)height];
}

- (id)initWithZXImage:(ZXImage *)image {
  return [self initWithCGImage:image.cgimage];
}

- (id)initWithCGImage:(CGImageRef)image
                 left:(size_t)left
                  top:(size_t)top
                width:(size_t)width
               height:(size_t)height {
  if (self = [super initWithWidth:(NSInteger)width height:(NSInteger)height]) {
    [self initializeWithImage:image left:(NSInteger)left top:(NSInteger)top width:(NSInteger)width height:(NSInteger)height];
  }

  return self;
}

- (id)initWithCGImage:(CGImageRef)image {
  return [self initWithCGImage:image left:0 top:0 width:(NSInteger)CGImageGetWidth(image) height:(NSInteger)CGImageGetHeight(image)];
}

- (id)initWithBuffer:(CVPixelBufferRef)buffer
                left:(size_t)left
                 top:(size_t)top
               width:(size_t)width
              height:(size_t)height {
  CGImageRef image = [ZXCGImageLuminanceSource createImageFromBuffer:buffer left:(NSInteger)left top:(NSInteger)top width:(NSInteger)width height:(NSInteger)height];

  return [self initWithCGImage:image];
}

- (id )initWithBuffer:(CVPixelBufferRef)buffer {
  CGImageRef image = [ZXCGImageLuminanceSource createImageFromBuffer:buffer];

  return [self initWithCGImage:image];
}

- (CGImageRef)image {
  return _image;
}

- (void)dealloc {  
  if (_image) {
    CGImageRelease(_image);
  }
  if (_data) {
    free(_data);
  }
}

- (int8_t *)row:(NSInteger)y {
  if (y < 0 || y >= self.height) {
    [NSException raise:NSInvalidArgumentException format:@"Requested row is outside the image: %ld", (long)y];
  }

  int8_t *row = (int8_t *)malloc(self.width * sizeof(int8_t));

  NSInteger offset = y * self.width;
  memcpy(row, _data + offset, self.width);
  return row;
}

- (int8_t *)matrix {
  NSInteger area = self.width * self.height;

  int8_t *result = (int8_t *)malloc(area * sizeof(int8_t));
  memcpy(result, _data, area * sizeof(int8_t));
  return result;
}

- (void)initializeWithImage:(CGImageRef)cgimage left:(NSInteger)left top:(NSInteger)top width:(NSInteger)width height:(NSInteger)height {
  _data = 0;
  _image = CGImageRetain(cgimage);
  _left = left;
  _top = top;
  NSInteger sourceWidth = (NSInteger)CGImageGetWidth(cgimage);
  NSInteger sourceHeight = (NSInteger)CGImageGetHeight(cgimage);

  if (left + self.width > sourceWidth ||
      top + self.height > sourceHeight ||
      top < 0 ||
      left < 0) {
    [NSException raise:NSInvalidArgumentException format:@"Crop rectangle does not fit within image data."];
  }

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = CGBitmapContextCreate(0, self.width, self.height, 8, self.width * 4, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
  CGContextSetAllowsAntialiasing(context, FALSE);
  CGContextSetInterpolationQuality(context, kCGInterpolationNone);

  if (top || left) {
    CGContextClipToRect(context, CGRectMake(0, 0, self.width, self.height));
  }

  CGContextDrawImage(context, CGRectMake(-left, -top, self.width, self.height), self.image);

  uint32_t *pixelData = (uint32_t *) malloc(self.width * self.height * sizeof(uint32_t));
  memcpy(pixelData, CGBitmapContextGetData(context), self.width * self.height * sizeof(uint32_t));
  CGContextRelease(context);
  CGColorSpaceRelease(colorSpace);

  _data = (int8_t *)malloc(self.width * self.height * sizeof(int8_t));

  for (NSInteger i = 0; i < self.height * self.width; i++) {
    uint32_t rgbPixel=pixelData[i];

    float red = (rgbPixel>>24)&0xFF;
    float green = (rgbPixel>>16)&0xFF;
    float blue = (rgbPixel>>8)&0xFF;
    float alpha = (float)(rgbPixel & 0xFF) / 255.0f;

    // ImageIO premultiplies all PNGs, so we have to "un-premultiply them":
    // http://code.google.com/p/cocos2d-iphone/issues/detail?id=697#c26
    red = round((red / alpha) - 0.001f);
    green = round((green / alpha) - 0.001f);
    blue = round((blue / alpha) - 0.001f);

    if (red == green && green == blue) {
      _data[i] = red;
    } else {
      _data[i] = (306 * (int32_t)red +
                 601 * (int32_t)green +
                 117 * (int32_t)blue +
                (0x200)) >> 10; // 0x200 = 1<<9, half an lsb of the result to force rounding
    }
  }

  free(pixelData);

  _top = top;
  _left = left;
}

- (BOOL)rotateSupported {
  return YES;
}

- (ZXLuminanceSource *)rotateCounterClockwise {
  double radians = 270.0f * M_PI / 180;

#if TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR
  radians = -1 * radians;
#endif

  NSInteger sourceWidth = self.width;
  NSInteger sourceHeight = self.height;

  CGRect imgRect = CGRectMake(0, 0, sourceWidth, sourceHeight);
  CGAffineTransform transform = CGAffineTransformMakeRotation(radians);
  CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, transform);

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = CGBitmapContextCreate(NULL,
                                               rotatedRect.size.width,
                                               rotatedRect.size.height,
                                               CGImageGetBitsPerComponent(self.image),
                                               0,
                                               colorSpace,
                                               kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedFirst);
  CGContextSetAllowsAntialiasing(context, FALSE);
  CGContextSetInterpolationQuality(context, kCGInterpolationNone);
  CGColorSpaceRelease(colorSpace);

  CGContextTranslateCTM(context,
                        +(rotatedRect.size.width/2),
                        +(rotatedRect.size.height/2));
  CGContextRotateCTM(context, radians);

  CGContextDrawImage(context, CGRectMake(-imgRect.size.width/2,
                                         -imgRect.size.height/2,
                                         imgRect.size.width,
                                         imgRect.size.height),
                     self.image);

  CGImageRef rotatedImage = CGBitmapContextCreateImage(context);

  CFRelease(context);

  return [[ZXCGImageLuminanceSource alloc] initWithCGImage:rotatedImage left:_top top:sourceWidth - (_left + self.width) width:self.height height:self.width];
}

@end
