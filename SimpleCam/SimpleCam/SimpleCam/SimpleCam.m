//
//  SimpleCam.m
//  SimpleCam
//
//  Created by Logan Wright on 2/1/14.
//  Copyright (c) 2014 Logan Wright. All rights reserved.
//
//  Mozilla Public License v2.0
//
//  **
//
//  PLEASE FAMILIARIZE YOURSELF WITH THE ----- Mozilla Public License v2.0
//
//  **
//
//  Attribution is satisfied by acknowledging the use of SimpleCam,
//  or its creation by Logan Wright
//
//  **
//
//  You can use, modify and redistribute this code in your product,
//  but to satisfy the requirements of Mozilla Public License v2.0,
//  it is required to provide the source code for any fixes you make to it.
//
//  **
//
//  Covered Software is provided under this License on an “as is” basis, without warranty of any
//  kind, either expressed, implied, or statutory, including, without limitation, warranties that
//  the Covered Software is free of defects, merchantable, fit for a particular purpose or non-
//  infringing. The entire risk as to the quality and performance of the Covered Software is with
//  You. Should any Covered Software prove defective in any respect, You (not any Contributor)
//  assume the cost of any necessary servicing, repair, or correction. This disclaimer of
//  warranty constitutes an essential part of this License. No use of any Covered Software is
//  authorized under this License except under this disclaimer.
//
//  **
//

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

static CGFloat optionAvailableAlpha = 0.6;
static CGFloat optionUnavailableAlpha = 0.2;

#import "SimpleCam.h"

@interface SimpleCam ()
{
    // Measurements
    CGFloat screenWidth;
    CGFloat screenHeight;
    CGFloat topX;
    CGFloat topY;
    
    // Resize Toggles
    BOOL isImageResized;
    BOOL isSaveWaitingForResizedImage;
    BOOL isRotateWaitingForResizedImage;
    
    // Capture Toggle
    BOOL isCapturingImage;
}

// Used to cover animation flicker during rotation
@property (strong, nonatomic) UIView * rotationCover;

// Square Border
@property (strong, nonatomic) UIView * squareV;
@property (strong, nonatomic) UIView * layerBottom;
@property (strong, nonatomic) UIView * layerTop;

// Controls
@property (strong, nonatomic) UIButton * backBtn;
@property (strong, nonatomic) CoolButton * captureBtn;
@property (strong, nonatomic) UIButton * flashBtn;
@property (strong, nonatomic) UIButton * switchCameraBtn;
@property (strong, nonatomic) UIButton * saveBtn;
@property (strong, nonatomic) UIButton * pickerImage;

@property (strong, nonatomic) UILabel *flashLb;

// AVFoundation Properties
@property (strong, nonatomic) AVCaptureSession * mySesh;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (strong, nonatomic) AVCaptureDevice * myDevice;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer * captureVideoPreviewLayer;

// View Properties
@property (strong, nonatomic) UIView * imageStreamV;
@property (strong, nonatomic) UIImageView * capturedImageV;

@end

@implementation SimpleCam;

