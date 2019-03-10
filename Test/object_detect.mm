<<<<<<< HEAD
// object_detect.cpp : Defines the entry point for the console application.
//

#include "object_detect.h"
#include "opencv2/opencv.hpp"

using namespace cv;
using namespace std;

bool check_pattern(cv::Mat img)
{
	vector<cv::Rect> boundRect;
	cv::Mat img_gray, img_sobel, img_threshold, element;
	cv::cvtColor(img, img_gray, CV_BGR2GRAY);
	cv::Sobel(img_gray, img_sobel, CV_8U, 1, 0, 3, 1, 0, BORDER_DEFAULT);
	cv::threshold(img_sobel, img_threshold, 0, 255, CV_THRESH_OTSU+CV_THRESH_BINARY);
    element = getStructuringElement(MORPH_RECT, cv::Size(17, 3) );
	morphologyEx(img_threshold, img_threshold, CV_MOP_CLOSE, element); 

	cv::imshow("pattern", img_threshold);
	waitKey(0);

	vector< vector< cv::Point> > contours;
	findContours(img_threshold, contours, 0, 1); 
	vector<vector<cv::Point> > contours_poly( contours.size() );
	int pattern_size = 0;
	for( int i = 0; i < contours.size(); i++ )
	{
		if (contours[i].size() > 100)
			pattern_size++;
	}

	if(pattern_size == 9)
		return true;
	else
		return false;
}

cv::Mat toCvMat(UIImage *image)
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

UIImage *UIImageFromCVMat(cv::Mat cvMat)
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}


UIImage* process(UIImage* image)
{
    cv::Mat src = toCvMat(image);
	if(src.empty())
		return nil;

	cv::Mat procImg, downImg, resultImg, greyImg;
	cv::pyrDown(src, downImg);
	cv::Scalar average = mean(downImg) * 2 / 3;

    cv::cvtColor(downImg, greyImg, CV_BGR2GRAY);
	cv::inRange(greyImg, 0, 50, procImg);
    
	cv::dilate(procImg, procImg, Mat());

	cv::Mat contourImg = procImg.clone();
    
	vector<vector<cv::Point>> contours;
	vector<cv::Vec4i> hierarchy;
	cv::findContours(contourImg, contours, hierarchy, CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0));
	// filter contours
	double contour_area = 0;
	cv::Rect contour_rect;
	cv::Mat object_img;
	if (contours.size() > 0)
	{
		for(int idx = 0; idx >= 0; idx = hierarchy[idx][0])
		{
			if(contour_area < cv::contourArea(contours[idx]))
            {
				contour_rect = cv::boundingRect(contours[idx]);
                contour_area = cv::contourArea(contours[idx]);
                cv::rectangle(downImg, contour_rect, Scalar(0, 0, 255), 3);
            }
		}
        
        return UIImageFromCVMat(downImg);
//        if (contour_rect.width > downImg.cols/2 || contour_rect.height > downImg.rows)
//        {
//            object_img = cv::Mat(downImg, contour_rect);
//            //bool bPattern = check_pattern(object_img);
//            //if(bPattern)
//            {
//                return UIImageFromCVMat(object_img);
//            }
//        }
	}

	return nil;
}

=======
// object_detect.cpp : Defines the entry point for the console application.
//

#include "object_detect.h"
#include "opencv2/opencv.hpp"
#import <AVFoundation/AVFoundation.h>

using namespace cv;
using namespace std;

bool check_pattern(cv::Mat img)
{
	vector<cv::Rect> boundRect;
	cv::Mat img_gray, img_sobel, img_threshold, element;
	cv::cvtColor(img, img_gray, CV_BGR2GRAY);
	cv::Sobel(img_gray, img_sobel, CV_8U, 1, 0, 3, 1, 0, BORDER_DEFAULT);
	cv::threshold(img_sobel, img_threshold, 0, 255, CV_THRESH_OTSU+CV_THRESH_BINARY);
    element = getStructuringElement(MORPH_RECT, cv::Size(17, 3) );
	morphologyEx(img_threshold, img_threshold, CV_MOP_CLOSE, element); 

	cv::imshow("pattern", img_threshold);
	waitKey(0);

	vector< vector< cv::Point> > contours;
	findContours(img_threshold, contours, 0, 1); 
	vector<vector<cv::Point> > contours_poly( contours.size() );
	int pattern_size = 0;
	for( int i = 0; i < contours.size(); i++ )
	{
		if (contours[i].size() > 100)
			pattern_size++;
	}

	if(pattern_size == 9)
		return true;
	else
		return false;
}

cv::Mat imageToCvMat(UIImage *image)
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

