#import "SignupViewController.h"
#import "APIClient.h"
#import "User.h"
#import "AppDelegate.h"

@interface SignupViewController ()

@property (nonatomic, strong) UITextField *usernameField;
@property (nonatomic, strong) UITextField *displayNameField;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UIButton *signupButton;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end

@implementation SignupViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor blackColor];
  self.title = @"Create Account";
  [self setupUI];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupUI {
  self.usernameField = [[UITextField alloc] init];
  self.usernameField.placeholder = @"Username";
  self.usernameField.textColor = [UIColor whiteColor];
  self.usernameField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Username" attributes:@{NSForegroundColorAttributeName: [UIColor grayColor]}];
  self.usernameField.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1];
  self.usernameField.layer.cornerRadius = 8;
  self.usernameField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 0)];
  self.usernameField.leftViewMode = UITextFieldViewModeAlways;
  self.usernameField.translatesAutoresizingMaskIntoConstraints = NO;
  self.usernameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
  self.usernameField.autocorrectionType = UITextAutocorrectionTypeNo;
  [self.view addSubview:self.usernameField];

  self.displayNameField = [[UITextField alloc] init];
  self.displayNameField.placeholder = @"Display Name (optional)";
  self.displayNameField.textColor = [UIColor whiteColor];
  self.displayNameField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Display Name (optional)" attributes:@{NSForegroundColorAttributeName: [UIColor grayColor]}];
  self.displayNameField.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1];
  self.displayNameField.layer.cornerRadius = 8;
  self.displayNameField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 0)];
  self.displayNameField.leftViewMode = UITextFieldViewModeAlways;
  self.displayNameField.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.displayNameField];

  self.passwordField = [[UITextField alloc] init];
  self.passwordField.placeholder = @"Password";
  self.passwordField.textColor = [UIColor whiteColor];
  self.passwordField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Password" attributes:@{NSForegroundColorAttributeName: [UIColor grayColor]}];
  self.passwordField.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1];
  self.passwordField.layer.cornerRadius = 8;
  self.passwordField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 0)];
  self.passwordField.leftViewMode = UITextFieldViewModeAlways;
  self.passwordField.secureTextEntry = YES;
  self.passwordField.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.passwordField];

  self.signupButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.signupButton setTitle:@"Sign Up" forState:UIControlStateNormal];
  [self.signupButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  self.signupButton.backgroundColor = [UIColor colorWithRed:1 green:0.22 blue:0.42 alpha:1];
  self.signupButton.layer.cornerRadius = 8;
  self.signupButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
  self.signupButton.translatesAutoresizingMaskIntoConstraints = NO;
  [self.signupButton addTarget:self action:@selector(signupTapped) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.signupButton];

  self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
  self.spinner.translatesAutoresizingMaskIntoConstraints = NO;
  self.spinner.hidesWhenStopped = YES;
  [self.view addSubview:self.spinner];

  [self.usernameField.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
  [self.usernameField.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:120].active = YES;
  [self.usernameField.widthAnchor constraintEqualToConstant:300].active = YES;
  [self.usernameField.heightAnchor constraintEqualToConstant:48].active = YES;

  [self.displayNameField.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
  [self.displayNameField.topAnchor constraintEqualToAnchor:self.usernameField.bottomAnchor constant:14].active = YES;
  [self.displayNameField.widthAnchor constraintEqualToConstant:300].active = YES;
  [self.displayNameField.heightAnchor constraintEqualToConstant:48].active = YES;

  [self.passwordField.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
  [self.passwordField.topAnchor constraintEqualToAnchor:self.displayNameField.bottomAnchor constant:14].active = YES;
  [self.passwordField.widthAnchor constraintEqualToConstant:300].active = YES;
  [self.passwordField.heightAnchor constraintEqualToConstant:48].active = YES;

  [self.signupButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
  [self.signupButton.topAnchor constraintEqualToAnchor:self.passwordField.bottomAnchor constant:24].active = YES;
  [self.signupButton.widthAnchor constraintEqualToConstant:300].active = YES;
  [self.signupButton.heightAnchor constraintEqualToConstant:50].active = YES;

  [self.spinner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
  [self.spinner.topAnchor constraintEqualToAnchor:self.signupButton.bottomAnchor constant:20].active = YES;
}

- (void)signupTapped {
  [self.view endEditing:YES];
  NSString *username = self.usernameField.text;
  NSString *password = self.passwordField.text;
  NSString *displayName = self.displayNameField.text;

  if (username.length < 3 || password.length < 4) {
    [self showAlert:@"Username min 3 chars, password min 4 chars"];
    return;
  }

  [self.spinner startAnimating];
  self.signupButton.enabled = NO;

  [[APIClient sharedClient] signupWithUsername:username password:password displayName:displayName success:^(id response) {
    [self.spinner stopAnimating];
    self.signupButton.enabled = YES;
    NSString *token = response[@"token"];
    [[APIClient sharedClient] setToken:token];
    User *user = [[User alloc] initWithDictionary:response[@"user"]];
    [User setCurrentUser:user];
    [self goToMain];
  } failure:^(NSError *error) {
    [self.spinner stopAnimating];
    self.signupButton.enabled = YES;
    [self showAlert:error.localizedDescription];
  }];
}

- (void)goToMain {
  AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
  [delegate showMain];
}

- (void)showAlert:(NSString *)msg {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:msg preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)keyboardWillShow:(NSNotification *)n {
  CGRect kb = [n.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
  NSTimeInterval dur = [n.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
  CGFloat overlap = CGRectGetMaxY(self.signupButton.frame) - kb.origin.y;
  if (overlap > 0) {
    [UIView animateWithDuration:dur animations:^{
      self.view.transform = CGAffineTransformMakeTranslation(0, -overlap - 20);
    }];
  }
}

- (void)keyboardWillHide:(NSNotification *)n {
  NSTimeInterval dur = [n.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
  [UIView animateWithDuration:dur animations:^{
    self.view.transform = CGAffineTransformIdentity;
  }];
}

@end
