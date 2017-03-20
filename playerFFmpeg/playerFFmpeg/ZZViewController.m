#import "ZZViewController.h"
#import "ZZEAGLView.h"
#import <MobileCoreServices/MobileCoreServices.h>
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/imgutils.h>
#include <libswscale/swscale.h>
# define ONE_FRAME_DURATION 0.03
# define LUMA_SLIDER_TAG 0
# define CHROMA_SLIDER_TAG 1

static void *AVPlayerItemStatusContext = &AVPlayerItemStatusContext;

@interface APLImagePickerController : UIImagePickerController

@end

@implementation APLImagePickerController

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskLandscape;
}

@end

@interface ZZViewController ()
{
	AVPlayer *_player;
	dispatch_queue_t _myVideoOutputQueue;
	id _notificationToken;
    id _timeObserver;
}

@property (nonatomic, weak) IBOutlet ZZEAGLView *playerView;
@property (nonatomic, weak) IBOutlet UISlider *chromaLevelSlider;
@property (nonatomic, weak) IBOutlet UISlider *lumaLevelSlider;
@property (nonatomic, weak) IBOutlet UILabel *currentTime;
@property (nonatomic, weak) IBOutlet UIView *timeView;
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property UIPopoverController *popover;

@property AVPlayerItemVideoOutput *videoOutput;
@property CADisplayLink *displayLink;

- (IBAction)updateLevels:(id)sender;
- (IBAction)loadMovieFromCameraRoll:(id)sender;
- (IBAction)handleTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer;

- (void)displayLinkCallback:(CADisplayLink *)sender;

@end


@implementation ZZViewController

#pragma mark -

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.playerView.lumaThreshold = [[self lumaLevelSlider] value];
	self.playerView.chromaThreshold = [[self chromaLevelSlider] value];

	_player = [[AVPlayer alloc] init];
    [self addTimeObserverToPlayer];
	
	// Setup CADisplayLink which will callback displayPixelBuffer: at every vsync.
	self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback:)];
	[[self displayLink] addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[[self displayLink] setPaused:YES];
	
    
	// Setup AVPlayerItemVideoOutput with the required pixelbuffer attributes.
	NSDictionary *pixBuffAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};
	self.videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixBuffAttributes];
	_myVideoOutputQueue = dispatch_queue_create("myVideoOutputQueue", DISPATCH_QUEUE_SERIAL);
	[[self videoOutput] setDelegate:self queue:_myVideoOutputQueue];
}