cv::Mat sampleBufferToCvMat(CMSampleBufferRef bSample) {
    
    // step 1: extract image from video buffer
    
    CVImageBufferRef bImage = CMSampleBufferGetImageBuffer(bSample);
    
    CVPixelBufferLockBaseAddress(bImage, kCVPixelBufferLock_ReadOnly);
    void *bRaw = CVPixelBufferGetBaseAddress(bImage);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(bImage);
    size_t width = CVPixelBufferGetWidth(bImage);
    size_t height = CVPixelBufferGetHeight(bImage);
    size_t bitsPerComponent = 8;
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    
    uint32_t flags = kCGImageByteOrder32Little | (kCGImageAlphaPremultipliedFirst & kCGBitmapAlphaInfoMask);
    CGContextRef inputContext = CGBitmapContextCreateWithData(bRaw, width, height, bitsPerComponent, bytesPerRow, colorspace, flags, NULL, NULL);
    CGImageRef image = CGBitmapContextCreateImage(inputContext);
    CGContextRelease(inputContext);
    
    // step 2: rotate image to correct orientation
    
    size_t newwidth = height;
    size_t newheight = width;
    
    // we make it here to make rotated image and result image of same size
    cv::Mat cvMat((int)newheight, (int)newwidth, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    size_t newBytesPerRow = cvMat.step[0];
    CGContextRef rotatedContext = CGBitmapContextCreate(NULL, newwidth, newheight, 8, newBytesPerRow, colorspace, kCGImageAlphaNoneSkipLast);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformRotate(transform, -M_PI_2);
    transform = CGAffineTransformTranslate(transform, -(CGFloat)width, 0);
    CGContextConcatCTM(rotatedContext, transform);
    
    CGContextDrawImage(rotatedContext, CGRectMake(0, 0, (CGFloat)width, (CGFloat)height), image);
    CGImageRef rotatedImage = CGBitmapContextCreateImage(rotatedContext);
    CGImageRelease(image);
    CGContextRelease(rotatedContext);

    // step 3: draw rotated image to result context
    
    CGContextRef outputContext = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                       cvMat.cols,                       // Width of bitmap
                                                       cvMat.rows,                       // Height of bitmap
                                                       8,                          // Bits per component
                                                       cvMat.step[0],              // Bytes per row
                                                       colorspace,                 // Colorspace
                                                       kCGImageAlphaNoneSkipLast |
                                                       kCGBitmapByteOrderDefault); // Bitmap info flags
    CGRect targetRect = CGRectMake(0, 0, (CGFloat)cvMat.cols, (CGFloat)cvMat.rows);
    CGContextSetRGBFillColor(outputContext, 1, 0, 0, 1);
    CGContextFillRect(outputContext, targetRect);
    
    CGContextDrawImage(outputContext, targetRect, rotatedImage);
    CGImageRelease(rotatedImage);
    CGImageRef result = CGBitmapContextCreateImage(outputContext);
    CGContextRelease(outputContext);
    CGImageRelease(result);
    
    CVPixelBufferUnlockBaseAddress(bImage, kCVPixelBufferLock_ReadOnly);
    
    return cvMat;
}

UIImage *UIImageFromCVMat(cv::Mat cvMat)
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    CGBitmapInfo flags;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
        flags = kCGImageAlphaNone|kCGBitmapByteOrderDefault;
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        flags = kCGImageAlphaNoneSkipLast|kCGBitmapByteOrderDefault;
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                              //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        flags,                                      // bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

cv::Mat _process(cv::Mat src) {
    cv::Mat procImg, downImg, resultImg, greyImg;
    cv::pyrDown(src, downImg);
    cv::Scalar average = mean(downImg) * 2 / 3;
    
    cv::cvtColor(downImg, greyImg, CV_BGR2GRAY);
    cv::inRange(greyImg, 0, 50, procImg);
    
    cv::dilate(procImg, procImg, Mat());
    
    cv::Mat contourImg = procImg.clone();
    
    vector<vector<cv::Point>> contours;
    vector<cv::Vec4i> hierarchy;
    cv::findContours(contourImg, contours, hierarchy, CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0));
    // filter contours
    double contour_area = 0;
    cv::Rect contour_rect;
    cv::Mat object_img;
    if (contours.size() > 0)
    {
        for(int idx = 0; idx >= 0; idx = hierarchy[idx][0])
        {
            if(contour_area < cv::contourArea(contours[idx]))
            {
                contour_rect = cv::boundingRect(contours[idx]);
                contour_area = cv::contourArea(contours[idx]);
                cv::rectangle(downImg, contour_rect, Scalar(0, 0, 255), 3);
            }
        }
        
        return downImg;
    }
    return src;
}

#ifdef __cplusplus
extern "C" {
#endif

UIImage *process(UIImage* image)
{
    cv::Mat src = imageToCvMat(image);
	if(src.empty()) return nil;

    cv::Mat result = _process(src);
    
    return UIImageFromCVMat(result);
}
    
UIImage *processFrame(CMSampleBufferRef sampleBuffer)
{
    cv::Mat src = sampleBufferToCvMat(sampleBuffer);
    if(src.empty()) return nil;
    
    cv::Mat result = _process(src);
    
    return UIImageFromCVMat(result);
}

#ifdef __cplusplus
}
#endif

>>>>>>> 39623597238bfdafb23702f28f31f729737a6c36
