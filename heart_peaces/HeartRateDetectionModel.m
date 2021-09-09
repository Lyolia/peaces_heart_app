//
//  HeartRateDetection.m
//  HeartRate


#import "HeartRateDetectionModel.h"

const int FRAMES_PER_SECOND = 30;// 30 // 60 rate increased
const int SECONDS = 12; //30;

@interface HeartRateDetectionModel() <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) NSMutableArray *dataPointsHue;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *input;
@end

@implementation HeartRateDetectionModel

#pragma mark - Data collection


- (void)initDetection
{

}

- (void)startDetection
{
    self.dataPointsHue = [[NSMutableArray alloc] init];
       
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetLow;

    self.captureDevice = [AVCaptureDevice defaultDeviceWithDeviceType: AVCaptureDeviceTypeBuiltInWideAngleCamera
      mediaType: AVMediaTypeVideo
       position: AVCaptureDevicePositionBack];
    
    // =====
    // Find the max frame rate we can get from the given device
    AVCaptureDeviceFormat *currentFormat;
    for (AVCaptureDeviceFormat *format in self.captureDevice.formats)
    {
        NSArray *ranges = format.videoSupportedFrameRateRanges;
        AVFrameRateRange *frameRates = ranges[0];
        
        // Find the lowest resolution format at the frame rate we want.
        if (frameRates.maxFrameRate == FRAMES_PER_SECOND && (!currentFormat || (CMVideoFormatDescriptionGetDimensions(format.formatDescription).width < CMVideoFormatDescriptionGetDimensions(currentFormat.formatDescription).width && CMVideoFormatDescriptionGetDimensions(format.formatDescription).height < CMVideoFormatDescriptionGetDimensions(currentFormat.formatDescription).height)))
        {
            currentFormat = format;
        }
    }
     NSLog(@"=== 2 ====: %@", currentFormat);
    // Tell the device to use the max frame rate.
    //[self.session beginConfiguration];
    if ([self.captureDevice hasTorch]) {
        [self.captureDevice lockForConfiguration:nil];
        self.captureDevice.torchMode=AVCaptureTorchModeOn;
        self.captureDevice.activeFormat = currentFormat;
        self.captureDevice.activeVideoMinFrameDuration = CMTimeMake(1, FRAMES_PER_SECOND);
        self.captureDevice.activeVideoMaxFrameDuration = CMTimeMake(1, FRAMES_PER_SECOND);
       
        [self.captureDevice unlockForConfiguration];
    }
    
     NSLog(@"=== 3 ====");
     NSError *error;
     self.input = [[AVCaptureDeviceInput alloc] initWithDevice:self.captureDevice error:&error];
     //[self.session addInput:input];
 
     if (error)
     {
        NSLog(@"error %@", error);
     }
    
    // Set the output
    AVCaptureVideoDataOutput* videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    // create a queue to run the capture on
    dispatch_queue_t captureQueue=dispatch_queue_create("catpureQueue", NULL);
    
    // setup our delegate
    [videoOutput setSampleBufferDelegate:self queue:captureQueue];
    
    // configure the pixel format
    videoOutput.videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey,
                                 nil];
    videoOutput.alwaysDiscardsLateVideoFrames = NO;
    
    [self.session addInput:self.input];
    [self.session addOutput:videoOutput];
    
    // Start the video session
    //[self.session commitConfiguration];
    [self.session startRunning];
    
    
    // added
    if ([self.captureDevice hasTorch]) {
        [self.captureDevice lockForConfiguration:nil];
        self.captureDevice.torchMode=AVCaptureTorchModeOn;
        [self.captureDevice unlockForConfiguration];
    }
    
    NSLog(@"=== 4 ====");
    if (self.delegate)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate heartRateStart];
        });
    }
}

-(void)interruptDetection
{
    [self.session stopRunning];
    self.session = nil;

    [[NSNotificationCenter defaultCenter] postNotificationName: @"stop_detection_notification" object:nil];
    //[self.session release];
    //TODO: session release
    
    if (self.delegate)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate handleHeartRateMonitorInterruption];
        });
    }
}

