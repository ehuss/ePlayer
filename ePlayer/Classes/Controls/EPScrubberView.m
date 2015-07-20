//
//  OBSlider.m
//
//  Created by Ole Begemann on 02.01.11.
//  Copyright 2011 Ole Begemann. All rights reserved.
//
//  https://github.com/ole/OBSlider

#import "EPScrubberView.h"

@interface EPScrubberView ()

@property (assign, nonatomic, readwrite) float scrubbingSpeed;
@property (assign, nonatomic, readwrite) float realPositionValue;
@property (assign, nonatomic) CGPoint beganTrackingLocation;

- (NSUInteger)indexOfLowerScrubbingSpeed:(NSArray*)scrubbingSpeedPositions forOffset:(CGFloat)verticalOffset;
- (NSArray *)defaultScrubbingSpeeds;
- (NSArray *)defaultScrubbingSpeedChangePositions;

@end

@implementation EPScrubberView

- (void)awakeFromNib
{
    [super awakeFromNib];

    UIImage *minTrack = [[UIImage imageNamed:@"scrubber-track-min"]
                         resizableImageWithCapInsets:UIEdgeInsetsMake(0, 9, 0, 0)];
    UIImage *maxTrack = [[UIImage imageNamed:@"scrubber-track-max"]
                         resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 9)];
    [self setMinimumTrackImage:minTrack forState:UIControlStateNormal];
    [self setMaximumTrackImage:maxTrack forState:UIControlStateNormal];
    [self setThumbImage:[UIImage imageNamed:@"scrubber-thumb"] forState:UIControlStateNormal];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        self.scrubbingSpeeds = [self defaultScrubbingSpeeds];
        self.scrubbingSpeedChangePositions = [self defaultScrubbingSpeedChangePositions];
        self.scrubbingSpeed = [[self.scrubbingSpeeds objectAtIndex:0] floatValue];
    }
    return self;
}


#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self != nil)
    {
    	if ([decoder containsValueForKey:@"scrubbingSpeeds"]) {
            self.scrubbingSpeeds = [decoder decodeObjectForKey:@"scrubbingSpeeds"];
        } else {
            self.scrubbingSpeeds = [self defaultScrubbingSpeeds];
        }
        
        if ([decoder containsValueForKey:@"scrubbingSpeedChangePositions"]) {
            self.scrubbingSpeedChangePositions = [decoder decodeObjectForKey:@"scrubbingSpeedChangePositions"];
        } else {
            self.scrubbingSpeedChangePositions = [self defaultScrubbingSpeedChangePositions];
        }
        
        self.scrubbingSpeed = [[self.scrubbingSpeeds objectAtIndex:0] floatValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    
    [coder encodeObject:self.scrubbingSpeeds forKey:@"scrubbingSpeeds"];
    [coder encodeObject:self.scrubbingSpeedChangePositions forKey:@"scrubbingSpeedChangePositions"];
    
    // No need to archive self.scrubbingSpeed as it is calculated from the arrays on init
}


#pragma mark -
#pragma mark Touch tracking

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    BOOL beginTracking = [super beginTrackingWithTouch:touch withEvent:event];
    if (beginTracking)
    {
		// Set the beginning tracking location to the centre of the current
		// position of the thumb. This ensures that the thumb is correctly re-positioned
		// when the touch position moves back to the track after tracking in one
		// of the slower tracking zones.
		CGRect thumbRect = [self thumbRectForBounds:self.bounds
										  trackRect:[self trackRectForBounds:self.bounds]
											  value:self.value];
        self.beganTrackingLocation = CGPointMake(thumbRect.origin.x + thumbRect.size.width / 2.0f,
												 thumbRect.origin.y + thumbRect.size.height / 2.0f);
        self.realPositionValue = self.value;
        [self updateSpeedLabel];
    }
    return beginTracking;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (self.tracking)
    {
        CGPoint previousLocation = [touch previousLocationInView:self];
        CGPoint currentLocation  = [touch locationInView:self];
        CGFloat trackingOffset = currentLocation.x - previousLocation.x;
        
        // Find the scrubbing speed that curresponds to the touch's vertical offset
        CGFloat verticalOffset = (CGFloat)fabs(currentLocation.y - self.beganTrackingLocation.y);
        NSUInteger scrubbingSpeedChangePosIndex = [self indexOfLowerScrubbingSpeed:self.scrubbingSpeedChangePositions forOffset:verticalOffset];
        if (scrubbingSpeedChangePosIndex == NSNotFound) {
            scrubbingSpeedChangePosIndex = [self.scrubbingSpeeds count];
        }
        self.scrubbingSpeed = [[self.scrubbingSpeeds objectAtIndex:scrubbingSpeedChangePosIndex - 1] floatValue];
        
        CGRect trackRect = [self trackRectForBounds:self.bounds];
        self.realPositionValue = self.realPositionValue + (self.maximumValue - self.minimumValue) * (trackingOffset / trackRect.size.width);
        
		CGFloat valueAdjustment = self.scrubbingSpeed * (self.maximumValue - self.minimumValue) * (trackingOffset / trackRect.size.width);
		CGFloat thumbAdjustment = 0.0f;
        if ( ((self.beganTrackingLocation.y < currentLocation.y) && (currentLocation.y < previousLocation.y)) ||
            ((self.beganTrackingLocation.y > currentLocation.y) && (currentLocation.y > previousLocation.y)) )
        {
            // We are getting closer to the slider, go closer to the real location
			thumbAdjustment = (self.realPositionValue - self.value) / (1 + fabs(currentLocation.y - self.beganTrackingLocation.y));
        }
		self.value += valueAdjustment + thumbAdjustment;
        
        if (self.continuous) {
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }
        
        [self updateSpeedLabel];
    }
    return self.tracking;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (self.tracking)
    {
        self.scrubbingSpeed = [[self.scrubbingSpeeds objectAtIndex:0] floatValue];
        [self sendActionsForControlEvents:UIControlEventValueChanged];
        if (self.speedLabel) {
            [self.speedLabel removeFromSuperview];
            self.speedLabel = nil;
        }
    }
}

