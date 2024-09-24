//
//  AudioViewController.m
//  MyApp
//
//  Created by Jinwoo Kim on 9/24/24.
//

#import "AudioViewController.h"
#import <AVFAudio/AVFAudio.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MediaAccessibility/MediaAccessibility.h>
#import <objc/message.h>
#import <objc/runtime.h>

@interface AudioViewController ()
@property (nonatomic, readonly) NSURL *audioURL;
@property (retain, nonatomic, readonly) UIStackView *stackView;
@property (retain, nonatomic, readonly) UIButton *playButton;
@property (retain, nonatomic, readonly) UIButton *pauseButton;
@property (retain, nonatomic, readonly) AVPlayer *player;
@property (retain, nonatomic, nullable) id statusObserver;
@end

@implementation AudioViewController
@synthesize stackView = _stackView;
@synthesize playButton = _playButton;
@synthesize pauseButton = _pauseButton;
@synthesize player = _player;

- (void)dealloc {
    [_stackView release];
    [_playButton release];
    [_pauseButton release];
    [_player release];
    
    [MPRemoteCommandCenter.sharedCommandCenter.playCommand removeTarget:self];
    [MPRemoteCommandCenter.sharedCommandCenter.pauseCommand removeTarget:self];
    
    if (id statusObserver = _statusObserver) {
        [MAMusicHapticsManager.sharedManager removeStatusObserver:statusObserver];
    }
    [super dealloc];
}

- (void)loadView {
    self.view = self.stackView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    assert(MAMusicHapticsManager.sharedManager.isActive);
    
    [MAMusicHapticsManager.sharedManager checkHapticTrackAvailabilityForMediaMatchingCode:@"USUG12306672" completionHandler:^(BOOL musicHapticsAvailable) {
        assert(musicHapticsAvailable);
    }];
    
    self.statusObserver = [MAMusicHapticsManager.sharedManager addStatusObserver:^(NSString * _Nonnull internationalStandardRecordingCode, BOOL musicHapticsActive) {
        abort();
    }];
    
    [UIApplication.sharedApplication beginReceivingRemoteControlEvents];
    [MPRemoteCommandCenter.sharedCommandCenter.playCommand addTarget:self action:@selector(play:)];
    [MPRemoteCommandCenter.sharedCommandCenter.pauseCommand addTarget:self action:@selector(pause:)];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(activeStatusDidChangeNotification:) name:MAMusicHapticsManagerActiveStatusDidChangeNotification object:nil];
}

- (MPRemoteCommandHandlerStatus)play:(MPRemoteCommandCenter *)sender {
    [self.player play];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (MPRemoteCommandHandlerStatus)pause:(MPRemoteCommandCenter *)sender {
    [self.player pause];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (void)activeStatusDidChangeNotification:(NSNotification *)notification {
    NSLog(@"%@", notification);
    assert(MAMusicHapticsManager.sharedManager.isActive);
}

- (NSURL *)audioURL {
    return [NSBundle.mainBundle URLForResource:@"audio" withExtension:@"m4a"];
}

- (UIStackView *)stackView {
    if (auto stackView = _stackView) return stackView;
    
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.playButton,
        self.pauseButton
    ]];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionFillEqually;
    stackView.alignment = UIStackViewAlignmentFill;
    
    _stackView = [stackView retain];
    return [stackView autorelease];
}

- (UIButton *)playButton {
    if (auto playButton = _playButton) return playButton;
    
    __weak auto weakSelf = self;
    
    UIAction *primaryAction = [UIAction actionWithTitle:@"Play" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        if (auto player = weakSelf.player) {
            [player play];
            return;
        }
        
        assert([AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback mode:AVAudioSessionModeDefault options:0 error:nullptr]);
        assert([AVAudioSession.sharedInstance setActive:YES error:nullptr]);
        
        //
        
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:weakSelf.audioURL options:nil];
        AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:asset];
        [asset release];
        AVPlayer *player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
        [playerItem release];
        player.allowsExternalPlayback = YES;
        
        assert(MAMusicHapticsManager.sharedManager.isActive);
        
        [player addPeriodicTimeObserverForInterval:CMTimeMake(1, 240) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            MPNowPlayingInfoCenter.defaultCenter.nowPlayingInfo = @{
                MPNowPlayingInfoPropertyAssetURL: weakSelf.audioURL,
                MPNowPlayingInfoPropertyInternationalStandardRecordingCode: @"USUG12306672",
                MPNowPlayingInfoPropertyElapsedPlaybackTime: @(CMTimeGetSeconds(time)),
                MPMediaItemPropertyPlaybackDuration: @(CMTimeGetSeconds(asset.duration)),
                MPNowPlayingInfoPropertyMediaType: @(MPNowPlayingInfoMediaTypeAudio),
                MPNowPlayingInfoPropertyDefaultPlaybackRate: @(1.0),
                MPNowPlayingInfoPropertyPlaybackRate: @(player.rate),
                MPNowPlayingInfoPropertyAdTimeRanges: @[[[[MPAdTimeRange alloc] initWithTimeRange:kCMTimeRangeZero] autorelease]],
                MPNowPlayingInfoPropertyPlaybackProgress: @((float)(CMTimeGetSeconds(time)) / (float)(CMTimeGetSeconds(asset.duration)))
            };
        }];
        
        [player play];
        [player release];
        
        assert(reinterpret_cast<BOOL (*)(id, SEL)>(objc_msgSend)(MAMusicHapticsManager.sharedManager, sel_registerName("musicHapticsActive")));
        assert(MAMusicHapticsManager.sharedManager.isActive);
    }];
    
    UIButton *playButton = [UIButton buttonWithType:UIButtonTypeSystem primaryAction:primaryAction];
    
    _playButton = [playButton retain];
    return playButton;
}

- (UIButton *)pauseButton {
    if (auto pauseButton = _pauseButton) return pauseButton;
    
    __weak auto weakSelf = self;
    
    UIAction *primaryAction = [UIAction actionWithTitle:@"Pause" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf.player pause];
    }];
    
    UIButton *pauseButton = [UIButton buttonWithType:UIButtonTypeSystem primaryAction:primaryAction];
    
    _pauseButton = [pauseButton retain];
    return pauseButton;
}

@end