- (void)stopDetection
{
    [self.session stopRunning];
    self.session = nil;
    //[self.session release];
    //TODO: session release
    
    if (self.delegate)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate heartRateEnd];
        });
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
 
    NSLog(@">> didOutputSampleBuffer");
    static int count=0;
    count++;
    // only run if we're not already processing an image
    // this is the image buffer
    CVImageBufferRef cvimgRef = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // Lock the image buffer
    CVPixelBufferLockBaseAddress(cvimgRef,0);
    
    // access the data
    NSInteger width = CVPixelBufferGetWidth(cvimgRef);
    NSInteger height = CVPixelBufferGetHeight(cvimgRef);
    
    // get the raw image bytes
    uint8_t *buf=(uint8_t *) CVPixelBufferGetBaseAddress(cvimgRef);
    size_t bprow=CVPixelBufferGetBytesPerRow(cvimgRef);
    float r=0,g=0,b=0;
    
    long widthScaleFactor = width/192;
    long heightScaleFactor = height/144;
    
    // Get the average rgb values for the entire image.
    for(int y=0; y < height; y+=heightScaleFactor) {
        for(int x=0; x < width*4; x+=(4*widthScaleFactor)) {
            b+=buf[x];
            g+=buf[x+1];
            r+=buf[x+2];
            // a+=buf[x+3];
        }
        buf+=bprow;
    }
    
    r/=255*(float) (width*height/widthScaleFactor/heightScaleFactor);
    g/=255*(float) (width*height/widthScaleFactor/heightScaleFactor);
    b/=255*(float) (width*height/widthScaleFactor/heightScaleFactor);
    
    // The hue value is the most expressive when looking for heart beats.
    // Here we convert our rgb values in hsv and continue with the h value.
    UIColor *color = [UIColor colorWithRed:r green:g blue:b alpha:1.0];
    CGFloat hue, sat, bright;
    [color getHue:&hue saturation:&sat brightness:&bright alpha:nil];
    
    NSLog(@">> r: %f", r);
    NSLog(@">> g: %f", g);
    NSLog(@">> b: %f", b);
    NSLog(@">> hue: %f", hue);
    NSLog(@">> sat: %f", sat);
    NSLog(@">> bright: %f", bright);
    
 // do a sanity check to see if a finger is placed over the camera
    if(sat<0.5 && bright<0.5 && self.dataPointsHue.count > 2) {
            
        NSLog(@"Please put the finger to the camera");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate updateLabel: @"Please put the finger to the camera"];
                  
        });
        [self stopDetection]; // probably don't need
        [self interruptDetection];
        
        
    } else {
        [self.dataPointsHue addObject:@(hue)];
        
        //TODO: display diagramm
        //dispatch_async(dispatch_get_main_queue(), ^{
        //    [self.delegate diagramUpdate: self.dataPointsHue];
        //});
        
        // Only send UI updates once a second
        NSLog(@">> self.dataPointsHue.count: %lu",(unsigned long)self.dataPointsHue.count);
        NSLog(@">> FRAMES_PER_SECOND: %d",FRAMES_PER_SECOND);
        if (self.dataPointsHue.count % FRAMES_PER_SECOND == 0)
        {
            NSLog(@">> YESSSSS");
            if (self.delegate)
            {
                float displaySeconds = self.dataPointsHue.count / FRAMES_PER_SECOND;
                
                NSLog(@">> dataPointsHue: %@",self.dataPointsHue);
                
                NSArray *bandpassFilteredItems = [self butterworthBandpassFilter:self.dataPointsHue];
                NSLog(@">> bandpassFilteredItems: %@",bandpassFilteredItems);
                
                NSArray *smoothedBandpassItems = [self medianSmoothing:bandpassFilteredItems];
                //NSLog(@">> smoothedBandpassItems: %@",smoothedBandpassItems);
                
                
                int peakCount = [self peakCount:smoothedBandpassItems];
                //int peakCount = [self peakCount:bandpassFilteredItems];
                NSLog(@">> peakCount: %d", peakCount);
                
                
                float secondsPassed = smoothedBandpassItems.count / FRAMES_PER_SECOND;
               
                NSLog(@">> secondsPassed: %f", secondsPassed);
                float percentage = secondsPassed / 60;
                NSLog(@">> percentage: %f", percentage);
                float heartRate = peakCount / percentage;

                dispatch_async(dispatch_get_main_queue(), ^{
                   [self.delegate diagramUpdate: bandpassFilteredItems];
                   [self.delegate heartRateUpdate:heartRate atTime:displaySeconds];
                });
            }
        }
    }


    // If we have enough data points, start the analysis
    if (self.dataPointsHue.count == (SECONDS * FRAMES_PER_SECOND))
    {
        [self stopDetection];
    }
    
    // Unlock the image buffer
    CVPixelBufferUnlockBaseAddress(cvimgRef,0);
}