@synthesize hideAllControls = _hideAllControls, hideBackButton = _hideBackButton, hideCaptureButton = _hideCaptureButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.view.clipsToBounds = NO;
    self.view.backgroundColor = [UIColor blackColor];
    
    screenWidth = self.view.bounds.size.width;
    screenHeight = self.view.bounds.size.height;
    
    if  (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) self.view.frame = CGRectMake(0, 0, screenHeight, screenWidth);
    
    if (_imageStreamV == nil) _imageStreamV = [[UIView alloc]init];
    _imageStreamV.alpha = 0;
    _imageStreamV.frame = self.view.bounds;
    [self.view addSubview:_imageStreamV];
    
    if (_capturedImageV == nil) _capturedImageV = [[UIImageView alloc]init];
    _capturedImageV.frame = _imageStreamV.frame; // just to even it out
    _capturedImageV.backgroundColor = [UIColor clearColor];
    _capturedImageV.userInteractionEnabled = YES;
    _capturedImageV.contentMode = UIViewContentModeScaleAspectFill;
    [self.view insertSubview:_capturedImageV aboveSubview:_imageStreamV];
    
    // for focus
    UITapGestureRecognizer * focusTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapSent:)];
    focusTap.numberOfTapsRequired = 1;
    [_capturedImageV addGestureRecognizer:focusTap];
    
    // SETTING UP CAM
    if (_mySesh == nil) _mySesh = [[AVCaptureSession alloc] init];
    _mySesh.sessionPreset = AVCaptureSessionPresetPhoto;
    
    _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_mySesh];
    _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _captureVideoPreviewLayer.frame = _imageStreamV.layer.bounds; // parent of layer
    
    [_imageStreamV.layer addSublayer:_captureVideoPreviewLayer];
    
    // rear camera: 0 front camera: 1
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    if (devices.count==0) {
        NSLog(@"SC: No devices found (for example: simulator)");
        return;
    }
    _myDevice = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][0];
    
    if ([_myDevice isFlashAvailable] && _myDevice.flashActive && [_myDevice lockForConfiguration:nil]) {
        //NSLog(@"SC: Turning Flash Off ...");
        _myDevice.flashMode = AVCaptureFlashModeOff;
        [_myDevice unlockForConfiguration];
    }
    
    NSError * error = nil;
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:_myDevice error:&error];
    
    if (!input) {
        // Handle the error appropriately.
        NSLog(@"SC: ERROR: trying to open camera: %@", error);
        [_delegate simpleCam:self didFinishWithImage:_capturedImageV.image];
    }
    
    [_mySesh addInput:input];
    
    _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [_stillImageOutput setOutputSettings:outputSettings];
    [_mySesh addOutput:_stillImageOutput];
    
    
    [_mySesh startRunning];
    
    if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
        _captureVideoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    }
    else if (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        _captureVideoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    }
    
    if (_isSquareMode) {
        NSLog(@"SC: isSquareMode");
        _squareV = [[UIView alloc]init];
        _squareV.backgroundColor = [UIColor clearColor];
        _squareV.layer.borderWidth = 4;
        _squareV.layer.borderColor = [UIColor colorWithWhite:1 alpha:.8].CGColor;
        _squareV.bounds = CGRectMake(0, 0, screenWidth, screenWidth);
        _squareV.center = self.view.center;
        
        _squareV.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        
        [self.view addSubview:_squareV];
    }
    
    // -- LOAD ROTATION COVERS BEGIN -- //
    /*
     Rotating causes a weird flicker, I'm in the process of looking for a better
     solution, but for now, this works.
     */
    
    // Stream Cover
    _rotationCover = [UIView new];
    _rotationCover.backgroundColor = [UIColor blackColor];
    _rotationCover.bounds = CGRectMake(0, 0, screenHeight * 3, screenHeight * 3); // 1 full screen size either direction
    _rotationCover.center = self.view.center;
    _rotationCover.autoresizingMask = UIViewAutoresizingNone;
    _rotationCover.alpha = 0;
    [self.view insertSubview:_rotationCover belowSubview:_imageStreamV];
    // -- LOAD ROTATION COVERS END -- //
    
    
    //Draw a layer in front of layout
    _layerBottom = [[UIView alloc] init];
    [_layerBottom setBackgroundColor:[UIColor blackColor]];
    [_layerBottom setAlpha:0.3];
    [self.view addSubview:_layerBottom];
    
    _layerTop = [UIView new];
    [_layerTop setBackgroundColor:[UIColor blackColor]];
    [_layerTop setAlpha:0.3];
    [self.view addSubview:_layerTop];
    
    
    // -- PREPARE OUR CONTROLS -- //
    [self loadControls];
    
    
}

