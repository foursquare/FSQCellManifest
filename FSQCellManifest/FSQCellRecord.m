//
//  FSQCellRecord.m
//
//  Copyright (c) 2015 Foursquare. All rights reserved.
//

#import "FSQCellRecord.h"

@implementation FSQCellRecord {
    NSNumber *_allowsHighlighting;
    NSNumber *_allowsSelection;
    NSMutableDictionary *_userInfo;
}

- (instancetype)initWithModel:(id)model 
                    cellClass:(Class)cellClass
                  onConfigure:(FSQCellRecordConfigBlock)onConfigure 
                  onSelection:(FSQCellRecordSelectBlock)onSelection {
    if ((self = [super init])) {
        self.model = model;
        self.cellClass = cellClass;
        self.onSelection = onSelection;
        self.onConfigure = onConfigure;
    }
    return self;
}

- (NSString *)reuseIdentifier {
    if (!_reuseIdentifier && _cellClass) {
        return NSStringFromClass(_cellClass);
    }
    else {
        return _reuseIdentifier;
    }
}

- (void)setAllowsHighlighting:(BOOL)allowsHighlighting {
    _allowsHighlighting = @(allowsHighlighting);
}

- (BOOL)allowsHighlighting {
    if (_allowsHighlighting) {
        return [_allowsHighlighting boolValue];
    }
    else {
        return (self.onSelection != nil);
    }
}

- (BOOL)allowsHighlightingWasSet {
    return (_allowsHighlighting != nil);
}

- (void)setAllowsSelection:(BOOL)allowsSelection {
    _allowsSelection = @(allowsSelection);
}

- (BOOL)allowsSelection {
    if (_allowsSelection) {
        return [_allowsSelection boolValue];
    }
    else {
        return self.allowsHighlighting;
    }
}

- (BOOL)allowsSelectionWasSet {
    return (_allowsSelection != nil);
}

- (BOOL)isEqual:(id)object {
    return [self isEqualToCellRecord:object];
}

- (BOOL)isEqualToCellRecord:(FSQCellRecord *)anotherCellRecord {
    if (self == anotherCellRecord) {
        return YES;
    }
    
    if (![anotherCellRecord isKindOfClass:[self class]]) {
        return NO;
    }
    
    return (([self.model isEqual:anotherCellRecord.model] || (!self.model && !anotherCellRecord.model))
            && (self.cellClass == anotherCellRecord.cellClass || (!self.cellClass && !anotherCellRecord.cellClass))
            && ([self.reuseIdentifier isEqualToString:anotherCellRecord.reuseIdentifier] || (!self.reuseIdentifier && !anotherCellRecord.reuseIdentifier))
            && (!!self.onConfigure == !!anotherCellRecord.onConfigure)
            && (!!self.onSelection == !!anotherCellRecord.onSelection)
            && ([_userInfo isEqualToDictionary:anotherCellRecord->_userInfo] || (!_userInfo && !anotherCellRecord->_userInfo))
            && (self.allowsHighlighting == anotherCellRecord.allowsHighlighting)
            && (self.allowsSelection == anotherCellRecord.allowsHighlighting)
            );
}

- (NSMutableDictionary *)userInfo {
    if (!_userInfo) {
        _userInfo = [NSMutableDictionary new];
    }
    
    return _userInfo;
}

@end
