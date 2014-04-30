//
//  ViewController.m
//  spritybird
//
//  Created by Alexis Creuzot on 09/02/2014.
//  Copyright (c) 2014 Alexis Creuzot. All rights reserved.
//

#import "ViewController.h"
#import "Scene.h"
#import "Score.h"

@interface ViewController ()
@property (weak,nonatomic) IBOutlet SKView * gameView;
@property (weak,nonatomic) IBOutlet UIView * getReadyView;

@property (weak,nonatomic) IBOutlet UIView * gameOverView;
@property (weak,nonatomic) IBOutlet UIImageView * medalImageView;
@property (weak,nonatomic) IBOutlet UILabel * currentScore;
@property (weak,nonatomic) IBOutlet UILabel * bestScoreLabel;

@end

int gap = 1;
int showWidth = 260;
int checkPoint = 190;
double continuousPeakThreshold = 0.5;
double timerInterval = 0.02;
double blowPoint = -11;

@implementation ViewController
{
    Scene * scene;
    UIView * flash;
}
@synthesize scrollView;
@synthesize realNumber;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    
	// Configure the view.
    //self.gameView.showsFPS = YES;
    //self.gameView.showsNodeCount = YES;
    
    // Create and configure the scene.
    scene = [Scene sceneWithSize:self.gameView.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    scene.delegate = self;
    
    // Present the scene
    self.gameOverView.alpha = 0;
    self.gameOverView.transform = CGAffineTransformMakeScale(.9, .9);
    [self.gameView presentScene:scene];
    
    
    
    scrollView.delegate = self;
    previousPreviousValue = 1;
    previousValue = 1;
    currentValue = 1;
    previousPoint = CGPointMake(0, 0);
    
    // Recorder initialization
    NSURL *url = [NSURL fileURLWithPath:@"/dev/null"];
    
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithFloat: 44100.0],                 AVSampleRateKey,
                              [NSNumber numberWithInt: kAudioFormatAppleLossless], AVFormatIDKey,
                              [NSNumber numberWithInt: 1],                         AVNumberOfChannelsKey,
                              [NSNumber numberWithInt: AVAudioQualityMax],         AVEncoderAudioQualityKey,
                              nil];
    
    NSError *error;
    
    recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
    
    // iOS7 porting
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
    //===============
    
    if (recorder) {
        [recorder prepareToRecord];
        recorder.meteringEnabled = YES;
        [recorder record];
        levelTimer = [NSTimer scheduledTimerWithTimeInterval: timerInterval target: self selector: @selector(levelTimerCallback:)
                                                    userInfo: nil repeats: YES];
    }
    
}

-(void) drawLineFrom:(CGPoint) startPoint to:(CGPoint)endPoint withColor:(UIColor*) color{
    
    // Line
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:startPoint];
    [path addLineToPoint:endPoint];
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = [path CGPath];
    if (color == nil) {
        shapeLayer.strokeColor = [[UIColor whiteColor] CGColor];
    }else{
        shapeLayer.strokeColor = [color CGColor];
    }
    
    shapeLayer.lineWidth = 1.0;
    shapeLayer.fillColor = [[UIColor clearColor] CGColor];
    
    [scrollView.layer addSublayer:shapeLayer];
}

-(void) drawCircleInPosition:(CGPoint) position{
    // Set up the shape of the circle
    int radius = 2;
    CAShapeLayer *circle = [CAShapeLayer layer];
    // Make a circular shape
    circle.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, radius, radius)
                                             cornerRadius:radius].CGPath;
    // Center the shape in self.view
    circle.position = CGPointMake(position.x-radius/2, position.y-radius/2);
    
    // Configure the apperence of the circle
    circle.fillColor = [UIColor clearColor].CGColor;
    circle.strokeColor = [UIColor redColor].CGColor;
    circle.lineWidth = 2;
    
    // Add to parent layer
    [scrollView.layer addSublayer:circle];
    
    /*
     // Configure animation
     CABasicAnimation *drawAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
     drawAnimation.duration            = 1.0; // "animate over 10 seconds or so.."
     drawAnimation.repeatCount         = 1.0;  // Animate only once..
     
     // Animate from no part of the stroke being drawn to the entire stroke being drawn
     drawAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
     drawAnimation.toValue   = [NSNumber numberWithFloat:1.0f];
     
     // Experiment with timing to get the appearence to look the way you want
     drawAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
     
     // Add the animation to the circle
     [circle addAnimation:drawAnimation forKey:@"drawCircleAnimation"];
     */
}


