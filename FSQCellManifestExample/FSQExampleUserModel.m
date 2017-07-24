//
//  FSQExampleUserModel.m
//  FSQCellManifestExample
//
//  Created by Brian Dorfman on 2/3/15.
//  Copyright (c) 2015 Foursquare. All rights reserved.
//

#import "FSQExampleUserModel.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FSQExampleUserModel

+ (instancetype)userWithName:(NSString *)name joinDate:(NSDate *)joinDate favoriteColor:(UIColor *)favoriteColor {
    FSQExampleUserModel *user = [[self alloc] init];
    user.name = name;
    user.joinDate = joinDate;
    user.favoriteColor = favoriteColor;
    return user;
}

@end

NS_ASSUME_NONNULL_END
