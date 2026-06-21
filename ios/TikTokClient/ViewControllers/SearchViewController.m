#import "SearchViewController.h"
#import "APIClient.h"
#import "User.h"
#import "ProfileViewController.h"

@interface SearchViewController () <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<User *> *results;
@property (nonatomic, strong) UILabel *placeholderLabel;

@end

@implementation SearchViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor blackColor];
  self.title = @"Search";
  self.results = [NSMutableArray array];
  [self setupUI];
}

- (void)setupUI {
  self.searchBar = [[UISearchBar alloc] init];
  self.searchBar.delegate = self;
  self.searchBar.placeholder = @"Search users...";
  self.searchBar.barStyle = UIBarStyleBlack;
  self.searchBar.tintColor = [UIColor whiteColor];
  self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
  self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.searchBar];

  self.tableView = [[UITableView alloc] init];
  self.tableView.backgroundColor = [UIColor blackColor];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.separatorColor = [UIColor colorWithWhite:0.2 alpha:1];
  self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UserCell"];
  [self.view addSubview:self.tableView];

  self.placeholderLabel = [[UILabel alloc] init];
  self.placeholderLabel.text = @"Search for other users";
  self.placeholderLabel.textColor = [UIColor grayColor];
  self.placeholderLabel.font = [UIFont systemFontOfSize:16];
  self.placeholderLabel.textAlignment = NSTextAlignmentCenter;
  self.placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.placeholderLabel];

  [self.searchBar.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:64].active = YES;
  [self.searchBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
  [self.searchBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;

  [self.tableView.topAnchor constraintEqualToAnchor:self.searchBar.bottomAnchor constant:8].active = YES;
  [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
  [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
  [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;

  [self.placeholderLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
  [self.placeholderLabel.topAnchor constraintEqualToAnchor:self.searchBar.bottomAnchor constant:60].active = YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
  [searchBar resignFirstResponder];
  NSString *query = searchBar.text;
  if (query.length == 0) return;

  self.placeholderLabel.hidden = YES;
  [self.results removeAllObjects];
  [self.tableView reloadData];

  [[APIClient sharedClient] searchUsers:query success:^(id response) {
    if ([response isKindOfClass:[NSArray class]]) {
      [self.results removeAllObjects];
      for (NSDictionary *dict in response) {
        User *u = [[User alloc] initWithDictionary:dict];
        [self.results addObject:u];
      }
      [self.tableView reloadData];
      if (self.results.count == 0) {
        self.placeholderLabel.text = @"No users found";
        self.placeholderLabel.hidden = NO;
      }
    }
  } failure:^(NSError *error) {
    self.placeholderLabel.text = @"Search failed";
    self.placeholderLabel.hidden = NO;
  }];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
  if (searchText.length == 0) {
    [self.results removeAllObjects];
    [self.tableView reloadData];
    self.placeholderLabel.text = @"Search for other users";
    self.placeholderLabel.hidden = NO;
  }
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell" forIndexPath:indexPath];
  User *u = self.results[indexPath.row];
  cell.backgroundColor = [UIColor clearColor];
  cell.textLabel.textColor = [UIColor whiteColor];
  cell.textLabel.text = [NSString stringWithFormat:@"@%@ - %@", u.username, u.displayName];
  cell.detailTextLabel.textColor = [UIColor grayColor];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  User *u = self.results[indexPath.row];
  ProfileViewController *vc = [[ProfileViewController alloc] init];
  vc.userId = u.userId;
  [self.navigationController pushViewController:vc animated:YES];
}

@end