#pragma mark - Data processing

- (NSArray *)butterworthBandpassFilter:(NSArray *)inputData
{
    const int NZEROS = 8;
    const int NPOLES = 8;
    static float xv[NZEROS+1], yv[NPOLES+1];
    
    // http://www-users.cs.york.ac.uk/~fisher/cgi-bin/mkfscript
    // Butterworth Bandpass filter
    // 4th order
    // sample rate - varies between possible camera frequencies. Either 30, 60, 120, or 240 FPS
    // corner1 freq. = 0.667 Hz (assuming a minimum heart rate of 40 bpm, 40 beats/60 seconds = 0.667 Hz)
    // corner2 freq. = 4.167 Hz (assuming a maximum heart rate of 250 bpm, 250 beats/60 secods = 4.167 Hz)
    // Bandpass filter was chosen because it removes frequency noise outside of our target range (both higher and lower)
    double dGain = 1.232232910e+02;
    
    NSMutableArray *outputData = [[NSMutableArray alloc] init];
    for (NSNumber *number in inputData)
    {
        double input = number.doubleValue;
        
        xv[0] = xv[1]; xv[1] = xv[2]; xv[2] = xv[3]; xv[3] = xv[4]; xv[4] = xv[5]; xv[5] = xv[6]; xv[6] = xv[7]; xv[7] = xv[8];
        xv[8] = input / dGain;
        yv[0] = yv[1]; yv[1] = yv[2]; yv[2] = yv[3]; yv[3] = yv[4]; yv[4] = yv[5]; yv[5] = yv[6]; yv[6] = yv[7]; yv[7] = yv[8];
        yv[8] =   (xv[0] + xv[8]) - 4 * (xv[2] + xv[6]) + 6 * xv[4]
        + ( -0.1397436053 * yv[0]) + (  1.2948188815 * yv[1])
        + ( -5.4070037946 * yv[2]) + ( 13.2683981280 * yv[3])
        + (-20.9442560520 * yv[4]) + ( 21.7932169160 * yv[5])
        + (-14.5817197500 * yv[6]) + (  5.7161939252 * yv[7]);
        
        [outputData addObject:@(yv[8])];
    }
    
    return outputData;
}


// Find the peaks in our data - these are the heart beats.
// At a 30 Hz detection rate, assuming 250 max beats per minute, a peak can't be closer than 7 data points apart.
- (int)peakCount:(NSArray *)inputData
{
    if (inputData.count == 0)
    {
        return 0;
    }
    
    int count = 0;
    
    for (int i = 3; i < inputData.count - 3;)
    {
        if ([inputData[i] doubleValue]> 0 &&
            [inputData[i] doubleValue] > [inputData[i-1] doubleValue] &&
            [inputData[i] doubleValue] > [inputData[i-2] doubleValue] &&
            [inputData[i] doubleValue] > [inputData[i-3] doubleValue] &&
            [inputData[i] doubleValue] >= [inputData[i+1] doubleValue] &&
            [inputData[i] doubleValue] >= [inputData[i+2] doubleValue] &&
            [inputData[i] doubleValue] >= [inputData[i+3] doubleValue]
            )
        {
            NSLog(@">> peak: %@", inputData[i]);
            count = count + 1;
            i = i + 4;
        }
        else
        {
            i = i + 1;
        }
    }
    
    return count;
}

// Smoothed data helps remove outliers that may be caused by interference, finger movement or pressure changes.
// This will only help with small interference changes.
// This also helps keep the data more consistent.
- (NSArray *)medianSmoothing:(NSArray *)inputData
{
    NSMutableArray *newData = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < inputData.count; i++)
    {
        if (i == 0 ||
            i == 1 ||
            i == 2 ||
            i == inputData.count - 1 ||
            i == inputData.count - 2 ||
            i == inputData.count - 3)        {
            [newData addObject:inputData[i]];
        }
        else
        {
            NSArray *items = [@[
                                inputData[i-2],
                                inputData[i-1],
                                inputData[i],
                                inputData[i+1],
                                inputData[i+2],
                                ] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES]]];
            
            [newData addObject:items[2]];
        }
    }
    
    return newData;
}

@end










