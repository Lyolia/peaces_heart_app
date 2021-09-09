//
//  HeartRateDetection.h
//  HeartRate


#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol HeartRateDetectionModelDelegate


- (void)heartRateStart;
- (void)heartRateUpdate:(int)bpm atTime:(int)seconds;
- (void)diagramUpdate:(NSArray*)dataPointsHue;
- (void)updateLabel:(NSString*)text;
- (void)heartRateEnd;
- (void)handleHeartRateMonitorInterruption;

@end

@interface HeartRateDetectionModel : NSObject

@property (nonatomic, strong) id<HeartRateDetectionModelDelegate> delegate;


- (void)initDetection;
- (void)startDetection;
- (void)stopDetection;

@end
