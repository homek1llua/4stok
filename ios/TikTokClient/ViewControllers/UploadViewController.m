#import "UploadViewController.h"
#import "APIClient.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>

@interface UploadViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UIButton *selectButton;
@property (nonatomic, strong) UIImageView *previewView;
@property (nonatomic, strong) UITextField *captionField;
@property (nonatomic, strong) UIButton *uploadButton;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSURL *selectedVideoURL;
@property (nonatomic, strong) NSData *videoData;
@property (nonatomic, strong) UILabel *statusLabel;

@end

@implementation UploadViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor blackColor];
  self.title = @"Upload";
  [self setupUI];
}

- (void)setupUI {
  self.previewView = [[UIImageView alloc] init];
  self.previewView.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1];
  self.previewView.contentMode = UIViewContentModeScaleAspectFit;
  self.previewView.layer.cornerRadius = 8;
  self.previewView.clipsToBounds = YES;
  self.previewView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.previewView];

  self.selectButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.selectButton setTitle:@"Select Video" forState:UIControlStateNormal];
  [self.selectButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  self.selectButton.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
  self.selectButton.layer.cornerRadius = 8;
  self.selectButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
  self.selectButton.translatesAutoresizingMaskIntoConstraints = NO;
  [self.selectButton addTarget:self action:@selector(selectVideo) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.selectButton];

  self.captionField = [[UITextField alloc] init];
  self.captionField.placeholder = @"Write a caption...";
  self.captionField.textColor = [UIColor whiteColor];
  self.captionField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Write a caption..." attributes:@{NSForegroundColorAttributeName: [UIColor grayColor]}];
  self.captionField.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1];
  self.captionField.layer.cornerRadius = 8;
  self.captionField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 0)];
  self.captionField.leftViewMode = UITextFieldViewModeAlways;
  self.captionField.delegate = self;
  self.captionField.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.captionField];

  self.uploadButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.uploadButton setTitle:@"Upload" forState:UIControlStateNormal];
  [self.uploadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  self.uploadButton.backgroundColor = [UIColor colorWithRed:1 green:0.22 blue:0.42 alpha:1];
  self.uploadButton.layer.cornerRadius = 8;
  self.uploadButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
  self.uploadButton.translatesAutoresizingMaskIntoConstraints = NO;
  self.uploadButton.enabled = NO;
  self.uploadButton.alpha = 0.5;
  [self.uploadButton addTarget:self action:@selector(uploadVideo) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.uploadButton];

  self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
  self.progressView.progressTintColor = [UIColor colorWithRed:1 green:0.22 blue:0.42 alpha:1];
  self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
  self.progressView.hidden = YES;
  [self.view addSubview:self.progressView];

  self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
  self.spinner.translatesAutoresizingMaskIntoConstraints = NO;
  self.spinner.hidesWhenStopped = YES;
  [self.view addSubview:self.spinner];

  self.statusLabel = [[UILabel alloc] init];
  self.statusLabel.textColor = [UIColor lightGrayColor];
  self.statusLabel.font = [UIFont systemFontOfSize:14];
  self.statusLabel.textAlignment = NSTextAlignmentCenter;
  self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.statusLabel];

  // Layout
  [self.previewView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
  [self.previewView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:100].active = YES;
  [self.previewView.widthAnchor constraintEqualToConstant:280].active = YES;
  [self.previewView.heightAnchor constraintEqualToConstant:400].active = YES;

  [self.selectButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
  [self.selectButton.topAnchor constraintEqualToAnchor:self.previewView.bottomAnchor constant:16].active = YES;
  [self.selectButton.widthAnchor constraintEqualToConstant:200].active = YES;
  [self.selectButton.heightAnchor constraintEqualToConstant:44].active = YES;

  [self.captionField.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
  [self.captionField.topAnchor constraintEqualToAnchor:self.selectButton.bottomAnchor constant:16].active = YES;
  [self.captionField.widthAnchor constraintEqualToConstant:300].active = YES;
  [self.captionField.heightAnchor constraintEqualToConstant:44].active = YES;

  [self.uploadButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
  [self.uploadButton.topAnchor constraintEqualToAnchor:self.captionField.bottomAnchor constant:24].active = YES;
  [self.uploadButton.widthAnchor constraintEqualToConstant:200].active = YES;
  [self.uploadButton.heightAnchor constraintEqualToConstant:50].active = YES;

  [self.progressView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
  [self.progressView.topAnchor constraintEqualToAnchor:self.uploadButton.bottomAnchor constant:20].active = YES;
  [self.progressView.widthAnchor constraintEqualToConstant:280].active = YES;

  [self.spinner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
  [self.spinner.topAnchor constraintEqualToAnchor:self.progressView.bottomAnchor constant:16].active = YES;

  [self.statusLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
  [self.statusLabel.topAnchor constraintEqualToAnchor:self.spinner.bottomAnchor constant:8].active = YES;
}

- (void)selectVideo {
  UIImagePickerController *picker = [[UIImagePickerController alloc] init];
  picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  picker.mediaTypes = @[(NSString *)kUTTypeMovie, (NSString *)kUTTypeVideo];
  picker.delegate = self;
  picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
  [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  [picker dismissViewControllerAnimated:YES completion:nil];

  self.selectedVideoURL = info[UIImagePickerControllerMediaURL];
  if (!self.selectedVideoURL) {
    self.selectedVideoURL = info[UIImagePickerControllerReferenceURL];
  }

  // Generate thumbnail
  AVAsset *asset = [AVAsset assetWithURL:self.selectedVideoURL];
  AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
  gen.appliesPreferredTrackTransform = YES;
  CMTime time = CMTimeMake(1, 1);
  CGImageRef imageRef = [gen copyCGImageAtTime:time actualTime:nil error:nil];
  if (imageRef) {
    UIImage *thumb = [UIImage imageWithCGImage:imageRef];
    self.previewView.image = thumb;
    CGImageRelease(imageRef);
  }

  // Read video data
  self.videoData = [NSData dataWithContentsOfURL:self.selectedVideoURL];
  self.uploadButton.enabled = YES;
  self.uploadButton.alpha = 1.0;
  self.statusLabel.text = [NSString stringWithFormat:@"Selected: %.1f MB", self.videoData.length / (1024.0 * 1024.0)];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)uploadVideo {
  if (!self.videoData) return;

  self.uploadButton.enabled = NO;
  self.uploadButton.alpha = 0.5;
  self.progressView.hidden = NO;
  self.progressView.progress = 0;
  [self.spinner startAnimating];
  self.statusLabel.text = @"Uploading...";

  // Simulate progress
  __block float progress = 0;
  [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer *timer) {
    progress += 0.02;
    if (progress > 0.9) progress = 0.9;
    self.progressView.progress = progress;
  }];

  [[APIClient sharedClient] uploadVideoWithData:self.videoData caption:self.captionField.text progress:nil success:^(id response) {
    self.progressView.progress = 1.0;
    [self.spinner stopAnimating];
    self.statusLabel.text = @"Upload complete!";
    [self showAlert:@"Video uploaded successfully!"];

    // Reset
    self.videoData = nil;
    self.selectedVideoURL = nil;
    self.previewView.image = nil;
    self.captionField.text = @"";
    self.uploadButton.enabled = NO;
    self.uploadButton.alpha = 0.5;
    self.progressView.hidden = YES;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
      self.statusLabel.text = @"";
    });
  } failure:^(NSError *error) {
    [self.spinner stopAnimating];
    self.progressView.hidden = YES;
    self.uploadButton.enabled = YES;
    self.uploadButton.alpha = 1.0;
    self.statusLabel.text = @"Upload failed";
    [self showAlert:error.localizedDescription];
  }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}

- (void)showAlert:(NSString *)msg {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
}

@end
