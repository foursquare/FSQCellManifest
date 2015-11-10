//
//  FSQExampleManifestTableViewController.m
//  FSQCellManifestExample
//
//  Created by Brian Dorfman on 2/3/15.
//  Copyright (c) 2015 Foursquare. All rights reserved.
//

#import "FSQExampleManifestTableViewController.h"
#import "FSQExampleUserModel.h"
#import "FSQExampleUserTableViewCell.h"

@import FSQCellManifest;

// Note: In a real app, use NSCalendar instead of macros like these :)
#define TIME_INTERVAL_ONE_MINUTE ((NSTimeInterval) 60)
#define TIME_INTERVAL_ONE_HOUR   ((NSTimeInterval) (TIME_INTERVAL_ONE_MINUTE * 60))
#define TIME_INTERVAL_ONE_DAY    ((NSTimeInterval) (TIME_INTERVAL_ONE_HOUR * 24))

#define TIME_INTERVAL_SECONDS(n) ((NSTimeInterval) (n))
#define TIME_INTERVAL_MINUTES(n) ((NSTimeInterval) (TIME_INTERVAL_ONE_MINUTE * n))
#define TIME_INTERVAL_HOURS(n)   ((NSTimeInterval) (TIME_INTERVAL_ONE_HOUR * n))
#define TIME_INTERVAL_DAYS(n)    ((NSTimeInterval) (TIME_INTERVAL_ONE_DAY * n))

@interface FSQExampleHeaderView : UITableViewHeaderFooterView <FSQCellManifestTableViewCellProtocol>
@end

@interface FSQExampleManifestTableViewController () <UITableViewDelegate>
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) FSQTableViewCellManifest *manifest;

@property (nonatomic, copy) NSArray *userModels;
@end

@implementation FSQExampleManifestTableViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Example User List";
    
    // Create our table view and manifest
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    self.manifest = [[FSQTableViewCellManifest alloc] initWithDelegate:self plugins:nil tableView:self.tableView];
    
    // Create some example data and then use them to populate the table
    [self createExampleModels];
    [self createAndSetSectionRecords];
}

- (void)createExampleModels {

    // Generate some random user models to show in our table
    
    NSArray *possibleFavoriteColors = @[
                                        [UIColor redColor], 
                                        [UIColor greenColor], 
                                        [UIColor blueColor],
                                        [UIColor cyanColor], 
                                        [UIColor magentaColor],
                                        [UIColor orangeColor],
                                        [UIColor purpleColor],
                                        ];
    
    // The best part of writing an example app is obviously getting to add in semi-obscure references
    NSArray *exampleUserNames = @[
                                  @"George Orr",
                                  @"Genly Ai",
                                  @"Philadelphia Burke",
                                  @"Lory Kaye",
                                  @"Bron Helstrom",
                                  @"Rydra Wong",
                                  @"Carl Corey",
                                  @"Susan Calvin",
                                  @"Cordelia Naismith",
                                  @"Della Lu",
                                  @"Brawne Lamia",
                                  @"Spider Jerusalem",
                                  @"Myfanwy Thomas",
                                  @"Anaander Mianaai",
                                  @"Billy VeryExtendedMiddlename McLonglastname" // to show off word wrapping
                                  ];
    
    
    NSMutableArray *exampleUserModels = [NSMutableArray new];
    
    
    for (NSString *userName in exampleUserNames) {
        [exampleUserModels addObject:[FSQExampleUserModel userWithName:userName 
                                                              joinDate:[NSDate dateWithTimeIntervalSinceNow:-TIME_INTERVAL_DAYS(arc4random_uniform(3000))] 
                                                         favoriteColor:possibleFavoriteColors[arc4random_uniform((u_int32_t)possibleFavoriteColors.count)]
                                      ]];
    }

    self.userModels = exampleUserModels;
}

- (void)createAndSetSectionRecords {
    
    NSMutableArray *cellRecords = [NSMutableArray new];
    for (FSQExampleUserModel *user in self.userModels) {
        [cellRecords addObject:[[FSQCellRecord alloc] initWithModel:user cellClass:[FSQExampleUserTableViewCell class] onConfigure:nil onSelection:nil]];
    }
    
    FSQCellRecord *headerRecord = [[FSQCellRecord alloc] initWithModel:@"Current Users" 
                                                             cellClass:[FSQExampleHeaderView class] 
                                                           onConfigure:nil
                                                           onSelection:nil];
    
    [self.manifest setSectionRecords:@[
                                       [[FSQSectionRecord alloc] initWithCellRecords:cellRecords 
                                                                              header:headerRecord 
                                                                              footer:nil]
                                       ]];
}

@end

@implementation FSQExampleHeaderView

+ (CGFloat)manifest:(FSQTableViewCellManifest *)manifest heightForModel:(NSString *)string maximumSize:(CGSize)maximumSize indexPath:(NSIndexPath *)indexPath record:(FSQCellRecord *)record {
    return 32;
}

- (void)manifest:(FSQCellManifest *)manifest configureWithModel:(NSString *)string indexPath:(NSIndexPath *)indexPath record:(FSQCellRecord *)record {
    self.textLabel.text = string;
}

@end