- (void) viewDidAppear:(BOOL)animated {
    [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        _imageStreamV.alpha = 1;
        _rotationCover.alpha = 1;
    } completion:^(BOOL finished) {
        if (finished) {
            if ([(NSObject *)_delegate respondsToSelector:@selector(simpleCamDidLoadCameraIntoView:)]) {
                [_delegate simpleCamDidLoadCameraIntoView:self];
            }
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    NSLog(@"SC: DID RECIEVE MEMORY WARNING");
    // Dispose of any resources that can be recreated.
}

#pragma mark CAMERA CONTROLS

- (void) loadControls {
    
    // -- LOAD BUTTON IMAGES BEGIN -- //
    //    UIImage * previousImg = [UIImage imageNamed:@"Previous.png"];
    //    UIImage * downloadImg = [UIImage imageNamed:@"Download.png"];
    UIImage * lighteningImg = [UIImage imageNamed:@"LighteningOrange.png"];
    UIImage * cameraRotateImg = [UIImage imageNamed:@"CameraRotateWhite.png"];
    UIImage * libraryImg = [UIImage imageNamed:@"image_library_icon"];
    // -- LOAD BUTTON IMAGES END -- //
    
    // -- LOAD BUTTONS BEGIN -- //
    _backBtn = [UIButton new];
    [_backBtn addTarget:self action:@selector(backBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_backBtn setTitle:@"Cancel" forState:UIControlStateNormal];
    [_backBtn setTintColor:[self blueColor]];
    [_backBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_backBtn setBackgroundColor:[UIColor clearColor]];
    
    
    _flashBtn = [UIButton new];
    [_flashBtn addTarget:self action:@selector(flashBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_flashBtn setImage:lighteningImg forState:UIControlStateNormal];
    [_flashBtn setTintColor:[self blueColor]];
    [_flashBtn setImageEdgeInsets:UIEdgeInsetsMake(6, 9, 6, 9)];
    
    _flashLb = [UILabel new];
    [_flashLb setUserInteractionEnabled:NO];
    [_flashLb setText:@"Auto"];
    [_flashLb setBackgroundColor:[UIColor clearColor]];
    [_flashLb setTextColor:[UIColor whiteColor]];
    [_flashLb setUserInteractionEnabled:YES];
    [_flashLb addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(flashBtnPressed:)]];

    
    _switchCameraBtn = [UIButton new];
    [_switchCameraBtn setImage:cameraRotateImg forState:UIControlStateNormal];
    [_switchCameraBtn setTintColor:[self blueColor]];
    [_switchCameraBtn setImageEdgeInsets:UIEdgeInsetsMake(9.5, 7, 9.5, 7)];
    
    _saveBtn = [UIButton new];
    [_saveBtn addTarget:self action:@selector(saveBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    //[_saveBtn setImage:downloadImg forState:UIControlStateNormal];
    [_saveBtn setTitle:@"Save" forState:UIControlStateNormal];
    [_saveBtn setTintColor:[self blueColor]];
    [_saveBtn setImageEdgeInsets:UIEdgeInsetsMake(7, 10.5, 7, 10.5)];
    
    _captureBtn = [CoolButton new];
    [_captureBtn addTarget:self action:@selector(captureBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    _pickerImage = [UIButton new];
    [_pickerImage addTarget:self action:@selector(getLibraryImage:) forControlEvents:UIControlEventTouchUpInside ];
    [_pickerImage setImage:libraryImg forState:UIControlStateNormal];
    [_pickerImage setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
    // -- LOAD BUTTONS END -- //
    
    // Stylize buttons
    for (UIView *v in @[_backBtn, _captureBtn, _flashBtn, _switchCameraBtn, _saveBtn, _pickerImage, _flashLb])  {
        v.bounds = CGRectMake(0, 0, 35, 40);
        v.hidden = YES;
        [self.view addSubview:v];
    }
    
    // If a device doesn't have multiple cameras, fade out button ...
    if ([AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo].count == 1) {
        _switchCameraBtn.alpha = optionUnavailableAlpha;
    }
    else {
        [_switchCameraBtn addTarget:self action:@selector(switchCameraBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    // Draw camera controls
    [self drawControls];
}

- (void) drawControls {
    
    if (self.hideAllControls) {
        
        // In case they want to hide after they've been displayed
        // for (UIButton * btn in @[_backBtn, _captureBtn, _flashBtn, _switchCameraBtn, _saveBtn]) {
        // btn.hidden = YES;
        // }
        return;
    }
    
    static int offsetFromSide = 10;
    //    static int offsetBetweenButtons = 20;
    
    //    static CGFloat portraitFontSize = 16.0;
    //    static CGFloat landscapeFontSize = 12.5;
    
    [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionCurveEaseOut  animations:^{
        
        //        if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        
        CGFloat padding_bottom = 40;
        CGFloat padding_top = 20;
        CGFloat centerY = screenHeight - padding_bottom; // 8 is offset from bottom (portrait), 20 is half btn height
        
        [_layerBottom setFrame:CGRectMake(0, centerY - 2 * padding_bottom + 30, screenWidth, screenHeight)];
        [_layerTop setFrame:CGRectMake(0, 0, screenWidth, 2 * padding_top)];
        
        _backBtn.bounds = CGRectMake(0, 0, 60, 40);
        _backBtn.center = CGPointMake(offsetFromSide + (_backBtn.bounds.size.width / 2) + 10, centerY);
        
        // offset from backbtn is '20'
        _captureBtn.bounds = CGRectMake(0, 0, 80, 80);
        _captureBtn.center = CGPointMake(screenWidth/ 2, screenHeight - _captureBtn.bounds.size.height / 2 - 3);
        
        // offset from capturebtn is '20'
        _flashBtn.bounds = CGRectMake(0, 0, 35, 40);
        _flashBtn.center = CGPointMake(offsetFromSide + _flashBtn.bounds.size.width / 2, padding_top);
        
        _flashLb.bounds = CGRectMake(0,0, 100, 40);
        _flashLb.center = CGPointMake(_flashBtn.frame.origin.x + _flashBtn.bounds.size.width + _flashLb.bounds.size.width / 2, padding_top);
        _flashLb.textColor = [UIColor colorWithRed:255 green:204 blue:0 alpha:1];
        // offset from flashBtn is '20'
        _switchCameraBtn.bounds = CGRectMake(0, 0, 40, 40);
        _switchCameraBtn.center = CGPointMake(screenWidth - offsetFromSide - _switchCameraBtn.bounds.size.width/2, padding_top);
        
        _pickerImage.bounds = CGRectMake(0, 0, 45, 45);
        _pickerImage.center = CGPointMake(screenWidth - offsetFromSide - _pickerImage.bounds.size.width/2, centerY);
        
        // just so it's ready when we need it to be.
        _saveBtn.frame = _pickerImage.frame;
        _saveBtn.center = CGPointMake(screenWidth - offsetFromSide - _saveBtn.bounds.size.width/2 - 10, centerY);
        /*
         Show the proper controls for picture preview and picture stream
         */
        
        // If camera preview -- show preview controls / hide capture controls
        if (_capturedImageV.image) {
            // Hide
            for (UIView * btn in @[_captureBtn, _flashBtn, _switchCameraBtn, _pickerImage, _layerTop, _flashLb])
                btn.hidden = YES;
            // Show
            _saveBtn.hidden = NO;
            // Force User Preference
            _backBtn.hidden = _hideBackButton;
        }
        // ELSE camera stream -- show capture controls / hide preview controls
        else {
            // Show
            for (UIView * btn in @[_flashBtn, _switchCameraBtn, _pickerImage, _pickerImage, _layerTop, _flashLb])
                btn.hidden = NO;
            // Hide
            _saveBtn.hidden = YES;
            // Force User Preference
            _captureBtn.hidden = _hideCaptureButton;
            _backBtn.hidden = _hideBackButton;
        }
        [self evaluateFlashBtn];
        
    } completion:nil];
}

- (void) capturePhoto {
    if (isCapturingImage) {
        return;
    }
    isCapturingImage = YES;
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in _stillImageOutput.connections)
    {
        for (AVCaptureInputPort *port in [connection inputPorts])
        {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] )
            {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) { break; }
    }
    
    [_stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
     {
         
         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
         
         UIImage * capturedImage = [[UIImage alloc]initWithData:imageData scale:1];
         
         if (_myDevice == [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][0]) {
             // rear camera active
             if (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
                 CGImageRef cgRef = capturedImage.CGImage;
                 capturedImage = [[UIImage alloc] initWithCGImage:cgRef scale:1.0 orientation:UIImageOrientationUp];
             }
             else if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
                 CGImageRef cgRef = capturedImage.CGImage;
                 capturedImage = [[UIImage alloc] initWithCGImage:cgRef scale:1.0 orientation:UIImageOrientationDown];
             }
         }
         else if (_myDevice == [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][1]) {
             // front camera active
             // flip to look the same as the camera
             if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) capturedImage = [UIImage imageWithCGImage:capturedImage.CGImage scale:capturedImage.scale orientation:UIImageOrientationLeftMirrored];
             else {
                 if (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)
                     capturedImage = [UIImage imageWithCGImage:capturedImage.CGImage scale:capturedImage.scale orientation:UIImageOrientationDownMirrored];
                 else if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft)
                     capturedImage = [UIImage imageWithCGImage:capturedImage.CGImage scale:capturedImage.scale orientation:UIImageOrientationUpMirrored];
             }
             
         }
         
         isCapturingImage = NO;
         //         _capturedImageV.image = capturedImage;
         //         imageData = nil;
         //
         //         // If we have disabled the photo preview directly fire the delegate callback, otherwise, show user a preview
         //
         //         _disablePhotoPreview ? [self photoCaptured] : [self drawControls];
         [self didCaptureImage:capturedImage];
     }];
}

- (void) didCaptureImage:(UIImage *) capturedImage{
    _capturedImageV.image = capturedImage;
    _disablePhotoPreview ? [self photoCaptured] : [self drawControls];
}

- (void) photoCaptured {
    if (!isImageResized) {
        [_delegate simpleCam:self didFinishWithImage:_capturedImageV.image];
    }
    else {
        isSaveWaitingForResizedImage = YES;
        [self resizeImage];
    }
}

#pragma mark BUTTON EVENTS

- (void) getLibraryImage:(id) sender{
    // hiden all component.
    for (UIView * btn in @[_flashBtn, _switchCameraBtn, _pickerImage, _pickerImage, _layerTop, _flashLb, _saveBtn, _captureBtn, _backBtn, _layerBottom])
        btn.hidden = NO;
    
    MBProgressHUD* HUD = [[MBProgressHUD alloc] initWithView:self.view];
    HUD.labelText = @"Loading Photo...";
    [HUD show:YES];
    [self.view addSubview:HUD];
    
    UIImagePickerController *pickerImage = [[UIImagePickerController alloc] init];
    pickerImage.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    pickerImage.delegate = self;
    
    [self presentViewController:pickerImage animated:YES completion:^(void){
        [HUD hide:YES];
        [HUD removeFromSuperview];
    }];
}

- (void) captureBtnPressed:(id)sender {
    [self capturePhoto];
}

- (void) saveBtnPressed:(id)sender {
    [self photoCaptured];
}

- (void) flashBtnPressed:(id)sender {
    //    if ([_myDevice isFlashAvailable]) {
    //        if (_myDevice.flashActive) {
    //            if([_myDevice lockForConfiguration:nil]) {
    //                _myDevice.flashMode = AVCaptureFlashModeOff;
    //                [_flashBtn setTintColor:[self redColor]];
    //            }
    //        }
    //        else {
    //            if([_myDevice lockForConfiguration:nil]) {
    //                _myDevice.flashMode = AVCaptureFlashModeOn;
    //                [_flashBtn setTintColor:[self greenColor]];
    //            }
    //        }
    //        [_myDevice unlockForConfiguration];
    //    }
    if ([_myDevice isFlashAvailable]) {
        if (_myDevice.flashMode == AVCaptureFlashModeOff) {
            if (![self setFlashMode:AVCaptureFlashModeAuto]) {
                [self setFlashMode:AVCaptureFlashModeOn];
            }
        } else if (_myDevice.flashMode == AVCaptureFlashModeOn) {
            [self setFlashMode:AVCaptureFlashModeOff];
        }else if (_myDevice.flashMode == AVCaptureFlashModeAuto) {
            [self setFlashMode:AVCaptureFlashModeOn];
        }
    }
    
    
}

- (BOOL) setFlashMode:(AVCaptureFlashMode) flashMode{
    
    if (![_myDevice isFlashModeSupported:flashMode]) {
        return false;
    }
    if ([_myDevice lockForConfiguration:nil]) {
        _myDevice.flashMode = flashMode;
        [_myDevice unlockForConfiguration];
        if (flashMode  == AVCaptureFlashModeOff) {
            [_flashBtn setTintColor:[self darkGreyColor]];
            _flashBtn.alpha = optionUnavailableAlpha;
            [_flashLb setHidden:YES];
            return YES;
        }else if (flashMode == AVCaptureFlashModeOn) {
            [_flashLb setHidden:NO];
            [_flashLb setText:@"On"];
            _flashBtn.alpha = optionAvailableAlpha;
            [_flashBtn setTintColor:[self greenColor]];
            return YES;
        }else if (flashMode == AVCaptureFlashModeAuto) {
            [_flashLb setHidden:NO];
            [_flashLb setText:@"Auto"];
            _flashBtn.alpha = optionAvailableAlpha;
            [_flashBtn setTintColor:[self greenColor]];
            return YES;
        }
    }
    [_myDevice unlockForConfiguration];
    return false;
}

- (void) backBtnPressed:(id)sender {
    if (_capturedImageV.image) {
        _capturedImageV.contentMode = UIViewContentModeScaleAspectFill;
        _capturedImageV.backgroundColor = [UIColor clearColor];
        _capturedImageV.image = nil;
        
        isRotateWaitingForResizedImage = NO;
        isImageResized = NO;
        isSaveWaitingForResizedImage = NO;
        
        [self.view insertSubview:_rotationCover belowSubview:_imageStreamV];
        
        [self drawControls];
    }
    else {
        [_delegate simpleCam:self didFinishWithImage:_capturedImageV.image];
    }
}

- (void) switchCameraBtnPressed:(id)sender {
    if (isCapturingImage != YES) {
        if (_myDevice == [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][0]) {
            // rear active, switch to front
            _myDevice = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][1];
            
            [_mySesh beginConfiguration];
            AVCaptureDeviceInput * newInput = [AVCaptureDeviceInput deviceInputWithDevice:_myDevice error:nil];
            for (AVCaptureInput * oldInput in _mySesh.inputs) {
                [_mySesh removeInput:oldInput];
            }
            [_mySesh addInput:newInput];
            [_mySesh commitConfiguration];
        }
        else if (_myDevice == [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][1]) {
            // front active, switch to rear
            _myDevice = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo][0];
            [_mySesh beginConfiguration];
            AVCaptureDeviceInput * newInput = [AVCaptureDeviceInput deviceInputWithDevice:_myDevice error:nil];
            for (AVCaptureInput * oldInput in _mySesh.inputs) {
                [_mySesh removeInput:oldInput];
            }
            [_mySesh addInput:newInput];
            [_mySesh commitConfiguration];
        }
        
        // Need to reset flash btn
        [self evaluateFlashBtn];
    }
}

- (void) evaluateFlashBtn {
    // Evaluate Flash Available?
    if (_myDevice.isFlashAvailable) {
        _flashBtn.alpha = optionAvailableAlpha;
        // Evaluate Flash Active?
        //        if (_myDevice.isFlashActive) {
        //            [_flashBtn setTintColor:[self greenColor]];
        //        }
        //        else {
        //            [_flashBtn setTintColor:[self redColor]];
        //        }
        if ([_myDevice isFlashModeSupported:AVCaptureFlashModeAuto]) {
            [self setFlashMode:AVCaptureFlashModeAuto];
        }else if ([_myDevice isFlashModeSupported:AVCaptureFlashModeOn]){
            [self setFlashMode:AVCaptureFlashModeOn];
        }else{
            [self setFlashMode:AVCaptureFlashModeOff];
        }
    }
    else {
        //        [self setFlashMode:AVCaptureFlashModeOff];
        _flashBtn.alpha = optionUnavailableAlpha;
        [_flashLb setHidden:YES];
        [_flashBtn setTintColor:[self darkGreyColor]];
    }
    
    //    [_flashBtn setTintColor:[UIColor redColor]];
}

#pragma mark TAP TO FOCUS

- (void) tapSent:(UITapGestureRecognizer *)sender {
    
    if (_capturedImageV.image == nil) {
        CGPoint aPoint = [sender locationInView:_imageStreamV];
        if (_myDevice != nil) {
            if([_myDevice isFocusPointOfInterestSupported] &&
               [_myDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                
                // we subtract the point from the width to inverse the focal point
                // focus points of interest represents a CGPoint where
                // {0,0} corresponds to the top left of the picture area, and
                // {1,1} corresponds to the bottom right in landscape mode with the home button on the right—
                // THIS APPLIES EVEN IF THE DEVICE IS IN PORTRAIT MODE
                // (from docs)
                // this is all a touch wonky
                double pX = aPoint.x / _imageStreamV.bounds.size.width;
                double pY = aPoint.y / _imageStreamV.bounds.size.height;
                double focusX = pY;
                // x is equal to y but y is equal to inverse x ?
                double focusY = 1 - pX;
                
                //NSLog(@"SC: about to focus at x: %f, y: %f", focusX, focusY);
                if([_myDevice isFocusPointOfInterestSupported] && [_myDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                    
                    if([_myDevice lockForConfiguration:nil]) {
                        [_myDevice setFocusPointOfInterest:CGPointMake(focusX, focusY)];
                        [_myDevice setFocusMode:AVCaptureFocusModeAutoFocus];
                        [_myDevice setExposurePointOfInterest:CGPointMake(focusX, focusY)];
                        [_myDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
                        //NSLog(@"SC: Done Focusing");
                    }
                    [_myDevice unlockForConfiguration];
                }
            }
        }
    }
}

#pragma mark RESIZE IMAGE

- (void) resizeImage {
    
    // Set Orientation
    BOOL isLandscape = UIInterfaceOrientationIsLandscape(self.interfaceOrientation) ? YES : NO;
    
    // Set Size
    CGSize size = (isLandscape) ? CGSizeMake(screenHeight, screenWidth) : CGSizeMake(screenWidth, screenHeight);
    if (_isSquareMode) size = _squareV.bounds.size;
    
    // Set Draw Rect
    CGRect drawRect = (isLandscape) ? ({
        // IS CURRENTLY LANDSCAPE
        
        // targetHeight is the height our image would need to be at the current screenwidth if we maintained the image ratio.
        CGFloat targetHeight = screenHeight * 0.75; // 3:4 ratio
        
        // we have to draw around the context of the screen
        // our final image will be the image that is left in the frame of the context
        // by drawing outside it, we remove the edges of the picture
        CGFloat offsetTop = (targetHeight - size.height) / 2;
        CGFloat offsetLeft = (screenHeight - size.width) / 2;
        CGRectMake(-offsetLeft, -offsetTop, screenHeight, targetHeight);
    }) : ({
        // IS CURRENTLY PORTRAIT
        // targetWidth is the width our image would need to be at the current screenheight if we maintained the image ratio.
        CGFloat targetWidth = screenHeight * 0.75; // 3:4 ratio
        
        // we have to draw around the context of the screen
        // our final image will be the image that is left in the frame of the context
        // by drawing outside it, we remove the edges of the picture
        CGFloat offsetTop = (screenHeight - size.height) / 2;
        CGFloat offsetLeft = (targetWidth - size.width) / 2;
        CGRectMake(-offsetLeft, -offsetTop, targetWidth, screenHeight);
    });
    
    // START CONTEXT
    UIGraphicsBeginImageContextWithOptions(size, YES, 2.0);
    [_capturedImageV.image drawInRect:drawRect];
    _capturedImageV.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    // END CONTEXT
    
    
    // See if someone's waiting for resized image
    if (isSaveWaitingForResizedImage == YES) [_delegate simpleCam:self didFinishWithImage:_capturedImageV.image];
    if (isRotateWaitingForResizedImage == YES) _capturedImageV.contentMode = UIViewContentModeScaleAspectFit;
    
    isImageResized = YES;
}

#pragma mark ROTATION

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration {
    
    //    if (_capturedImageV.image) {
    //        _capturedImageV.backgroundColor = [UIColor blackColor];
    //
    //        // Move for rotation
    //        [self.view insertSubview:_rotationCover belowSubview:_capturedImageV];
    //
    //        if (!isImageResized) {
    //            isRotateWaitingForResizedImage = YES;
    //            [self resizeImage];
    //        }
    //    }
    //
    //    CGRect targetRect;
    //    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
    //        targetRect = CGRectMake(0, 0, screenHeight, screenWidth);
    //
    //        if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
    //            _captureVideoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    //        }
    //        else if (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
    //            _captureVideoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    //        }
    //
    //    }
    //    else {
    //        targetRect = CGRectMake(0, 0, screenWidth, screenHeight);
    //        _captureVideoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    //    }
    //
    //
    //
    //    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
    //        for (UIView * v in @[_capturedImageV, _imageStreamV, self.view]) {
    //            v.frame = targetRect;
    //        }
    //
    //        // not in for statement, cuz layer
    //        _captureVideoPreviewLayer.frame = _imageStreamV.bounds;
    //
    //    } completion:^(BOOL finished) {
    //        [self drawControls];
    //    }];
    
}

- (BOOL) shouldAutorotate{
    return YES;
}
- (NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:^(void){
        [self didCaptureImage:image];
    }];
    
};
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:^(void){
        [self drawControls];
    }];
};

#pragma mark CLOSE

- (void) closeWithCompletion:(void (^)(void))completion {
    
    // Need alpha 0.0 before dismissing otherwise sticks out on dismissal
    _rotationCover.alpha = 0.0;
    
    [self dismissViewControllerAnimated:YES completion:^{
        
        completion();
        
        // Clean Up
        isImageResized = NO;
        isSaveWaitingForResizedImage = NO;
        isRotateWaitingForResizedImage = NO;
        
        [_mySesh stopRunning];
        _mySesh = nil;
        
        _capturedImageV.image = nil;
        [_capturedImageV removeFromSuperview];
        _capturedImageV = nil;
        
        [_imageStreamV removeFromSuperview];
        _imageStreamV = nil;
        
        [_rotationCover removeFromSuperview];
        _rotationCover = nil;
        
        _stillImageOutput = nil;
        _myDevice = nil;
        
        self.view = nil;
        _delegate = nil;
        [self removeFromParentViewController];
        
    }];
}

#pragma mark COLORS

- (UIColor *) darkGreyColor {
    return [UIColor colorWithRed:0.226082 green:0.244034 blue:0.297891 alpha:1];
}
- (UIColor *) redColor {
    return [UIColor colorWithRed:1 green:0 blue:0.105670 alpha:.6];
}
- (UIColor *) greenColor {
    return [UIColor colorWithRed:0.128085 green:.749103 blue:0.004684 alpha:0.6];
}
- (UIColor *) blueColor {
    return [UIColor colorWithRed:0 green:.478431 blue:1 alpha:1];
}

#pragma mark STATUS BAR

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark

#pragma mark GETTERS | SETTERS

- (void) setHideAllControls:(BOOL)hideAllControls {
    _hideAllControls = hideAllControls;
    
    // This way, hideAllControls can be used as a toggle.
    [self drawControls];
}
- (BOOL) hideAllControls {
    return _hideAllControls;
}
- (void) setHideBackButton:(BOOL)hideBackButton {
    _hideBackButton = hideBackButton;
    _backBtn.hidden = _hideBackButton;
}
- (BOOL) hideBackButton {
    return _hideBackButton;
}
- (void) setHideCaptureButton:(BOOL)hideCaptureButton {
    _hideCaptureButton = hideCaptureButton;
    _captureBtn.hidden = YES;
}
- (BOOL) hideCaptureButton {
    return _hideCaptureButton;
}

@end