- (void)viewWillAppear:(BOOL)animated
{
	[self addObserver:self forKeyPath:@"player.currentItem.status" options:NSKeyValueObservingOptionNew context:AVPlayerItemStatusContext];
	[self addTimeObserverToPlayer];
	
	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[self removeObserver:self forKeyPath:@"player.currentItem.status" context:AVPlayerItemStatusContext];
	[self removeTimeObserverFromPlayer];
	
	if (_notificationToken) {
		[[NSNotificationCenter defaultCenter] removeObserver:_notificationToken name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
		_notificationToken = nil;
	}
	
	[super viewWillDisappear:animated];
}

#pragma mark - Utilities

- (IBAction)updateLevels:(id)sender
{
	NSInteger tag = [sender tag];
	
	switch (tag) {
		case LUMA_SLIDER_TAG: {
			self.playerView.lumaThreshold = [[self lumaLevelSlider] value];
			break;
		}
		case CHROMA_SLIDER_TAG: {
			self.playerView.chromaThreshold = [[self chromaLevelSlider] value];
			break;
		}
		default:
			break;
	}
}

- (IBAction)loadMovieFromCameraRoll:(id)sender
{
	[_player pause];
	[[self displayLink] setPaused:YES];
	
	if ([[self popover] isPopoverVisible]) {
		[[self popover] dismissPopoverAnimated:YES];
	}
	// Initialize UIImagePickerController to select a movie from the camera roll
	APLImagePickerController *videoPicker = [[APLImagePickerController alloc] init];
	videoPicker.delegate = self;
	videoPicker.modalPresentationStyle = UIModalPresentationCurrentContext;
	videoPicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
	videoPicker.mediaTypes = @[(NSString*)kUTTypeMovie];

	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		self.popover = [[UIPopoverController alloc] initWithContentViewController:videoPicker];
		self.popover.delegate = self;
		[[self popover] presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
	}
	else {
		[self presentViewController:videoPicker animated:YES completion:nil];
	}
}

- (IBAction)handleTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer
{
	self.toolbar.hidden = !self.toolbar.hidden;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskLandscape;
}

#pragma mark - Playback setup

- (void)setupPlaybackForURL:(NSURL *)URL
{
	/*
	 Sets up player item and adds video output to it.
	 The tracks property of an asset is loaded via asynchronous key value loading, to access the preferred transform of a video track used to orientate the video while rendering.
	 After adding the video output, we request a notification of media change in order to restart the CADisplayLink.
	 */
	
	// Remove video output from old item, if any.
	[[_player currentItem] removeOutput:self.videoOutput];

	AVPlayerItem *item = [AVPlayerItem playerItemWithURL:URL];
	AVAsset *asset = [item asset];

	[asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
			
		if ([asset statusOfValueForKey:@"tracks" error:nil] == AVKeyValueStatusLoaded) {
			NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
			if ([tracks count] > 0) {
				// Choose the first video track.
				AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
				[videoTrack loadValuesAsynchronouslyForKeys:@[@"preferredTransform"] completionHandler:^{
					
					if ([videoTrack statusOfValueForKey:@"preferredTransform" error:nil] == AVKeyValueStatusLoaded) {
						CGAffineTransform preferredTransform = [videoTrack preferredTransform];
						
						/*
                         The orientation of the camera while recording affects the orientation of the images received from an AVPlayerItemVideoOutput. Here we compute a rotation that is used to correctly orientate the video.
                         */
						self.playerView.preferredRotation = -1 * atan2(preferredTransform.b, preferredTransform.a);
						
						[self addDidPlayToEndTimeNotificationForPlayerItem:item];
						
						dispatch_async(dispatch_get_main_queue(), ^{
							[item addOutput:self.videoOutput];
							[_player replaceCurrentItemWithPlayerItem:item];
							[self.videoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:ONE_FRAME_DURATION];
							[_player play];
						});
						
					}
					
				}];
			}
		}
		
	}];
	
}

- (void)stopLoadingAnimationAndHandleError:(NSError *)error
{
	if (error) {
        NSString *cancelButtonTitle = NSLocalizedString(@"OK", @"Cancel button title for animation load error");
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription] message:[error localizedFailureReason] delegate:nil cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
		[alertView show];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == AVPlayerItemStatusContext) {
		AVPlayerStatus status = [change[NSKeyValueChangeNewKey] integerValue];
		switch (status) {
			case AVPlayerItemStatusUnknown:
				break;
			case AVPlayerItemStatusReadyToPlay:
				self.playerView.presentationRect = [[_player currentItem] presentationSize];
				break;
			case AVPlayerItemStatusFailed:
				[self stopLoadingAnimationAndHandleError:[[_player currentItem] error]];
				break;
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)addDidPlayToEndTimeNotificationForPlayerItem:(AVPlayerItem *)item
{
	if (_notificationToken)
		_notificationToken = nil;
	
	/*
     Setting actionAtItemEnd to None prevents the movie from getting paused at item end. A very simplistic, and not gapless, looped playback.
     */
	_player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
	_notificationToken = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:item queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		// Simple item playback rewind.
		[[_player currentItem] seekToTime:kCMTimeZero];
	}];
}

- (void)syncTimeLabel
{
	double seconds = CMTimeGetSeconds([_player currentTime]);
	if (!isfinite(seconds)) {
		seconds = 0;
	}
	
	int secondsInt = round(seconds);
	int minutes = secondsInt/60;
	secondsInt -= minutes*60;
	
	self.currentTime.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
	self.currentTime.textAlignment = NSTextAlignmentCenter;

	self.currentTime.text = [NSString stringWithFormat:@"%.2i:%.2i", minutes, secondsInt];
}

