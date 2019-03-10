//
//  ViewController.m
//  Object Eraser
//
//  Created by Mac on 25/06/18.
//

#import "ViewController.h"
#import "object_detect.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>
{
    UIImage *image;
    bool isLoaded;
    
    AVCaptureVideoPreviewLayer *previewLayer;
    AVCaptureSession *cameraSession;
}

@property (retain, nonatomic) IBOutlet UIImageView *baghaView;
@property (retain, nonatomic) IBOutlet UIView *cameraView;

- (IBAction)LoadImage:(id)sender;
- (IBAction)processImage:(id)sender;


@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _baghaView.hidden = NO;
    _baghaView.clipsToBounds = YES;

    isLoaded = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)LoadImage:(id)sender
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:nil];
}
    
- (IBAction)toggleCamera:(id)sender
{
    if (previewLayer == nil) {
        NSLog(@"enabling camera");
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self runCamera];
            });
        }];
        
    } else {
        NSLog(@"disabling camera");
        [cameraSession stopRunning];
        [previewLayer removeFromSuperlayer];
        previewLayer = nil;
    }
}
    
- (void)runCamera
{
    cameraSession = [AVCaptureSession new];
    
    // input - cam device
    AVCaptureDevice *camera = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera
                                                                 mediaType:AVMediaTypeVideo
                                                                  position:AVCaptureDevicePositionBack];
    AVCaptureDeviceInput *camInput = [AVCaptureDeviceInput deviceInputWithDevice:camera error:nil];
    [cameraSession addInput:camInput];
    
    // live preview layer
    previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:cameraSession];
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    previewLayer.frame = self.cameraView.bounds;
    [self.cameraView.layer addSublayer: previewLayer];
    
    // output - data stream
    AVCaptureVideoDataOutput *output = [AVCaptureVideoDataOutput new];
    NSString *pixelFormat = (NSString *)kCVPixelBufferPixelFormatTypeKey;
    output.videoSettings = @{pixelFormat: [NSNumber numberWithUnsignedLong: kCVPixelFormatType_32BGRA]};
    output.alwaysDiscardsLateVideoFrames = YES;
//    [output setSampleBufferDelegate:self queue: dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)];
    [output setSampleBufferDelegate:self queue: dispatch_get_main_queue()];
    [cameraSession addOutput:output];
    
    [cameraSession startRunning];
}

// here we're receiving camera frames and can process it
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (!CMSampleBufferDataIsReady(sampleBuffer)) return;
    _baghaView.image = processFrame(sampleBuffer);
    
}
    
- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"dropped frame");
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

 - (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)editingInfo
{
    image = [self fixOrientation:[editingInfo valueForKey:UIImagePickerControllerOriginalImage]];
    
    [_baghaView setImage:image];
    _baghaView.contentMode = UIViewContentModeScaleAspectFit;
    _baghaView.backgroundColor = [UIColor clearColor];

    [picker dismissViewControllerAnimated:YES completion:nil];
    isLoaded = TRUE;
}

- (IBAction)processImage:(id)sender
{
    if (isLoaded && image != nil) {
        _baghaView.image = process(image);
    }
}

- (UIImage *)fixOrientation:(UIImage *) img {
    
    // No-op if the orientation is already correct
    if (img.imageOrientation == UIImageOrientationUp) return img;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (img.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, img.size.width, img.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, img.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, img.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (img.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, img.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, img.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, img.size.width, img.size.height,
                                             CGImageGetBitsPerComponent(img.CGImage), 0,
                                             CGImageGetColorSpace(img.CGImage),
                                             CGImageGetBitmapInfo(img.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (img.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,img.size.height,img.size.width), img.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,img.size.width,img.size.height), img.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *result = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return result;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    //NSLog(@"segue triggered %@",segue.destinationViewController);
    /*if ([segue.identifier isEqualToString:@"showTargetImage"]) {
        //NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        ORView *destViewController = segue.destinationViewController;
        //destViewController.recipeName = [recipes objectAtIndex:indexPath.row];
        destViewController.image =  _hiddenView.image;
    }*/
}

@end
