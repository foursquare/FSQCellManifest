//
//  FSQSectionRecord.m
//
//  Copyright (c) 2015 Foursquare. All rights reserved.
//

#import "FSQSectionRecord.h"

#import "FSQCellRecord.h"

@implementation FSQSectionRecord {
    NSArray *_cellRecords;
    NSValue *_collectionViewSectionInsetPrivate;
    NSMutableDictionary *_userInfo;
}

- (instancetype)initWithCellRecords:(NSArray *)cellRecords 
                             header:(FSQCellRecord *)header 
                             footer:(FSQCellRecord *)footer {
    if ((self = [super init])) {
        _cellRecords = [cellRecords copy];
        self.header = header;
        self.footer = footer;
    }
    return self;
}

- (NSInteger)numberOfCellRecords {
    return [_cellRecords count];
}

- (FSQCellRecord *)cellRecordAtIndex:(NSInteger)index {
    if (index < [_cellRecords count]
        && index >= 0) {
        return _cellRecords[index];
    }
    else {
        return nil;
    }
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len {
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

- (NSMutableDictionary *)userInfo {
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

- (NSArray *)cellRecords {
    if (_cellRecords) {
        return _cellRecords;
    }
    else {
        return  @[];
    }
}

// Exposed for internal use of other FSQCellManifest files only
- (NSValue *)collectionViewSectionInsetPrivate {
    return _collectionViewSectionInsetPrivate;
}

@end