- (void)addTimeObserverToPlayer
{
	/*
	 Adds a time observer to the player to periodically refresh the time label to reflect current time.
	 */
    if (_timeObserver)
        return;
    /*
     Use __weak reference to self to ensure that a strong reference cycle is not formed between the view controller, player and notification block.
     */
    __weak ZZViewController* weakSelf = self;
    _timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 2) queue:dispatch_get_main_queue() usingBlock:
                 ^(CMTime time) {
                     NSLog(@"%lld %d", time.value , time.timescale);
                     [weakSelf syncTimeLabel];
                 }];
}

- (void)removeTimeObserverFromPlayer
{
    if (_timeObserver)
    {
        [_player removeTimeObserver:_timeObserver];
        _timeObserver = nil;
    }
}

#pragma mark - CADisplayLink Callback

- (void)displayLinkCallback:(CADisplayLink *)sender
{
	/*
	 The callback gets called once every Vsync.
	 Using the display link's timestamp and duration we can compute the next time the screen will be refreshed, and copy the pixel buffer for that time
	 This pixel buffer can then be processed and later rendered on screen.
	 */
	CMTime outputItemTime = kCMTimeInvalid;
	
	// Calculate the nextVsync time which is when the screen will be refreshed next.
	CFTimeInterval nextVSync = ([sender timestamp] + [sender duration]);
	
	outputItemTime = [[self videoOutput] itemTimeForHostTime:nextVSync];
	
	if ([[self videoOutput] hasNewPixelBufferForItemTime:outputItemTime]) {
		CVPixelBufferRef pixelBuffer = NULL;
		pixelBuffer = [[self videoOutput] copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:NULL];
		
		[[self playerView] displayPixelBuffer:pixelBuffer];
		
		if (pixelBuffer != NULL) {
			CFRelease(pixelBuffer);
		}
	}
}

