//
//  FSQExampleUserTableViewCell.m
//  FSQCellManifestExample
//
//  Created by Brian Dorfman on 2/3/15.
//  Copyright (c) 2015 Foursquare. All rights reserved.
//

#import "FSQExampleUserTableViewCell.h"
#import "FSQExampleUserModel.h"

@import FSQCellManifest;

NS_ASSUME_NONNULL_BEGIN

static const CGFloat kLabelHorizontalPadding = 10;
static const CGFloat kLabelVerticalPadding = 5;

@interface FSQExampleUserModel (CellAdditions)
- (NSString *)joinDateString;
@end

@interface NSString (FSQExampleAdditions)
- (CGFloat)heightForWidth:(CGFloat)width font:(UIFont *)font;
@end

@interface FSQExampleUserTableViewCell () <FSQCellManifestTableViewCellProtocol>

@property (nonatomic, retain) UILabel *nameLabel;
@property (nonatomic, retain) UILabel *joinDateLabel;

@end

@implementation FSQExampleUserTableViewCell

+ (UIFont *)mainLabelFont {
    return [UIFont systemFontOfSize:16];
}

+ (UIFont *)secondaryLabelFont {
    return [UIFont italicSystemFontOfSize:14];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.nameLabel.numberOfLines = 0;
        self.nameLabel.font = [[self class] mainLabelFont];
        
        
        self.joinDateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.joinDateLabel.numberOfLines = 0;
        self.joinDateLabel.font = [[self class] secondaryLabelFont];
        
        for (UIView *view in @[self.nameLabel, self.joinDateLabel]) {
            [self.contentView addSubview:view];
        }
    }
    return self;
}

+ (CGFloat)manifest:(FSQCellManifest *)manifest heightForModel:(FSQExampleUserModel *)user maximumSize:(CGSize)maximumSize indexPath:(NSIndexPath *)indexPath record:(FSQCellRecord *)record {
    CGFloat maximumWidth = maximumSize.width - (kLabelHorizontalPadding * 2);
    
    CGFloat cellHeight = 0;
    cellHeight += [user.name heightForWidth:maximumWidth font:[self mainLabelFont]];
    cellHeight += [user.joinDateString heightForWidth:maximumWidth font:[self secondaryLabelFont]];
    cellHeight += (kLabelVerticalPadding * 3); //top and bottom of cell and between labels
    
    return cellHeight;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat maximumWidth = self.contentView.frame.size.width - (kLabelHorizontalPadding * 2);
    
    self.nameLabel.frame = CGRectMake(kLabelHorizontalPadding,
                                      kLabelVerticalPadding,
                                      maximumWidth,
                                      [self.nameLabel.text heightForWidth:maximumWidth font:self.nameLabel.font]);
    
    self.joinDateLabel.frame = CGRectMake(kLabelHorizontalPadding,
                                          CGRectGetMaxY(self.nameLabel.frame) + kLabelVerticalPadding,
                                          maximumWidth,
                                          [self.joinDateLabel.text heightForWidth:maximumWidth font:self.joinDateLabel.font]);
}

- (void)manifest:(FSQCellManifest *)manifest configureWithModel:(FSQExampleUserModel *)user indexPath:(NSIndexPath *)indexPath record:(FSQCellRecord *)record {
    self.nameLabel.text = user.name;
    self.nameLabel.textColor = user.favoriteColor;
    self.joinDateLabel.text = user.joinDateString;
}

@end

@implementation FSQExampleUserModel (CellAdditions)

- (NSString *)joinDateString{
    return [NSString stringWithFormat:@"User since %@", [NSDateFormatter localizedStringFromDate:self.joinDate
                                                                                       dateStyle:NSDateFormatterLongStyle
                                                                                       timeStyle:NSDateFormatterNoStyle]];
}

@end

@implementation NSString (FSQExampleAdditions)

- (CGFloat)heightForWidth:(CGFloat)width font:(UIFont *)font {
    return [self boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                              options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine | NSLineBreakByWordWrapping
                           attributes:@{ NSFontAttributeName : font}
                              context:nil].size.height;
}

@end

NS_ASSUME_NONNULL_END