-(void) viewDidAppear:(BOOL)animated{
    scrollView.contentSize = CGSizeMake(320, 108);
}

- (void)levelTimerCallback:(NSTimer *)timer {
	[recorder updateMeters];
    lowPassResults = [recorder averagePowerForChannel:0];
    
    [realNumber setText:[NSString stringWithFormat:@"%.2f",lowPassResults]];
    
    if (previousPreviousValue == 1) {
        previousPreviousValue = lowPassResults;
    }else if (previousValue == 1){
        previousValue = lowPassResults;
    }else if (currentValue == 1){
        currentValue = lowPassResults;
    }else{
        previousPreviousValue = previousValue;
        previousValue = currentValue;
        currentValue = lowPassResults;
    }
    
    if ((previousValue - previousPreviousValue)>0 &&
        (currentValue-previousValue) <= 0 &&
//        ((fabs(previousValue - previousPreviousValue) >= continuousPeakThreshold) ||
//         (fabs(currentValue-previousValue) >= continuousPeakThreshold)) &&
        previousValue >= blowPoint) {
        
        [self drawCircleInPosition:CGPointMake(previousPoint.x, 80 - (60+previousValue)/60*80+20)];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"blow" object:nil userInfo:nil];
        
        NSLog(@"fly..");
    }
    
    double value = 80 - (60+lowPassResults)/60*80+20;
    CGPoint currentPoint = CGPointMake(previousPoint.x+gap, value);
    
    [self drawLineFrom:previousPoint to:currentPoint withColor:nil];
    
    if (currentPoint.x >= showWidth) {
        scrollView.contentSize = CGSizeMake(scrollView.contentSize.width+gap, scrollView.contentSize.height);
        [scrollView setContentOffset:CGPointMake(currentPoint.x-showWidth, 0) animated:NO];
    }
    
    NSLog(@"current point x:%f",currentPoint.x);
    
    previousPoint = currentPoint;
}


- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Bouncing scene delegate

- (void)eventStart
{
    [UIView animateWithDuration:.2 animations:^{
        self.gameOverView.alpha = 0;
        self.gameOverView.transform = CGAffineTransformMakeScale(.8, .8);
        flash.alpha = 0;
        self.getReadyView.alpha = 1;
    } completion:^(BOOL finished) {
        [flash removeFromSuperview];

    }];
}

- (void)eventPlay
{
    [UIView animateWithDuration:.5 animations:^{
        self.getReadyView.alpha = 0;
    }];
}

- (void)eventWasted
{
    flash = [[UIView alloc] initWithFrame:self.view.frame];
    flash.backgroundColor = [UIColor whiteColor];
//    flash.alpha = .9;
    flash.alpha = 0;
    [self.gameView insertSubview:flash belowSubview:self.getReadyView];
    
    [self shakeFrame];
    
    [UIView animateWithDuration:.6 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        
        // Display game over
//        flash.alpha = .4;
        self.gameOverView.alpha = 1;
        self.gameOverView.transform = CGAffineTransformMakeScale(1, 1);
        
        // Set medal
        if(scene.score >= 4){
            self.medalImageView.image = [UIImage imageNamed:@"medal_platinum"];
        }else if (scene.score >= 3){
            self.medalImageView.image = [UIImage imageNamed:@"medal_gold"];
        }else if (scene.score >= 2){
            self.medalImageView.image = [UIImage imageNamed:@"medal_silver"];
        }else if (scene.score >= 1){
            self.medalImageView.image = [UIImage imageNamed:@"medal_bronze"];
        }else{
            self.medalImageView.image = nil;
        }
        
        // Set scores
        self.currentScore.text = F(@"%li",(long)scene.score);
        self.bestScoreLabel.text = F(@"%li",(long)[Score bestScore]);
        
    } completion:^(BOOL finished) {
        flash.userInteractionEnabled = NO;
    }];
    
}

- (void) shakeFrame
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    [animation setDuration:0.05];
    [animation setRepeatCount:4];
    [animation setAutoreverses:YES];
    [animation setFromValue:[NSValue valueWithCGPoint:
                             CGPointMake([self.view  center].x - 4.0f, [self.view  center].y)]];
    [animation setToValue:[NSValue valueWithCGPoint:
                           CGPointMake([self.view  center].x + 4.0f, [self.view  center].y)]];
    [[self.view layer] addAnimation:animation forKey:@"position"];
}

@end
