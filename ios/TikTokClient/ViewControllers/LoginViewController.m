#import "LoginViewController.h"
#import "SignupViewController.h"
#import "APIClient.h"
#import "User.h"
#import "AppDelegate.h"

@interface LoginViewController ()

@property (nonatomic, strong) UITextField *usernameField;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIButton *signupButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end

@implementation LoginViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor blackColor];
  [self setupUI];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupUI {
  self.titleLabel = [[UILabel alloc] init];
  self.titleLabel.text = @"TikTok";
  self.titleLabel.textColor = [UIColor whiteColor];
  self.titleLabel.font = [UIFont systemFontOfSize:36 weight:UIFontWeightBold];
  self.titleLabel.textAlignment = NSTextAlignmentCenter;
  self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.titleLabel];

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

  self.loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.loginButton setTitle:@"Log In" forState:UIControlStateNormal];
  [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  self.loginButton.backgroundColor = [UIColor colorWithRed:1 green:0.22 blue:0.42 alpha:1];
  self.loginButton.layer.cornerRadius = 8;
  self.loginButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
  self.loginButton.translatesAutoresizingMaskIntoConstraints = NO;
  [self.loginButton addTarget:self action:@selector(loginTapped) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.loginButton];

  self.signupButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.signupButton setTitle:@"Don't have an account? Sign up" forState:UIControlStateNormal];
  [self.signupButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
  self.signupButton.translatesAutoresizingMaskIntoConstraints = NO;
  [self.signupButton addTarget:self action:@selector(signupTapped) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.signupButton];

  self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
  self.spinner.translatesAutoresizingMaskIntoConstraints = NO;
  self.spinner.hidesWhenStopped = YES;
  [self.view addSubview:self.spinner];

  NSDictionary *views = @{
    @"title": self.titleLabel,
    @"user": self.usernameField,
    @"pass": self.passwordField,
    @"login": self.loginButton,
    @"signup": self.signupButton
  };

  for (UIView *v in [views allValues]) {
    v.translatesAutoresizingMaskIntoConstraints = NO;
  }

  [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
  [self.titleLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:120].active = YES;

  [self.usernameField.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
  [self.usernameField.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:50].active = YES;
  [self.usernameField.widthAnchor constraintEqualToConstant:300].active = YES;
  [self.usernameField.heightAnchor constraintEqualToConstant:48].active = YES;

  [self.passwordField.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
  [self.passwordField.topAnchor constraintEqualToAnchor:self.usernameField.bottomAnchor constant:14].active = YES;
  [self.passwordField.widthAnchor constraintEqualToConstant:300].active = YES;
  [self.passwordField.heightAnchor constraintEqualToConstant:48].active = YES;

  [self.loginButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
  [self.loginButton.topAnchor constraintEqualToAnchor:self.passwordField.bottomAnchor constant:24].active = YES;
  [self.loginButton.widthAnchor constraintEqualToConstant:300].active = YES;
  [self.loginButton.heightAnchor constraintEqualToConstant:50].active = YES;

  [self.signupButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
  [self.signupButton.topAnchor constraintEqualToAnchor:self.loginButton.bottomAnchor constant:16].active = YES;

  [self.spinner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
  [self.spinner.topAnchor constraintEqualToAnchor:self.signupButton.bottomAnchor constant:20].active = YES;
}

- (void)loginTapped {
  [self.view endEditing:YES];
  NSString *username = self.usernameField.text;
  NSString *password = self.passwordField.text;
  if (username.length < 3 || password.length < 4) {
    [self showAlert:@"Username min 3 chars, password min 4 chars"];
    return;
  }

  [self.spinner startAnimating];
  self.loginButton.enabled = NO;

  [[APIClient sharedClient] loginWithUsername:username password:password success:^(id response) {
    [self.spinner stopAnimating];
    self.loginButton.enabled = YES;
    NSString *token = response[@"token"];
    [[APIClient sharedClient] setToken:token];
    User *user = [[User alloc] initWithDictionary:response[@"user"]];
    [User setCurrentUser:user];
    [self goToMain];
  } failure:^(NSError *error) {
    [self.spinner stopAnimating];
    self.loginButton.enabled = YES;
    [self showAlert:error.localizedDescription];
  }];
}

- (void)signupTapped {
  SignupViewController *vc = [[SignupViewController alloc] init];
  [self.navigationController pushViewController:vc animated:YES];
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
  CGFloat overlap = CGRectGetMaxY(self.loginButton.frame) - kb.origin.y;
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