- (void)decode
{
    AVFormatContext	*pFormatCtx;
    int				i, videoindex;
    AVCodecContext	*pCodecCtx;
    AVCodec			*pCodec;
    AVFrame	*pFrame,*pFrameYUV;
    uint8_t *out_buffer;
    AVPacket *packet;
    int y_size;
    int ret, got_picture;
    struct SwsContext *img_convert_ctx;
    FILE *fp_yuv;
    int frame_cnt;
    clock_t time_start, time_finish;
    double  time_duration = 0.0;
    
    char input_str_full[500]={0};
    char output_str_full[500]={0};
    char info[1000]={0};
    
    
//    NSString *input_str= [NSString stringWithFormat:@"resource.bundle/%@",self.inputurl.text];
    NSString *input_str= [[NSBundle mainBundle] pathForResource:@"sintel" ofType:@"mov"];
//    NSString *output_str= [NSString stringWithFormat:@"resource.bundle/%@",self.outputurl.text];
    
//    NSString *input_nsstr=[[[NSBundle mainBundle]resourcePath] stringByAppendingPathComponent:input_str];
//    NSString *output_nsstr=[[[NSBundle mainBundle]resourcePath] stringByAppendingPathComponent:output_str];
    
//    sprintf(input_str_full,"%s",[input_nsstr UTF8String]);
//    sprintf(output_str_full,"%s",[output_nsstr UTF8String]);
    
//    printf("Input Path:%s\n",input_str_full);
//    printf("Output Path:%s\n",output_str_full);
    
    av_register_all();
    avformat_network_init();
    pFormatCtx = avformat_alloc_context();
    
    if(avformat_open_input(&pFormatCtx,[input_str UTF8String],NULL,NULL)!=0){
        printf("Couldn't open input stream.\n");
        return ;
    }
    if(avformat_find_stream_info(pFormatCtx,NULL)<0){
        printf("Couldn't find stream information.\n");
        return;
    }
    videoindex=-1;
    for(i=0; i<pFormatCtx->nb_streams; i++)
        if(pFormatCtx->streams[i]->codec->codec_type==AVMEDIA_TYPE_VIDEO){
            videoindex=i;
            break;
        }
    if(videoindex==-1){
        printf("Couldn't find a video stream.\n");
        return;
    }
    pCodecCtx=pFormatCtx->streams[videoindex]->codec;
    pCodec=avcodec_find_decoder(pCodecCtx->codec_id);
    if(pCodec==NULL){
        printf("Couldn't find Codec.\n");
        return;
    }
    if(avcodec_open2(pCodecCtx, pCodec,NULL)<0){
        printf("Couldn't open codec.\n");
        return;
    }
    
    pFrame=av_frame_alloc();
    pFrameYUV=av_frame_alloc();
    out_buffer=(unsigned char *)av_malloc(av_image_get_buffer_size(AV_PIX_FMT_YUV420P,  pCodecCtx->width, pCodecCtx->height,1));
    av_image_fill_arrays(pFrameYUV->data, pFrameYUV->linesize,out_buffer,
                         AV_PIX_FMT_YUV420P,pCodecCtx->width, pCodecCtx->height,1);
    packet=(AVPacket *)av_malloc(sizeof(AVPacket));
    
    img_convert_ctx = sws_getContext(pCodecCtx->width, pCodecCtx->height, pCodecCtx->pix_fmt,
                                     pCodecCtx->width, pCodecCtx->height, AV_PIX_FMT_YUV420P, SWS_BICUBIC, NULL, NULL, NULL);
    
    
    sprintf(info,   "[Input     ]%s\n", [input_str UTF8String]);
//    sprintf(info, "%s[Output    ]%s\n",info,[output_str UTF8String]);
    sprintf(info, "%s[Format    ]%s\n",info, pFormatCtx->iformat->name);
    sprintf(info, "%s[Codec     ]%s\n",info, pCodecCtx->codec->name);
    sprintf(info, "%s[Resolution]%dx%d\n",info, pCodecCtx->width,pCodecCtx->height);
    
    
    fp_yuv=fopen(output_str_full,"wb+");
    if(fp_yuv==NULL){
        printf("Cannot open output file.\n");
        return;
    }
    
    frame_cnt=0;
//    time_start = flock();
    
    while(av_read_frame(pFormatCtx, packet)>=0){
        if(packet->stream_index==videoindex){
            ret = avcodec_decode_video2(pCodecCtx, pFrame, &got_picture, packet);
            if(ret < 0){
                printf("Decode Error.\n");
                return;
            }
            if(got_picture){
                sws_scale(img_convert_ctx, (const uint8_t* const*)pFrame->data, pFrame->linesize, 0, pCodecCtx->height,
                          pFrameYUV->data, pFrameYUV->linesize);
                
                y_size=pCodecCtx->width*pCodecCtx->height;
                fwrite(pFrameYUV->data[0],1,y_size,fp_yuv);    //Y
                fwrite(pFrameYUV->data[1],1,y_size/4,fp_yuv);  //U
                fwrite(pFrameYUV->data[2],1,y_size/4,fp_yuv);  //V
                //Output info
                char pictype_str[10]={0};
                switch(pFrame->pict_type){
                    case AV_PICTURE_TYPE_I:sprintf(pictype_str,"I");break;
                    case AV_PICTURE_TYPE_P:sprintf(pictype_str,"P");break;
                    case AV_PICTURE_TYPE_B:sprintf(pictype_str,"B");break;
                    default:sprintf(pictype_str,"Other");break;
                }
                printf("Frame Index: %5d. Type:%s\n",frame_cnt,pictype_str);
                frame_cnt++;
            }
        }
        av_free_packet(packet);
    }
    //flush decoder
    //FIX: Flush Frames remained in Codec
    while (1) {
        ret = avcodec_decode_video2(pCodecCtx, pFrame, &got_picture, packet);
        if (ret < 0)
            break;
        if (!got_picture)
            break;
        sws_scale(img_convert_ctx, (const uint8_t* const*)pFrame->data, pFrame->linesize, 0, pCodecCtx->height,
                  pFrameYUV->data, pFrameYUV->linesize);
        int y_size=pCodecCtx->width*pCodecCtx->height;
        fwrite(pFrameYUV->data[0],1,y_size,fp_yuv);    //Y
        fwrite(pFrameYUV->data[1],1,y_size/4,fp_yuv);  //U
        fwrite(pFrameYUV->data[2],1,y_size/4,fp_yuv);  //V
        //Output info
        char pictype_str[10]={0};
        switch(pFrame->pict_type){
            case AV_PICTURE_TYPE_I:sprintf(pictype_str,"I");break;
            case AV_PICTURE_TYPE_P:sprintf(pictype_str,"P");break;
            case AV_PICTURE_TYPE_B:sprintf(pictype_str,"B");break;
            default:sprintf(pictype_str,"Other");break;
        }
        printf("Frame Index: %5d. Type:%s\n",frame_cnt,pictype_str);
        frame_cnt++;
    }
//    time_finish = clock();
//    time_duration=(double)(time_finish - time_start);
    
    sprintf(info, "%s[Time      ]%fus\n",info,time_duration);
    sprintf(info, "%s[Count     ]%d\n",info,frame_cnt);
    
    sws_freeContext(img_convert_ctx);
    
    fclose(fp_yuv);
    
    av_frame_free(&pFrameYUV);
    av_frame_free(&pFrame);
    avcodec_close(pCodecCtx);
    avformat_close_input(&pFormatCtx);
    
//    NSString * info_ns = [NSString stringWithFormat:@"%s", info];
//    self.infomation.text=info_ns;
}

