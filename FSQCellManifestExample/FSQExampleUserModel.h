//
//  FSQExampleUserModel.h
//  FSQCellManifestExample
//
//  Created by Brian Dorfman on 2/3/15.
//  Copyright (c) 2015 Foursquare. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface FSQExampleUserModel : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSDate   *joinDate;
@property (nonatomic, copy) UIColor  *favoriteColor;

+ (instancetype)userWithName:(NSString *)name joinDate:(NSDate *)joinDate favoriteColor:(UIColor *)favoriteColor;

@end

NS_ASSUME_NONNULL_END