- (void)updateSpeedLabel
{
    if (self.speedLabel == nil) {
        self.speedLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.speedLabel.font = [UIFont boldSystemFontOfSize:14];
        self.speedLabel.textColor = [UIColor whiteColor];
        self.speedLabel.opaque = NO;
        self.speedLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:self.speedLabel];
    }
    CGRect thumbRect = [self thumbRectForBounds:self.bounds
                                      trackRect:[self trackRectForBounds:self.bounds]
                                          value:self.value];
    self.speedLabel.text = [NSString stringWithFormat:@"%i%%", (int)(self.scrubbingSpeed*100)];
    [self.speedLabel sizeToFit];
//    self.speedLabel.center = CGPointMake(thumbRect.origin.x-self.speedLabel.bounds.size.width-2,
//                                         thumbRect.origin.y+thumbRect.size.height/2);
    self.speedLabel.center = CGPointMake(thumbRect.origin.x+thumbRect.size.width/2,
                                         thumbRect.origin.y-self.speedLabel.bounds.size.height+8);
    
    
}


#pragma mark - Helper methods

// Return the lowest index in the array of numbers passed in scrubbingSpeedPositions
// whose value is smaller than verticalOffset.
- (NSUInteger) indexOfLowerScrubbingSpeed:(NSArray*)scrubbingSpeedPositions forOffset:(CGFloat)verticalOffset
{
    for (NSUInteger i = 0; i < [scrubbingSpeedPositions count]; i++) {
        NSNumber *scrubbingSpeedOffset = [scrubbingSpeedPositions objectAtIndex:i];
        if (verticalOffset < [scrubbingSpeedOffset floatValue]) {
            return i;
        }
    }
    return NSNotFound;
}


#pragma mark - Default values

// Used in -initWithFrame: and -initWithCoder:
- (NSArray *) defaultScrubbingSpeeds
{
    return [NSArray arrayWithObjects:
            [NSNumber numberWithFloat:1.0f],
            [NSNumber numberWithFloat:0.5f],
            [NSNumber numberWithFloat:0.25f],
            [NSNumber numberWithFloat:0.1f],
            nil];
}

- (NSArray *) defaultScrubbingSpeedChangePositions
{
    return [NSArray arrayWithObjects:
            [NSNumber numberWithFloat:0.0f],
            [NSNumber numberWithFloat:100.0f],
            [NSNumber numberWithFloat:200.0f],
            [NSNumber numberWithFloat:300.0f],
            nil];
}

@end