#pragma mark - AVPlayerItemOutputPullDelegate

- (void)outputMediaDataWillChange:(AVPlayerItemOutput *)sender
{
	// Restart display link.
	[[self displayLink] setPaused:NO];
}

#pragma mark - Image Picker Controller Delegate

- (void)imagePickerController:(APLImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		[self.popover dismissPopoverAnimated:YES];
	}
	else {
		[self dismissViewControllerAnimated:YES completion:nil];
	}
	
	if ([_player currentItem] == nil) {
		[[self lumaLevelSlider] setEnabled:YES];
		[[self chromaLevelSlider] setEnabled:YES];
		[[self playerView] setupGL];
	}
    
	// Time label shows the current time of the item.
    if (self.timeView.hidden) {
		[self.timeView.layer setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3].CGColor];
		[self.timeView.layer setCornerRadius:5.0f];
		[self.timeView.layer setBorderColor:[UIColor colorWithWhite:1.0 alpha:0.15].CGColor];
		[self.timeView.layer setBorderWidth:1.0f];
		self.timeView.hidden = NO;
		self.currentTime.hidden = NO;
    }
    
	[self setupPlaybackForURL:info[UIImagePickerControllerReferenceURL]];
	
	picker.delegate = nil;
}

- (void)imagePickerControllerDidCancel:(APLImagePickerController *)picker
{
	[self dismissViewControllerAnimated:YES completion:nil];
	
	// Make sure our playback is resumed from any interruption.
	if ([_player currentItem]) {
		[self addDidPlayToEndTimeNotificationForPlayerItem:[_player currentItem]];
	}
	
	[[self videoOutput] requestNotificationOfMediaDataChangeWithAdvanceInterval:ONE_FRAME_DURATION];
	[_player play];
	
	picker.delegate = nil;
}

# pragma mark - Popover Controller Delegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
	// Make sure our playback is resumed from any interruption.
	if ([_player currentItem]) {
		[self addDidPlayToEndTimeNotificationForPlayerItem:[_player currentItem]];
	}
	[[self videoOutput] requestNotificationOfMediaDataChangeWithAdvanceInterval:ONE_FRAME_DURATION];
	[_player play];
	
	self.popover.delegate = nil;
}

#pragma mark - Gesture recognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	if (touch.view != self.view) {
		// Ignore touch on toolbar.
		return NO;
	}
	return YES;
}

@end
