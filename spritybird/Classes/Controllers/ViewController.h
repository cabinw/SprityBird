//
//  ViewController.h
//  spritybird
//
//  Created by Alexis Creuzot on 09/02/2014.
//  Copyright (c) 2014 Alexis Creuzot. All rights reserved.
//

#import "Scene.h"
#import <CoreAudio/CoreAudioTypes.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController<SceneDelegate,UIScrollViewDelegate>{
    AVAudioRecorder *recorder;
    NSTimer *levelTimer;
    double lowPassResults;
    
    double previousPreviousValue;
    double previousValue;
    double currentValue;
    
    CGPoint previousPoint;
}

@property (nonatomic,strong) IBOutlet UIScrollView* scrollView;
@property (nonatomic,strong) IBOutlet UILabel* realNumber;

@end
