//
//  FSQSectionRecord.m
//
//  Copyright (c) 2015 Foursquare. All rights reserved.
//

#import "FSQSectionRecord.h"

#import "FSQCellRecord.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FSQSectionRecord {
    NSArray<FSQCellRecord *> *_cellRecords;
    NSValue *_Nullable _collectionViewSectionInsetPrivate;
    NSMutableDictionary<NSString *, id> *_Nullable _userInfo;
}

- (instancetype)initWithCellRecords:(nullable NSArray<FSQCellRecord *> *)cellRecords
                             header:(nullable FSQCellRecord *)header
                             footer:(nullable FSQCellRecord *)footer {
    if ((self = [super init])) {
        _cellRecords = [cellRecords copy] ?: @[];
        self.header = header;
        self.footer = footer;
    }
    return self;
}

- (NSInteger)numberOfCellRecords {
    return [_cellRecords count];
}

- (nullable FSQCellRecord *)cellRecordAtIndex:(NSInteger)index {
    if (index < [_cellRecords count]
        && index >= 0) {
        return _cellRecords[index];
    }
    else {
        return nil;
    }
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id _Nonnull __unsafe_unretained [])buffer count:(NSUInteger)len {
    return [_cellRecords countByEnumeratingWithState:state objects:buffer count:len];
}

- (void)setCollectionViewSectionInset:(UIEdgeInsets)collectionViewSectionInset {
    _collectionViewSectionInsetPrivate = [NSValue valueWithUIEdgeInsets:collectionViewSectionInset];
}

- (UIEdgeInsets)collectionViewSectionInset {
    if (_collectionViewSectionInsetPrivate) {
        return [_collectionViewSectionInsetPrivate UIEdgeInsetsValue];
    }
    else {
        return UIEdgeInsetsZero;
    }
}

- (NSMutableDictionary<NSString *, id> *)userInfo {
    if (!_userInfo) {
        _userInfo = [NSMutableDictionary new];
    }
    
    return _userInfo;
}


- (BOOL)isEqual:(id)object {
    return [self isEqualToSectionRecord:object];
}

- (BOOL)isEqualToSectionRecord:(FSQSectionRecord *)anotherSectionRecord {
    if (self == anotherSectionRecord) {
        return YES;
    }
    
    if (![anotherSectionRecord isKindOfClass:[self class]]) {
        return NO;
    }
    
    return (
            ([_cellRecords isEqualToArray:anotherSectionRecord->_cellRecords] || (!_cellRecords && !anotherSectionRecord->_cellRecords))
            && ([self.header isEqualToCellRecord:anotherSectionRecord.header] || (!self.header && !anotherSectionRecord.header))
            && ([self.footer isEqualToCellRecord:anotherSectionRecord.footer] || (!self.footer && !anotherSectionRecord.footer))
            && ([_collectionViewSectionInsetPrivate isEqualToValue:anotherSectionRecord->_collectionViewSectionInsetPrivate] || (!_collectionViewSectionInsetPrivate && !anotherSectionRecord->_collectionViewSectionInsetPrivate))
            && ([_userInfo isEqualToDictionary:anotherSectionRecord->_userInfo] || (!_userInfo && !anotherSectionRecord->_userInfo))
            );
}

- (NSArray<FSQCellRecord *> *)cellRecords {
    if (_cellRecords) {
        return _cellRecords;
    }
    else {
        return @[];
    }
}

// Exposed for internal use of other FSQCellManifest files only
- (nullable NSValue *)collectionViewSectionInsetPrivate {
    return _collectionViewSectionInsetPrivate;
}

@end

NS_ASSUME_NONNULL_END
