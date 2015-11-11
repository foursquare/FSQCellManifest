//
//  FSQCellManifest.m
//
//  Copyright (c) 2015 Foursquare. All rights reserved.
//

#import "FSQCellManifest.h"

@import FSQMessageForwarder;

#pragma mark - Begin Private Headers, Types, and Constants

const NSInteger kRowIndexForHeaderIndexPaths = -1;
const NSInteger kRowIndexForFooterIndexPaths = -2;

static NSString *const kFSQIdentifierClassMismatchException = @"FSQIdentifierClassMismatchException";
static NSString *const kFSQIdentifierCellDequeueException = @"FSQIdentifierCellDequeueException";

typedef NS_ENUM(NSInteger, FSQIdentifierRegistrationResult) {
    FSQIdentifierRegistrationResultAdded,
    FSQIdentifierRegistrationResultAlreadyExists,
    FSQIdentifierRegistrationResultConflictingExistingType
};

typedef NS_ENUM(NSInteger, FSQCellRecordType) {
    FSQCellRecordTypeBody,
    FSQCellRecordTypeHeader,
    FSQCellRecordTypeFooter
};

@interface FSQMessageForwarder (FSQManifestAdditions) <UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@end

@interface FSQCellManifestMessageForwarderEnumerator : NSEnumerator <FSQMessageForwarderEnumeratorGenerator>
@property (nonatomic, readonly) FSQMessageForwarderWithEnumerator *messageForwarder;
@property (nonatomic, weak) FSQCellManifest *manifest;
@property (nonatomic, weak) id manifestDelegate;
@property (nonatomic, readonly) NSUInteger currentIndex;
- (void)addPlugins:(NSArray *)newPlugins;
- (void)removePlugins:(NSArray *)pluginsToRemove;
@end

// These methods all already exist in FSQSectionRecord.m but are not exposed.
// Define them here so that FSQCellManfiest can know about them.
// They are for internal manifest use only and should not be used outside of the framework
@interface FSQSectionRecord (FSQCellManifestPrivateMethods)
- (NSValue *)collectionViewSectionInsetPrivate;
@end

@interface FSQCellRecord (FSQCellManifestPrivateMethods)
- (BOOL)allowsHighlightingWasSet;
- (BOOL)allowsSelectionWasSet;
@end

#pragma mark End Private Headers, Types, and Constants -

#pragma mark - Begin Core Manifest

@implementation FSQCellManifest {
    NSMutableDictionary *_identifierCellClassMap;
    FSQCellManifestMessageForwarderEnumerator *_scrollViewDelegateForwarderEnumerator;
}

- (instancetype)initWithDelegate:(id)delegate 
                         plugins:(NSArray *)plugins {
    if ((self = [super init])) {
        _sectionRecords = @[];
        _identifierCellClassMap = [NSMutableDictionary new];
        _automaticallyUpdateManagedView = YES;
        [self createForwarders];
        [self addPlugins:plugins];
        self.delegate = delegate;
    }
    return self;
}

- (NSArray *)messageForwarderEnumerators NS_REQUIRES_SUPER {
    return @[_scrollViewDelegateForwarderEnumerator];
}

- (void)createForwarders NS_REQUIRES_SUPER {
    _scrollViewDelegateForwarderEnumerator = [FSQCellManifestMessageForwarderEnumerator new];
    _scrollViewDelegateForwarderEnumerator.manifest = self;
}

- (void)addPluginsToForwarders:(NSArray *)plugins {    
    for (FSQCellManifestMessageForwarderEnumerator *enumerator in [self messageForwarderEnumerators]) {
        [enumerator addPlugins:plugins];
    }
}

- (void)removePluginsFromForwarders:(NSArray *)plugins {
    for (FSQCellManifestMessageForwarderEnumerator *enumerator in [self messageForwarderEnumerators]) {
        [enumerator removePlugins:plugins];
    }
}

- (void)addPlugins:(NSArray *)plugins {
    if (!_plugins) {
        _plugins = plugins;
    }
    else {
        _plugins = [_plugins arrayByAddingObjectsFromArray:plugins];
    }
    
    for (id<FSQCellManifestPlugin> plugin in plugins) {
        if ([plugin respondsToSelector:@selector(wasAttachedToManifest:)]) {
            [plugin wasAttachedToManifest:self];
        }
    }
    
    // After self, before any delegates
    [self addPluginsToForwarders:plugins];
}

- (void)removePlugins:(NSArray *)plugins {
    NSMutableArray *mutablePlugins = [_plugins mutableCopy];
    [mutablePlugins removeObjectsInArray:plugins];
    _plugins = [mutablePlugins copy];
    
    for (id<FSQCellManifestPlugin> plugin in plugins) {
        if ([plugin respondsToSelector:@selector(wasRemovedFromManifest:)]) {
            [plugin wasRemovedFromManifest:self];
        }
    }
    
    [self removePluginsFromForwarders:plugins];
}

- (void)setManagedView:(UIScrollView *)managedView {
    UIScrollView *oldView = _managedView;
    _managedView = managedView;
    oldView.delegate = nil;
    managedView.delegate = _scrollViewDelegateForwarderEnumerator.messageForwarder;
    
    [self withEachPlugin:^(id<FSQCellManifestPlugin> plugin) {
        if ([plugin respondsToSelector:@selector(manifest:managedViewDidChange:oldView:)]) {
            [plugin manifest:self managedViewDidChange:managedView oldView:oldView];
        }
    }];
}

- (void)setDelegate:(id)delegate {
    if (_delegate == delegate) {
        return;
    }
    _delegate = delegate;
    
    for (FSQCellManifestMessageForwarderEnumerator *enumerator in [self messageForwarderEnumerators]) {
        enumerator.manifestDelegate = delegate;
    }
}

- (void)withEachPluginAndDelegate:(void (^)(id delegate))block {
    NSAssert(block, @"Missing block in withEachPluginAndDelegate:");
    
    for (id delegate in self.plugins) {
        block(delegate);
    }
    
    block(self.delegate);
}

- (void)withEachPlugin:(void (^)(id<FSQCellManifestPlugin> plugin))block {
    NSAssert(block, @"Missing block in withEachPlugin:");
    
    for (id<FSQCellManifestPlugin> plugin in self.plugins) {
        block(plugin);
    }
}

- (void)performBatchRecordModificationUpdates:(void (^)(void))updates {
    // Subclasses should override
    if (updates) {
        updates();
    }
}

- (void)performRecordModificationUpdatesWithoutUpdatingManagedView:(void (^)(void))updates {
    if (updates) {
        if (self.automaticallyUpdateManagedView) {
            self.automaticallyUpdateManagedView = NO;
            updates();
            self.automaticallyUpdateManagedView = YES;
        }
        else {
            updates();
        }
    }
}

- (FSQSectionRecord *)sectionRecordAtIndex:(NSInteger)index {
    if (index < [_sectionRecords count]
        && index >= 0) {
        return _sectionRecords[index];
    }
    else {
        return nil;
    }
}

- (FSQCellRecord *)cellRecordAtIndexPath:(NSIndexPath *)indexPath {
    return [[self sectionRecordAtIndex:indexPath.section] cellRecordAtIndex:[self rowOrItemIndexForIndexPath:indexPath]];
}

- (NSInteger)numberOfSectionRecords {
    return [_sectionRecords count];
}

- (NSInteger)numberOfCellRecordsInSectionAtIndex:(NSInteger)index {
    return [[self sectionRecordAtIndex:index] numberOfCellRecords];
}

- (NSInteger)rowOrItemIndexForIndexPath:(NSIndexPath *)indexPath {
    // Subclasses override
    NSAssert(0, @"rowOrItemIndexForIndexPath: should be overriden by subclass");
    return 0;
}

- (NSIndexPath *)indexPathForRowOrItem:(NSInteger)rowOrItem inSection:(NSInteger)section {
    // Subclasses override
    NSAssert(0, @"indexPathForRowOrItem:inSection: should be overriden by subclass");
    return nil;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len {
    return [_sectionRecords countByEnumeratingWithState:state objects:buffer count:len];
}


- (CGSize)maxSizeForRecord:(FSQCellRecord *)record atIndexPath:(NSIndexPath *)indexPath defaultWidth:(CGFloat)defaultWidth defaultHeight:(CGFloat)defaultHeight {
    if (indexPath // nil means its a header or footer
        && [self.delegate respondsToSelector:@selector(maximumSizeForCellAtIndexPath:withManifest:record:)]) {
        return [self.delegate maximumSizeForCellAtIndexPath:indexPath withManifest:self record:record];
    }
    else {
        if ([self.delegate respondsToSelector:@selector(defaultMaximumCellSizeForManifest:)]) {
            CGSize defaultSize = [self.delegate defaultMaximumCellSizeForManifest:self];
            defaultWidth = defaultSize.width;
            defaultHeight = defaultSize.height;
        }
        return CGSizeMake(defaultWidth, defaultHeight);
    }
}

#pragma mark - Insertion and Removal

// The managedViewUpdates versions should not be directly overridden.
// Subclasses should override public methods, then call through to these with managedViewUpdates set to
// do any additional work they need to support their use case (ie table or collection updating)

- (void)replaceSectionRecords:(NSArray *)sectionRecords 
            selectionStrategy:(FSQViewReloadCellSelectionStrategy)selectionStrategy 
           managedViewUpdates:(void(^)(NSArray *originalRecords))managedViewUpdates {
    
    NSArray *originalRecords = _sectionRecords;
    
    /**  Inform delegates  **/
    
    [self withEachPluginAndDelegate:^(id delegate) {
        if ([delegate respondsToSelector:@selector(manifest:willReplaceSectionRecords:withRecords:)]) {
            [delegate manifest:self willReplaceSectionRecords:originalRecords withRecords:sectionRecords];
        }
    }];
    
    /**  Do work  **/
    
    if (!sectionRecords) {
        _sectionRecords = @[];
    }
    else {
        _sectionRecords = [sectionRecords copy];
    }
    
    if (managedViewUpdates && _automaticallyUpdateManagedView) {
        managedViewUpdates(originalRecords);
    }
    
    /**  Inform delegates  **/
    
    [self withEachPluginAndDelegate:^(id delegate) {
        if ([delegate respondsToSelector:@selector(manifest:didReplaceSectionRecords:withRecords:)]) {
            [delegate manifest:self didReplaceSectionRecords:originalRecords withRecords:sectionRecords];
        }
    }];
}

- (void)setSectionRecords:(NSArray *)sectionRecords selectionStrategy:(FSQViewReloadCellSelectionStrategy)selectionStrategy { 
    [self replaceSectionRecords:sectionRecords selectionStrategy:selectionStrategy managedViewUpdates:nil];
}

- (void)setSectionRecords:(NSArray *)sectionRecords { 
    [self setSectionRecords:sectionRecords selectionStrategy:FSQViewReloadCellSelectionStrategyDeselectAll];
}

- (NSArray *)insertCellRecords:(NSArray *)cellRecordsToInsert 
                   atIndexPath:(NSIndexPath *)indexPath 
            managedViewUpdates:(void(^)(NSArray *insertedIndexPaths))managedViewUpdates {
    
    /**  Check parameters  **/
    
    if ([cellRecordsToInsert count] <= 0) {
        return nil;
    }
    
    FSQSectionRecord *sectionRecord = [self sectionRecordAtIndex:indexPath.section];
    if (!sectionRecord) {
        return nil;
    }
    
    NSInteger row = [self rowOrItemIndexForIndexPath:indexPath];
    NSInteger numberOfCellRecords = [sectionRecord numberOfCellRecords];
    
    if (row > numberOfCellRecords || row < 0) {
        return nil;
    }
    
    /**  Inform delegates  **/
    
    [self withEachPluginAndDelegate:^(id delegate) {
        if ([delegate respondsToSelector:@selector(manifest:willInsertCellRecords:atIndexPath:)]) {
            [delegate manifest:self willInsertCellRecords:cellRecordsToInsert atIndexPath:indexPath];
        }
    }];
    
    /**  Do work  **/
    
    NSIndexSet *insertedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row, [cellRecordsToInsert count])];
    NSMutableArray *updatedCellRecords = [sectionRecord.cellRecords mutableCopy];
    [updatedCellRecords insertObjects:cellRecordsToInsert atIndexes:insertedIndexes];
    [sectionRecord setCellRecords:updatedCellRecords];
    NSMutableArray *insertedIndexPathsMutable = [NSMutableArray new];
    [insertedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [insertedIndexPathsMutable addObject:[self indexPathForRowOrItem:idx inSection:indexPath.section]];
    }];
    
    NSArray *insertedIndexPaths = [insertedIndexPathsMutable copy];
    
    if (managedViewUpdates && _automaticallyUpdateManagedView) {
        managedViewUpdates(insertedIndexPaths);
    }
    
    /**  Inform delegates  **/
    
    [self withEachPluginAndDelegate:^(id delegate) {
        if ([delegate respondsToSelector:@selector(manifest:didInsertCellRecords:atIndexPaths:)]) {
            [delegate manifest:self didInsertCellRecords:cellRecordsToInsert atIndexPaths:insertedIndexPaths];
        }
    }];
    
    return insertedIndexPaths;
    
}

- (NSArray *)insertCellRecords:(NSArray *)cellRecordsToInsert 
                   atIndexPath:(NSIndexPath *)indexPath {
    return [self insertCellRecords:cellRecordsToInsert atIndexPath:indexPath managedViewUpdates:nil];
}

- (NSIndexSet *)insertSectionRecords:(NSArray *)sectionRecordsToInsert 
                             atIndex:(NSInteger)index 
                  managedViewUpdates:(void(^)(NSIndexSet *insertedIndexes))managedViewUpdates {
    
    /**  Check parameters  **/
    
    NSInteger numberOfSectionRecords = [self numberOfSectionRecords];
    if ([sectionRecordsToInsert count] <= 0 || index > numberOfSectionRecords || index < 0) {
        return nil;
    }
    
    /**  Inform delegates  **/
    
    [self withEachPluginAndDelegate:^(id delegate) {
        if ([delegate respondsToSelector:@selector(manifest:willInsertSectionRecords:atIndex:)]) {
            [delegate manifest:self willInsertSectionRecords:sectionRecordsToInsert atIndex:index];
        }
    }];
    
    /**  Do work  **/
    
    NSIndexSet *insertedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, [sectionRecordsToInsert count])];
    
    NSMutableArray *updatedSectionRecords = [_sectionRecords mutableCopy];
    [updatedSectionRecords insertObjects:sectionRecordsToInsert atIndexes:insertedIndexes];
    
    // Don't use setSectionRecords as that will trigger a view reload and all sorts of delegate callbacks
    _sectionRecords = [updatedSectionRecords copy];
    
    if (managedViewUpdates && _automaticallyUpdateManagedView) {
        managedViewUpdates(insertedIndexes);
    }
    
    /**  Inform delegates  **/
    
    [self withEachPluginAndDelegate:^(id delegate) {
        if ([delegate respondsToSelector:@selector(manifest:didInsertSectionRecords:atIndexes:)]) {
            [delegate manifest:self didInsertSectionRecords:sectionRecordsToInsert atIndexes:insertedIndexes];
        }
    }];
    
    return insertedIndexes;
}

- (NSIndexSet *)insertSectionRecords:(NSArray *)sectionRecordsToInsert atIndex:(NSInteger)index {
    return [self insertSectionRecords:sectionRecordsToInsert atIndex:index managedViewUpdates:nil];
}

- (BOOL)moveCellRecordAtIndexPath:(NSIndexPath *)initialIndexPath 
                      toIndexPath:(NSIndexPath *)targetIndexPath 
               managedViewUpdates:(void(^)())managedViewUpdates {
    
    /**  Check parameters  **/
    
    if (initialIndexPath.section >= [self numberOfSectionRecords]
        || targetIndexPath.section >= [self numberOfSectionRecords]
        || initialIndexPath.section < 0
        || targetIndexPath.section < 0
        ) {
        return NO;
    }
    
    FSQSectionRecord *initialSectionRecord = [self sectionRecordAtIndex:initialIndexPath.section];
    FSQSectionRecord *targetSectionRecord;
    NSInteger intitialCellIndex = [self rowOrItemIndexForIndexPath:initialIndexPath];
    NSInteger targetCellIndex = [self rowOrItemIndexForIndexPath:targetIndexPath];
    NSInteger numberofTargetSectionRecordsAfterRemoval;
    
    if (initialIndexPath.section == targetIndexPath.section) {
        targetSectionRecord = initialSectionRecord;
        numberofTargetSectionRecordsAfterRemoval = [targetSectionRecord numberOfCellRecords] - 1;
    }
    else {
        targetSectionRecord = [self sectionRecordAtIndex:initialIndexPath.section];        
        numberofTargetSectionRecordsAfterRemoval = [targetSectionRecord numberOfCellRecords];
    }
    
    if (!(intitialCellIndex < [initialSectionRecord numberOfCellRecords]) 
        || targetCellIndex > numberofTargetSectionRecordsAfterRemoval) {
        return NO;
    }
    
    /**  Inform delegates  **/
    
    [self withEachPluginAndDelegate:^(id delegate) {
        if ([delegate respondsToSelector:@selector(manifest:willMoveCellRecordAtIndexPath:toIndexPath:)]) {
            [delegate manifest:self willMoveCellRecordAtIndexPath:initialIndexPath toIndexPath:targetIndexPath];
        }
    }];
    
    /**  Do work  **/
    
    NSMutableArray *mutableInitialRecords = [initialSectionRecord.cellRecords mutableCopy];
    NSMutableArray *mutableTargetRecords;
    if (initialSectionRecord == targetSectionRecord) {
        mutableTargetRecords = mutableInitialRecords;
    }
    else {
        mutableTargetRecords = [targetSectionRecord.cellRecords mutableCopy];
    }
    
    FSQCellRecord *record = mutableInitialRecords[intitialCellIndex];
    [mutableInitialRecords removeObjectAtIndex:intitialCellIndex];
    
    // Record will always exist because we check numberOfCellRecords above and return NO if there are not enough.
    // But if you do not include this check, the Xcode analyzer warns about possible nil insertion.
    if (record) {
        [mutableTargetRecords insertObject:record atIndex:targetCellIndex];
    }
    
    [initialSectionRecord setCellRecords:mutableInitialRecords];
    
    if (initialSectionRecord != targetSectionRecord) {
        [targetSectionRecord setCellRecords:mutableTargetRecords];
    }
    
    if (managedViewUpdates && _automaticallyUpdateManagedView) {
        managedViewUpdates();
    }
    
    /**  Inform delegates  **/
    
    [self withEachPluginAndDelegate:^(id delegate) {
        if ([delegate respondsToSelector:@selector(manifest:didMoveCellRecordAtIndexPath:toIndexPath:)]) {
            [delegate manifest:self didMoveCellRecordAtIndexPath:initialIndexPath toIndexPath:targetIndexPath];
        }
    }];
    
    return YES;
}

- (BOOL)moveCellRecordAtIndexPath:(NSIndexPath *)initialIndexPath toIndexPath:(NSIndexPath *)targetIndexPath {
    return [self moveCellRecordAtIndexPath:initialIndexPath toIndexPath:targetIndexPath managedViewUpdates:nil];
}

- (BOOL)moveSectionRecordAtIndex:(NSInteger)initialIndex 
                         toIndex:(NSInteger)targetIndex 
              managedViewUpdates:(void(^)())managedViewUpdates {
    
    /**  Check parameters  **/
    
    if (initialIndex >= [self numberOfSectionRecords]
        || targetIndex >= [self numberOfSectionRecords]
        || initialIndex < 0
        || targetIndex < 0) {
        return NO;
    }
    
    /**  Inform delegates  **/
    
    [self withEachPluginAndDelegate:^(id delegate) {
        if ([delegate respondsToSelector:@selector(manifest:willMoveSectionRecordAtIndex:toIndex:)]) {
            [delegate manifest:self willMoveSectionRecordAtIndex:initialIndex toIndex:targetIndex];
        }
    }];
    
    /**  Do work  **/
    
    NSMutableArray *mutableSectionRecords = [_sectionRecords mutableCopy];
    FSQSectionRecord *record = [mutableSectionRecords objectAtIndex:initialIndex];
    [mutableSectionRecords removeObjectAtIndex:initialIndex];
    [mutableSectionRecords insertObject:record atIndex:targetIndex];
    
    // Don't use setSectionRecords as that will trigger a view reload
    _sectionRecords = [mutableSectionRecords copy];
    
    if (managedViewUpdates && _automaticallyUpdateManagedView) {
        managedViewUpdates();
    }
    
    /**  Inform delegates  **/
    
    [self withEachPluginAndDelegate:^(id delegate) {
        if ([delegate respondsToSelector:@selector(manifest:didMoveSectionRecordAtIndex:toIndex:)]) {
            [delegate manifest:self didMoveSectionRecordAtIndex:initialIndex toIndex:targetIndex];
        }
    }];
    
    return YES;
}

- (BOOL)moveSectionRecordAtIndex:(NSInteger)initialIndex toIndex:(NSInteger)targetIndex {
    return [self moveSectionRecordAtIndex:initialIndex toIndex:targetIndex managedViewUpdates:nil];
}

- (NSArray *)removeCellRecordsAtIndexPaths:(NSArray *)indexPaths 
                       removeEmptySections:(BOOL)shouldRemoveEmptySections 
                        managedViewUpdates:(void(^)(NSArray *removedIndexPaths, NSIndexSet *removedSectionIndexes))managedViewUpdates {
    
    /**  Check parameters  **/
    
    if ([indexPaths count] <= 0) {
        return nil;
    }
    
    /**  Inform delegates  **/
    
    [self withEachPluginAndDelegate:^(id delegate) {
        if ([delegate respondsToSelector:@selector(manifest:willRemoveCellRecordsAtIndexPaths:removingEmptySections:)]) {
            [delegate manifest:self willRemoveCellRecordsAtIndexPaths:indexPaths removingEmptySections:shouldRemoveEmptySections];
        }
    }];
    
    /**  Do work  **/
    
    NSMutableDictionary *cellIndexesToRemoveBySection = [NSMutableDictionary new];
    
    NSInteger numberOfSections = [self numberOfSectionRecords];
    
    // Store index data in a more useful structure
    for (NSIndexPath *indexPath in indexPaths) {
        if (indexPath.section < numberOfSections && indexPath.section >= 0) {
            NSInteger cellIndexToRemove = [self rowOrItemIndexForIndexPath:indexPath];
            if (cellIndexToRemove < [self numberOfCellRecordsInSectionAtIndex:indexPath.section]
                && cellIndexToRemove >= 0) {
                NSMutableIndexSet *cellIndexesToRemoveForSection = cellIndexesToRemoveBySection[@(indexPath.section)];
                if (!cellIndexesToRemoveForSection) {
                    cellIndexesToRemoveForSection = [NSMutableIndexSet new];
                    cellIndexesToRemoveBySection[@(indexPath.section)] = cellIndexesToRemoveForSection;
                }
                
                [cellIndexesToRemoveForSection addIndex:cellIndexToRemove];
            }
        }
    }
    
    NSMutableArray *removedCellIndexPathsMutable = [NSMutableArray new];
    
    NSMutableIndexSet *sectionIndexesToRemoveMutable = nil;
    if (shouldRemoveEmptySections) {
        sectionIndexesToRemoveMutable = [NSMutableIndexSet new];
    }
    
    for (NSNumber *sectionIndexNumber in [cellIndexesToRemoveBySection allKeys]) {
        NSInteger sectionIndex = [sectionIndexNumber integerValue];
        NSIndexSet *cellIndexesToRemove = cellIndexesToRemoveBySection[sectionIndexNumber];
        FSQSectionRecord *sectionRecord = [self sectionRecordAtIndex:sectionIndex];
        
        // If all cells in this section are to be removed
        if ([cellIndexesToRemove containsIndexesInRange:NSMakeRange(0, [sectionRecord numberOfCellRecords])]) {
            if (sectionIndexesToRemoveMutable) {
                [sectionIndexesToRemoveMutable addIndex:sectionIndex];
                continue;
            }
            else {
                [sectionRecord setCellRecords:nil];
            }
        }
        else {
            NSMutableArray *mutableCellRecords = [sectionRecord.cellRecords mutableCopy];
            [mutableCellRecords removeObjectsAtIndexes:cellIndexesToRemove];
            [sectionRecord setCellRecords:mutableCellRecords];
        }
        
        [cellIndexesToRemove enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [removedCellIndexPathsMutable addObject:[self indexPathForRowOrItem:idx inSection:sectionIndex]];
        }];
    }
    
    NSIndexSet *sectionIndexesToRemove = [sectionIndexesToRemoveMutable copy];
    NSArray *removedCellIndexPaths = [removedCellIndexPathsMutable copy];
    
    [self removeSectionRecordsAtIndexes:sectionIndexesToRemove shouldInformDelegates:NO managedViewUpdates:nil];
    
    if (managedViewUpdates && _automaticallyUpdateManagedView) {
        managedViewUpdates(removedCellIndexPaths, sectionIndexesToRemove);
    }
    
    /**  Inform delegates  **/
    
    [self withEachPluginAndDelegate:^(id delegate) {
        if ([delegate respondsToSelector:@selector(manifest:didRemoveCellRecordsAtIndexPaths:removedEmptySectionsAtIndexes:)]) {
            [delegate manifest:self didRemoveCellRecordsAtIndexPaths:removedCellIndexPaths removedEmptySectionsAtIndexes:sectionIndexesToRemove];
        }
    }];
    
    return [removedCellIndexPaths copy];
}

- (NSArray *)removeCellRecordsAtIndexPaths:(NSArray *)indexPaths 
                       removeEmptySections:(BOOL)shouldRemoveEmptySections {
    return [self removeCellRecordsAtIndexPaths:indexPaths removeEmptySections:shouldRemoveEmptySections managedViewUpdates:nil];
    
}

- (BOOL)removeSectionRecordsAtIndexes:(NSIndexSet *)indexes 
                   managedViewUpdates:(void(^)())managedViewUpdates {
    return [self removeSectionRecordsAtIndexes:indexes shouldInformDelegates:YES managedViewUpdates:managedViewUpdates];
}

- (BOOL)removeSectionRecordsAtIndexes:(NSIndexSet *)indexes 
                shouldInformDelegates:(BOOL)shouldInformDelegates
                   managedViewUpdates:(void(^)())managedViewUpdates {
    
    /**  Check parameters  **/
    
    NSInteger numberOfSections = [self numberOfSectionRecords];
    
    if (numberOfSections <= 0 
        || [indexes count] <= 0 
        || [indexes lastIndex] >= numberOfSections) {
        return NO;
    }
    
    /**  Inform delegates  **/
    if (shouldInformDelegates) {
        [self withEachPluginAndDelegate:^(id delegate) {
            if ([delegate respondsToSelector:@selector(manifest:willRemoveSectionRecordsAtIndexes:)]) {
                [delegate manifest:self willRemoveSectionRecordsAtIndexes:indexes];
            }
        }];
    }
    
    /**  Do work  **/
    
    NSMutableArray *mutableSectionRecords = [_sectionRecords mutableCopy];
    [mutableSectionRecords removeObjectsAtIndexes:indexes];
    _sectionRecords = [mutableSectionRecords copy];
    
    if (managedViewUpdates && _automaticallyUpdateManagedView) {
        managedViewUpdates();
    }
    
    /**  Inform delegates  **/
    if (shouldInformDelegates) {
        [self withEachPluginAndDelegate:^(id delegate) {
            if ([delegate respondsToSelector:@selector(manifest:didRemoveSectionRecordsAtIndexes:)]) {
                [delegate manifest:self didRemoveSectionRecordsAtIndexes:indexes];
            }
        }];
    }
    
    return YES;
}

- (BOOL)removeSectionRecordsAtIndexes:(NSIndexSet *)indexes {
    return [self removeSectionRecordsAtIndexes:indexes managedViewUpdates:nil];
}

- (NSArray *)replaceCellRecordsAtIndexPaths:(NSArray *)indexPaths 
                            withCellRecords:(NSArray *)newCellRecords 
                         managedViewUpdates:(void(^)(NSArray *replacedIndexPaths))managedViewUpdates {
    /**  Check parameters  **/
    
    if (!indexPaths
        || !newCellRecords
        || [indexPaths count] == 0
        || [indexPaths count] != [newCellRecords count]) {
        return nil;
    }
    
    /**  Inform delegates  **/
    
    [self withEachPluginAndDelegate:^(id delegate) {
        if ([delegate respondsToSelector:@selector(manifest:willReplaceCellRecordsAtIndexPaths:withRecords:)]) {
            [delegate manifest:self willReplaceCellRecordsAtIndexPaths:indexPaths withRecords:newCellRecords];
        }
    }];
    
    /**  Do work  **/
    
    NSMutableArray *replacedIndexPathsMutable = [NSMutableArray new];
    NSMutableArray *replacedCellRecordsMutable = [NSMutableArray new];
    NSMutableArray *insertedCellRecordsMutable = [NSMutableArray new];
    
    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger parameterIndex, BOOL *stop) {        
        NSInteger sectionIndex = indexPath.section;
        
        if (sectionIndex >= [self numberOfSectionRecords]
            || sectionIndex < 0) {
            return;
        }
        
        NSInteger cellIndex = [self rowOrItemIndexForIndexPath:indexPath];
        FSQSectionRecord *sectionRecord = [self sectionRecordAtIndex:indexPath.section];
        
        if (cellIndex >= [sectionRecord numberOfCellRecords]
            || cellIndex < 0) {
            return;
        } 
        
        NSMutableArray *cellRecords = [sectionRecord.cellRecords mutableCopy];
        
        [replacedIndexPathsMutable addObject:indexPath];
        [replacedCellRecordsMutable addObject:cellRecords[cellIndex]];
        [insertedCellRecordsMutable addObject:newCellRecords[parameterIndex]];
        
        cellRecords[cellIndex] = newCellRecords[parameterIndex];
        
        [sectionRecord setCellRecords:cellRecords];
    }];
    
    NSArray *replacedIndexPaths = [replacedIndexPathsMutable copy];
    NSArray *replacedCellRecords = [replacedCellRecordsMutable copy];
    NSArray *insertedCellRecords = [insertedCellRecordsMutable copy];
    
    if (managedViewUpdates && _automaticallyUpdateManagedView) {
        managedViewUpdates(replacedIndexPaths);
    }
    
    /**  Inform delegates  **/
    
    [self withEachPluginAndDelegate:^(id delegate) {
        if ([delegate respondsToSelector:@selector(manifest:didReplaceCellRecordsAtIndexPaths:withRecords:replacedRecords:)]) {
            [delegate manifest:self didReplaceCellRecordsAtIndexPaths:replacedIndexPaths withRecords:insertedCellRecords replacedRecords:replacedCellRecords];
        }
    }];
    
    return nil;
}

- (NSArray *)replaceCellRecordsAtIndexPaths:(NSArray *)indexPaths withCellRecords:(NSArray *)newCellRecords {
    return [self replaceCellRecordsAtIndexPaths:indexPaths withCellRecords:newCellRecords managedViewUpdates:nil];
}

- (NSIndexSet *)replaceSectionRecordsAtIndexes:(NSArray *)indexes 
                            withSectionRecords:(NSArray *)newSectionRecords 
                            managedViewUpdates:(void(^)(NSIndexSet *replacedIndexes))managedViewUpdates {
    
    /**  Check parameters  **/
    
    if (!indexes
        || !newSectionRecords
        || [indexes count] == 0
        || [indexes count] != [newSectionRecords count]) {
        return nil;
    }
    
    /**  Inform delegates  **/
    
    [self withEachPluginAndDelegate:^(id delegate) {
        if ([delegate respondsToSelector:@selector(manifest:willReplaceSectionRecordsAtIndexes:withRecords:)]) {
            [delegate manifest:self willReplaceSectionRecordsAtIndexes:indexes withRecords:newSectionRecords];
        }
    }];
    
    /**  Do work  **/
    
    NSMutableArray *replacedIndexesMutable = [NSMutableArray new];
    NSMutableIndexSet *replacedIndexSetMutable = [NSMutableIndexSet new];
    NSMutableArray *replacedSectionRecordsMutable = [NSMutableArray new];
    NSMutableArray *insertedSectionRecordsMutable = [NSMutableArray new];
    
    NSMutableArray *sectionRecordsMutable = [_sectionRecords mutableCopy];
    
    [indexes enumerateObjectsUsingBlock:^(NSNumber *sectionIndexNumber, NSUInteger parameterIndex, BOOL *stop) {
        NSInteger sectionIndex = [sectionIndexNumber integerValue];
        
        if (sectionIndex >= [self numberOfSectionRecords]
            || sectionIndex < 0) {
            return;
        }
        
        [replacedIndexesMutable addObject:sectionIndexNumber];
        [replacedIndexSetMutable addIndex:sectionIndex];
        [replacedSectionRecordsMutable addObject:sectionRecordsMutable[sectionIndex]];
        [insertedSectionRecordsMutable addObject:newSectionRecords[parameterIndex]];
        
        sectionRecordsMutable[sectionIndex] = newSectionRecords[parameterIndex];
    }];
    
    _sectionRecords = [sectionRecordsMutable copy];
    
    NSArray *replacedIndexes = [replacedIndexesMutable copy];
    NSIndexSet *replacedIndexSet = [replacedIndexSetMutable copy];
    NSArray *replacedSectionRecords = [replacedSectionRecordsMutable copy];
    NSArray *insertedSectionRecords = [insertedSectionRecordsMutable copy];
    
    if (managedViewUpdates && _automaticallyUpdateManagedView) {
        managedViewUpdates(replacedIndexSet);
    }
    
    /**  Inform delegates  **/
    
    [self withEachPluginAndDelegate:^(id delegate) {
        if ([delegate respondsToSelector:@selector(manifest:didReplaceSectionRecordsAtIndexes:withRecords:replacedRecords:)]) {
            [delegate manifest:self didReplaceSectionRecordsAtIndexes:replacedIndexes withRecords:insertedSectionRecords replacedRecords:replacedSectionRecords];
        }
    }];
    
    return replacedIndexSet;
}

- (NSIndexSet *)replaceSectionRecordsAtIndexes:(NSArray *)indexes withSectionRecords:(NSArray *)newSectionRecords {
    return [self replaceSectionRecordsAtIndexes:indexes withSectionRecords:newSectionRecords managedViewUpdates:nil];
}

- (void)reloadManagedViewWithUpdates:(void(^)())managedViewUpdates {
    
    /**  Inform delegates  **/
    
    [self withEachPluginAndDelegate:^(id delegate) {
        if ([delegate respondsToSelector:@selector(manifestWillReloadManagedView:)]) {
            [delegate manifestWillReloadManagedView:self];
        }
    }];
    
    /**  Do work  **/
    
    if (managedViewUpdates) {
        managedViewUpdates();
    }
    
    /**  Inform delegates  **/
    
    [self withEachPluginAndDelegate:^(id delegate) {
        if ([delegate respondsToSelector:@selector(manifestDidReloadManagedView:)]) {
            [delegate manifestDidReloadManagedView:self];
        }
    }];
}

- (void)reloadManagedView {
    [self reloadManagedViewWithUpdates:nil];
}

- (void)reloadSectionsAtIndexes:(NSIndexSet *)indexes managedViewUpdates:(void(^)(NSIndexSet *indexes))managedViewUpdates {
    
    /**  Inform delegates  **/
    
    [self withEachPluginAndDelegate:^(id delegate) {
        if ([delegate respondsToSelector:@selector(manifest:willReloadSectionsAtIndexes:)]) {
            [delegate manifest:self willReloadSectionsAtIndexes:indexes];
        }
    }];
    
    /**  Do work  **/
    
    if (managedViewUpdates) {
        managedViewUpdates(indexes);
    }
    
    /**  Inform delegates  **/
    
    [self withEachPluginAndDelegate:^(id delegate) {
        if ([delegate respondsToSelector:@selector(manifest:didReloadSectionsAtIndexes:)]) {
            [delegate manifest:self didReloadSectionsAtIndexes:indexes];
        }
    }];
}

- (void)reloadSectionsAtIndexes:(NSIndexSet *)indexes {
    [self reloadSectionsAtIndexes:indexes managedViewUpdates:nil];
}

- (void)reloadCellsAtIndexPaths:(NSArray *)indexPaths managedViewUpdates:(void(^)(NSArray *indexPaths))managedViewUpdates {
    
    /**  Inform delegates  **/
    
    [self withEachPluginAndDelegate:^(id delegate) {
        if ([delegate respondsToSelector:@selector(manifest:willReloadCellsAtIndexPaths:)]) {
            [delegate manifest:self willReloadCellsAtIndexPaths:indexPaths];
        }
    }];
    
    /**  Do work  **/
    
    if (managedViewUpdates) {
        managedViewUpdates(indexPaths);
    }
    
    /**  Inform delegates  **/
    
    [self withEachPluginAndDelegate:^(id delegate) {
        if ([delegate respondsToSelector:@selector(manifest:didReloadCellsAtIndexPaths:)]) {
            [delegate manifest:self didReloadCellsAtIndexPaths:indexPaths];
        }
    }];
}

- (void)reloadCellsAtIndexPaths:(NSArray *)indexPaths {
    [self reloadCellsAtIndexPaths:indexPaths managedViewUpdates:nil];
}

#pragma mark - Shared configuration

- (void)configureView:(id)view withRecord:(FSQCellRecord *)record recordType:(FSQCellRecordType)recordType atIndexPath:(NSIndexPath *)indexPath {
    switch (recordType) {
        case FSQCellRecordTypeBody: {
            [self withEachPluginAndDelegate:^(id delegate) {
                if ([delegate respondsToSelector:@selector(manifest:willConfigureCell:withModel:atIndexPath:record:)]) {
                    [delegate manifest:self willConfigureCell:view withModel:record.model atIndexPath:indexPath  record:record];
                }
            }];
        }
            break;
        case FSQCellRecordTypeHeader: {
            [self withEachPluginAndDelegate:^(id delegate) {
                if ([delegate respondsToSelector:@selector(manifest:willConfigureHeader:withModel:atIndex:record:)]) {
                    [delegate manifest:self willConfigureHeader:view withModel:record.model atIndex:indexPath.section record:record];
                }
            }];
        }
            break;
        case FSQCellRecordTypeFooter: {
            [self withEachPluginAndDelegate:^(id delegate) {
                if ([delegate respondsToSelector:@selector(manifest:willConfigureFooter:withModel:atIndex:record:)]) {
                    [delegate manifest:self willConfigureFooter:view withModel:record.model atIndex:indexPath.section record:record];
                }
            }];
        }
            break;
    }
    
    if ([view conformsToProtocol:@protocol(FSQCellManifestCellProtocol)]) {
        [(id<FSQCellManifestCellProtocol>)view manifest:self configureWithModel:record.model indexPath:indexPath record:record];
    }
    
    if (record.onConfigure) {
        record.onConfigure(view, indexPath, self, record);
    }
    
    switch (recordType) {
        case FSQCellRecordTypeBody: {
            [self withEachPluginAndDelegate:^(id delegate) {
                if ([delegate respondsToSelector:@selector(manifest:didConfigureCell:withModel:atIndexPath:record:)]) {
                    [delegate manifest:self didConfigureCell:view withModel:record.model atIndexPath:indexPath record:record];
                }
            }];
        }
            break;
        case FSQCellRecordTypeHeader: {
            [self withEachPluginAndDelegate:^(id delegate) {
                if ([delegate respondsToSelector:@selector(manifest:didConfigureHeader:withModel:atIndex:record:)]) {
                    [delegate manifest:self didConfigureHeader:view withModel:record.model atIndex:indexPath.section record:record];
                }
            }];
        }
            break;
        case FSQCellRecordTypeFooter: {
            [self withEachPluginAndDelegate:^(id delegate) {
                if ([delegate respondsToSelector:@selector(manifest:didConfigureFooter:withModel:atIndex:record:)]) {
                    [delegate manifest:self didConfigureFooter:view withModel:record.model atIndex:indexPath.section record:record];
                }
            }];
        }
            break;
    }
}

- (FSQIdentifierRegistrationResult)registerIdentifier:(NSString *)identifier forCellClass:(Class)cellClass recordType:(FSQCellRecordType)recordType {
    
    if (recordType == FSQCellRecordTypeBody) {
        return [self registerIdentifier:identifier forCellClass:cellClass map:_identifierCellClassMap];        
    }
    else {
        @throw ([NSException exceptionWithName:NSInvalidArgumentException reason:@"Unrecognized recordType in registerIdentifier:forCellClass:recordType:" userInfo:nil]);
    }
}

- (FSQIdentifierRegistrationResult)registerIdentifier:(NSString *)identifier forCellClass:(Class)cellClass map:(NSMutableDictionary *)map {
    Class registeredClass = map[identifier];
    
    if (registeredClass) {
        if (registeredClass == cellClass) {
            return FSQIdentifierRegistrationResultAlreadyExists;
        }
        else {
            return FSQIdentifierRegistrationResultConflictingExistingType;
        }
    }
    else {
        map[identifier] = cellClass;
        return FSQIdentifierRegistrationResultAdded;
    }
}


- (NSSet *)matchingIndexPathsForCurrentlySelectedIndexPaths:(NSArray *)currentlySelectedIndexPaths
                                          newSectionRecords:(NSArray *)newSectionRecords {
    
    NSMutableSet *currentlySelectedRecords = [NSMutableSet new];
    
    for (NSIndexPath *selectedPath in currentlySelectedIndexPaths) {
        [currentlySelectedRecords addObject:[self cellRecordAtIndexPath:selectedPath]];
    }
    
    NSMutableSet *newIndexPathsToSelect = [NSMutableSet new];
    
    NSInteger sectionIndex = 0;
    for (FSQSectionRecord *newSectionRecord in newSectionRecords) {
        NSInteger cellIndex = 0;
        for (FSQCellRecord *newCellRecord in newSectionRecord) {
            for (FSQCellRecord *currentCellRecord in currentlySelectedRecords) {
                if ([newCellRecord isEqualToCellRecord:currentCellRecord]) {
                    [newIndexPathsToSelect addObject:[self indexPathForRowOrItem:cellIndex inSection:sectionIndex]];
                    break;
                }
            }
            ++cellIndex;
        }
        ++sectionIndex;
    }
    
    return newIndexPathsToSelect;
}

- (BOOL)recordShouldHighlightAtIndexPath:(NSIndexPath *)indexPath {
    FSQCellRecord *record = [self cellRecordAtIndexPath:indexPath];
    BOOL shouldHighlight = record.allowsHighlighting;
    if (!shouldHighlight && ![record allowsHighlightingWasSet]) {
        shouldHighlight = self.cellSelectionEnabledByDefault;
    }
    return shouldHighlight;
}

- (BOOL)recordShouldSelectAtIndexPath:(NSIndexPath *)indexPath {
    FSQCellRecord *record = [self cellRecordAtIndexPath:indexPath];
    BOOL shouldSelect = record.allowsSelection;
    if (!shouldSelect && ![record allowsSelectionWasSet]) {
        shouldSelect = self.cellSelectionEnabledByDefault;
    }
    
    if (shouldSelect) {
        return YES;
    }
    else {
        return NO;
    }
}

@end

#pragma mark End Core Manifest -

#pragma mark - Begin Table View Manifest

@implementation FSQTableViewCellManifest {
    NSMutableDictionary *_headerFooterIdentifierCellClassMap;
    FSQCellManifestMessageForwarderEnumerator *_tableViewDatasourceForwarderEnumerator;
}

- (void)setTableView:(UITableView *)tableView {
    self.tableView.dataSource = nil;
    
    [self setManagedView:tableView];
    tableView.dataSource = _tableViewDatasourceForwarderEnumerator.messageForwarder;
}

- (UITableView *)tableView {
    return (UITableView *)self.managedView;
}


- (NSArray *)messageForwarderEnumerators NS_REQUIRES_SUPER {
    return  [[super messageForwarderEnumerators] arrayByAddingObjectsFromArray:@[_tableViewDatasourceForwarderEnumerator]];
}

- (void)createForwarders NS_REQUIRES_SUPER {
    [super createForwarders];
    
    _tableViewDatasourceForwarderEnumerator = [FSQCellManifestMessageForwarderEnumerator new];
    _tableViewDatasourceForwarderEnumerator.manifest = self;
}

- (instancetype)initWithDelegate:(id)delegate 
                         plugins:(NSArray *)plugins
                       tableView:(UITableView *)tableView {
    if ((self = [self initWithDelegate:delegate plugins:plugins])) {
        [self setTableView:tableView];
        _headerFooterIdentifierCellClassMap = [NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc {
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;
}

- (NSInteger)rowOrItemIndexForIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row;
}

- (NSIndexPath * )indexPathForRowOrItem:(NSInteger)rowOrItem inSection:(NSInteger)section {
    return [NSIndexPath indexPathForRow:rowOrItem inSection:section];
}

- (void)performBatchRecordModificationUpdates:(void (^)(void))updates {
    
    if (updates) {
        [self.tableView beginUpdates];
        updates();
        [self.tableView endUpdates];
    }
}

#pragma mark - Insertion and Removal - 

- (void)reloadManagedView {
    [super reloadManagedViewWithUpdates:^{
        [self.tableView reloadData];
    }];
}

- (void)reloadSectionsAtIndexes:(NSIndexSet *)indexes {
    [self reloadSectionsAtIndexes:indexes withAnimation:UITableViewRowAnimationNone];
}

- (void)reloadSectionsAtIndexes:(NSIndexSet *)indexes withAnimation:(UITableViewRowAnimation)animation {
    [super reloadSectionsAtIndexes:indexes managedViewUpdates:^(NSIndexSet *indexes) {
        [self.tableView reloadSections:indexes withRowAnimation:animation];
    }];
}

- (void)reloadCellsAtIndexPaths:(NSArray *)indexPaths {
    [self reloadCellsAtIndexPaths:indexPaths withAnimation:UITableViewRowAnimationNone];
}

- (void)reloadCellsAtIndexPaths:(NSArray *)indexPaths withAnimation:(UITableViewRowAnimation)animation {
    [super reloadCellsAtIndexPaths:indexPaths managedViewUpdates:^(NSArray *indexPaths) {
        [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:animation];
    }];
}

- (void)setSectionRecords:(NSArray *)sectionRecords selectionStrategy:(FSQViewReloadCellSelectionStrategy)selectionStrategy {
    
    switch (selectionStrategy) {
        case FSQViewReloadCellSelectionStrategyDeselectAll: {
            [super replaceSectionRecords:sectionRecords 
                       selectionStrategy:selectionStrategy 
                      managedViewUpdates:^(NSArray *originalRecorcds) {
                          [self.tableView reloadData];
                          
                          // Possibly not needed, UITableView's  reloadData method does this, but the behavior is not documented.
                          for (NSIndexPath *indexPath in [self.tableView indexPathsForSelectedRows]) {
                              [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                          }
                      }];
        }
            break;
        case FSQViewReloadCellSelectionStrategyMaintainSelectedIndexPaths: {
            [super replaceSectionRecords:sectionRecords 
                       selectionStrategy:selectionStrategy 
                      managedViewUpdates:^(NSArray *originalRecorcds) {
                          NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
                          
                          [self.tableView reloadData];
                          
                          for (NSIndexPath *indexPath in indexPaths) {
                              [self.tableView selectRowAtIndexPath:indexPath 
                                                          animated:NO 
                                                    scrollPosition:UITableViewScrollPositionNone];
                          }
                      }];
        }
            break;
        case FSQViewReloadCellSelectionStrategyMaintainSelectedRecords: {
            NSSet *newIndexPathsToSelect = [self matchingIndexPathsForCurrentlySelectedIndexPaths:[self.tableView indexPathsForSelectedRows] 
                                                                                newSectionRecords:sectionRecords];
            
            // Above must be done before super call so "currently" selected paths line up
            [super replaceSectionRecords:sectionRecords 
                       selectionStrategy:selectionStrategy 
                      managedViewUpdates:^(NSArray *originalRecorcds) {
                          [self.tableView reloadData];
                          
                          for (NSIndexPath *indexPath in newIndexPathsToSelect) {
                              [self.tableView selectRowAtIndexPath:indexPath 
                                                          animated:NO 
                                                    scrollPosition:UITableViewScrollPositionNone];
                          }
                      }];
        }
            break;
    }
}

- (NSArray *)insertCellRecords:(NSArray *)cellRecordsToInsert atIndexPath:(NSIndexPath *)indexPath {
    return [self insertCellRecords:cellRecordsToInsert atIndexPath:indexPath withAnimation:UITableViewRowAnimationNone];
}

- (NSArray *)insertCellRecords:(NSArray *)cellRecordsToInsert atIndexPath:(NSIndexPath *)indexPath withAnimation:(UITableViewRowAnimation)animation {
    return [super insertCellRecords:cellRecordsToInsert 
                        atIndexPath:indexPath 
                 managedViewUpdates:^(NSArray *insertedIndexPaths) {
                     if ([insertedIndexPaths count] > 0) {
                         [self.tableView insertRowsAtIndexPaths:insertedIndexPaths withRowAnimation:animation];
                     }
                 }];
}

- (NSIndexSet *)insertSectionRecords:(NSArray *)sectionRecords atIndex:(NSInteger)index {
    return [self insertSectionRecords:sectionRecords atIndex:index withAnimation:UITableViewRowAnimationNone];
}

- (NSIndexSet *)insertSectionRecords:(NSArray *)sectionRecords atIndex:(NSInteger)index withAnimation:(UITableViewRowAnimation)animation {
    return [super insertSectionRecords:sectionRecords 
                               atIndex:index 
                    managedViewUpdates:^(NSIndexSet *insertedIndexes) {
                        if ([insertedIndexes count] > 0) {
                            [self.tableView insertSections:insertedIndexes withRowAnimation:animation];
                        }
                    }];
}

- (BOOL)moveCellRecordAtIndexPath:(NSIndexPath *)initialIndexPath toIndexPath:(NSIndexPath *)targetIndexPath {
    return [super moveCellRecordAtIndexPath:initialIndexPath 
                                toIndexPath:targetIndexPath 
                         managedViewUpdates:^{
                             [self.tableView moveRowAtIndexPath:initialIndexPath toIndexPath:targetIndexPath];
                         }];
}

- (BOOL)moveSectionRecordAtIndex:(NSInteger)initialIndex toIndex:(NSInteger)targetIndex {
    return [super moveSectionRecordAtIndex:initialIndex 
                                   toIndex:targetIndex 
                        managedViewUpdates:^{
                            [self.tableView moveSection:initialIndex toSection:targetIndex];
                        }];
}


- (NSArray *)removeCellRecordsAtIndexPaths:(NSArray *)indexPaths 
                       removeEmptySections:(BOOL)shouldRemoveEmptySections {
    return [self removeCellRecordsAtIndexPaths:indexPaths 
                                 withAnimation:UITableViewRowAnimationNone 
                           removeEmptySections:shouldRemoveEmptySections];
}

- (NSArray *)removeCellRecordsAtIndexPaths:(NSArray *)indexPaths 
                             withAnimation:(UITableViewRowAnimation)animation 
                       removeEmptySections:(BOOL)shouldRemoveEmptySections {
    return [super removeCellRecordsAtIndexPaths:indexPaths 
                            removeEmptySections:shouldRemoveEmptySections 
                             managedViewUpdates:^(NSArray *removedIndexPaths, NSIndexSet *removedSectionIndexes) {
                                 if ([removedSectionIndexes count] > 0) {
                                     [self.tableView beginUpdates];
                                     [self.tableView deleteRowsAtIndexPaths:removedIndexPaths withRowAnimation:animation];
                                     [self.tableView deleteSections:removedSectionIndexes withRowAnimation:animation];
                                     [self.tableView endUpdates];
                                 }
                                 else {
                                     [self.tableView deleteRowsAtIndexPaths:removedIndexPaths withRowAnimation:animation];
                                 }
                             }];
}

- (BOOL)removeSectionRecordsAtIndexes:(NSIndexSet *)indexes {
    return [self removeSectionRecordsAtIndexes:indexes withAnimation:UITableViewRowAnimationNone];
}

- (BOOL)removeSectionRecordsAtIndexes:(NSIndexSet *)indexes withAnimation:(UITableViewRowAnimation)animation {
    return [super removeSectionRecordsAtIndexes:indexes 
                             managedViewUpdates:^{
                                 [self.tableView deleteSections:indexes withRowAnimation:animation];
                             }];
}

- (NSArray *)replaceCellRecordsAtIndexPaths:(NSArray *)indexPaths withCellRecords:(NSArray *)newCellRecords {
    return [self replaceCellRecordsAtIndexPaths:indexPaths withCellRecords:newCellRecords withAnimation:UITableViewRowAnimationNone];
}

- (NSArray *)replaceCellRecordsAtIndexPaths:(NSArray *)indexPaths 
                            withCellRecords:(NSArray *)newCellRecords 
                              withAnimation:(UITableViewRowAnimation)animation {
    return [super replaceCellRecordsAtIndexPaths:indexPaths 
                                 withCellRecords:newCellRecords 
                              managedViewUpdates:^(NSArray *replacedIndexPaths) {
                                  if ([replacedIndexPaths count] > 0) {
                                      [self.tableView reloadRowsAtIndexPaths:replacedIndexPaths withRowAnimation:animation];
                                  }
                              }];
    
}

- (NSIndexSet *)replaceSectionRecordsAtIndexes:(NSArray *)indexes withSectionRecords:(NSArray *)newSectionRecords {
    return [self replaceSectionRecordsAtIndexes:indexes withSectionRecords:newSectionRecords withAnimation:UITableViewRowAnimationNone];
}

- (NSIndexSet *)replaceSectionRecordsAtIndexes:(NSArray *)indexes 
                            withSectionRecords:(NSArray *)newSectionRecords 
                                 withAnimation:(UITableViewRowAnimation)animation {
    return [super replaceSectionRecordsAtIndexes:indexes 
                              withSectionRecords:newSectionRecords 
                              managedViewUpdates:^(NSIndexSet *replacedIndexes) {
                                  if ([replacedIndexes count] > 0) {
                                      [self.tableView reloadSections:replacedIndexes withRowAnimation:animation];
                                  }
                              }];
}

#pragma mark - Table View Delegate Methods -

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        FSQCellRecord *record = [self cellRecordAtIndexPath:indexPath];
        
        CGSize maxSize = [self maxSizeForRecord:record atIndexPath:indexPath defaultWidth:CGRectGetWidth(tableView.frame) defaultHeight:CGFLOAT_MAX];
        
        if ([self.delegate respondsToSelector:@selector(sizeForCellAtIndexPath:withManifest:record:maximumSize:)]) {
            return [self.delegate sizeForCellAtIndexPath:indexPath withManifest:self record:record maximumSize:maxSize].height;
        }
        else if ([record.cellClass conformsToProtocol:@protocol(FSQCellManifestTableViewCellProtocol)]) {
            return [record.cellClass manifest:self heightForModel:record.model maximumSize:maxSize indexPath:indexPath record:record];
        }
        else {
            return 0;
        }
    }
    else {
        return 0;
    }
}

- (CGFloat)heightForHeaderOrFooter:(FSQCellRecord *)record indexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    if ([record.cellClass conformsToProtocol:@protocol(FSQCellManifestTableViewCellProtocol)]) {
        CGSize maxSize = [self maxSizeForRecord:record atIndexPath:nil defaultWidth:CGRectGetWidth(tableView.frame) defaultHeight:CGFLOAT_MAX];
        return [record.cellClass manifest:self heightForModel:record.model maximumSize:maxSize indexPath:indexPath record:record];
    }
    else {
        return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return [self heightForHeaderOrFooter:[self sectionRecordAtIndex:section].header indexPath:[NSIndexPath indexPathForRow:kRowIndexForHeaderIndexPaths inSection:section] tableView:tableView];
    }
    else {
        return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return [self heightForHeaderOrFooter:[self sectionRecordAtIndex:section].footer indexPath:[NSIndexPath indexPathForRow:kRowIndexForFooterIndexPaths inSection:section] tableView:tableView];
    }
    else {
        return 0;
    }
}

- (UITableViewHeaderFooterView *)viewForHeaderOrFooter:(FSQCellRecordType)recordType 
                                                record:(FSQCellRecord *)record 
                                             tableView:(UITableView *)tableView 
                                             indexPath:(NSIndexPath *)indexPath {
    if (!record) {
        return nil;
    }
    
    NSString *identifier = record.reuseIdentifier ?: NSStringFromClass(record.cellClass);
    
    [self registerIdentifier:identifier forCellClass:record.cellClass recordType:recordType];
    
    UITableViewHeaderFooterView *headerFooterView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:identifier];
    
    if ([headerFooterView conformsToProtocol:@protocol(FSQCellManifestTableViewCellProtocol)]) {
        [(id<FSQCellManifestCellProtocol>)headerFooterView manifest:self configureWithModel:record.model indexPath:indexPath record:record];
    }
    
    [self configureView:headerFooterView withRecord:record recordType:recordType atIndexPath:indexPath];
    
    return headerFooterView;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return [self viewForHeaderOrFooter:FSQCellRecordTypeHeader
                                    record:[self sectionRecordAtIndex:section].header 
                                 tableView:tableView 
                                 indexPath:[NSIndexPath indexPathForRow:kRowIndexForHeaderIndexPaths inSection:section]];
    }
    else {
        return nil;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return [self viewForHeaderOrFooter:FSQCellRecordTypeFooter
                                    record:[self sectionRecordAtIndex:section].footer 
                                 tableView:tableView 
                                 indexPath:[NSIndexPath indexPathForRow:kRowIndexForFooterIndexPaths inSection:section]];
    }
    else {
        return nil;
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        return [self recordShouldHighlightAtIndexPath:indexPath];
    }
    else {
        return NO;
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if ([self recordShouldSelectAtIndexPath:indexPath]) {
            return indexPath;
        }
        else {
            return nil;
        }
    }
    else {
        return indexPath;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        FSQCellRecord *record = [self cellRecordAtIndexPath:indexPath];
        
        [self withEachPluginAndDelegate:^(id delegate) {
            if ([delegate respondsToSelector:@selector(manifest:willSelectCellAtIndexPath:withRecord:)]) {
                [delegate manifest:self willSelectCellAtIndexPath:indexPath withRecord:record];
            }
        }];
        
        if (record.onSelection) {
            record.onSelection(indexPath, self, record);
        }
        
        [self withEachPluginAndDelegate:^(id delegate) {
            if ([delegate respondsToSelector:@selector(manifest:didSelectCellAtIndexPath:withRecord:)]) {
                [delegate manifest:self didSelectCellAtIndexPath:indexPath withRecord:record];
            }
        }];
    }
}

#pragma mark - Table View Data Source Methods -
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return [self numberOfSectionRecords];
    }
    else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return [self numberOfCellRecordsInSectionAtIndex:section];
    }
    else {
        return 0;
    }
}

- (FSQIdentifierRegistrationResult)registerIdentifier:(NSString *)identifier forCellClass:(Class)cellClass recordType:(FSQCellRecordType)recordType {
    
    BOOL isHeaderOrFooter = (recordType != FSQCellRecordTypeBody);
    
    FSQIdentifierRegistrationResult result;
    
    if (isHeaderOrFooter) {
        result = [self registerIdentifier:identifier forCellClass:cellClass map:_headerFooterIdentifierCellClassMap];
    }
    else {
        result = [super registerIdentifier:identifier forCellClass:cellClass recordType:recordType];
    }
    
    switch (result) {
        case FSQIdentifierRegistrationResultAlreadyExists:
            // do nothing
            break;
        case FSQIdentifierRegistrationResultAdded:
        {
            if (isHeaderOrFooter) {
                [self.tableView registerClass:cellClass forHeaderFooterViewReuseIdentifier:identifier];
            }
            else {
                [self.tableView registerClass:cellClass forCellReuseIdentifier:identifier];   
            }
            break;
        }
        case FSQIdentifierRegistrationResultConflictingExistingType:
        {
            @throw ([NSException exceptionWithName:kFSQIdentifierClassMismatchException 
                                            reason:[NSString stringWithFormat:@"Tried to register class %@ for identifier %@, but a different class was already registered. Delegate: %@", cellClass, identifier, self.delegate]
                                          userInfo:nil]);
        }
    }
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        FSQCellRecord *record = [self cellRecordAtIndexPath:indexPath];
        NSString *identifier = record.reuseIdentifier ?: NSStringFromClass(record.cellClass);
        
        if (!record || !identifier || !record.cellClass) {
            return nil;
        }
        
        [self registerIdentifier:identifier forCellClass:record.cellClass recordType:FSQCellRecordTypeBody];
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
        [self configureView:cell withRecord:record recordType:FSQCellRecordTypeBody atIndexPath:indexPath];
        return cell;
    }
    else {
        NSAssert(0, @"Unrecognized table view in FSQCellManifest cellForRowAtIndexPath");
        return nil;
    }
}

@end

#pragma mark End Table View Manifest -

#pragma mark - Begin Collection View Manifest

@implementation FSQCollectionViewCellManifest {
    NSMutableDictionary *_headerIdentifierCellClassMap;
    NSMutableDictionary *_footerIdentifierCellClassMap;
    FSQCellManifestMessageForwarderEnumerator *_collectionViewDatasourceForwarderEnumerator;
}

- (NSArray *)messageForwarderEnumerators NS_REQUIRES_SUPER {
    return  [[super messageForwarderEnumerators] arrayByAddingObjectsFromArray:@[_collectionViewDatasourceForwarderEnumerator]];
}

- (void)createForwarders NS_REQUIRES_SUPER {
    [super createForwarders];
    _collectionViewDatasourceForwarderEnumerator = [FSQCellManifestMessageForwarderEnumerator new];
    _collectionViewDatasourceForwarderEnumerator.manifest = self;
}


- (void)setCollectionView:(UICollectionView *)collectionView {
    self.collectionView.dataSource = nil;
    
    [self setManagedView:collectionView];
    collectionView.dataSource = _collectionViewDatasourceForwarderEnumerator.messageForwarder;
}

- (UICollectionView *)collectionView {
    return (UICollectionView *)self.managedView;
}

- (instancetype)initWithDelegate:(id)delegate 
                         plugins:(NSArray *)plugins
                  collectionView:(UICollectionView *)collectionView {
    
    if ((self = [self initWithDelegate:delegate plugins:plugins])) {
        [self setCollectionView:collectionView];
    }
    return self;
}

- (void)dealloc {
    self.collectionView.dataSource = nil;
    self.collectionView.delegate = nil;
}

- (NSInteger)rowOrItemIndexForIndexPath:(NSIndexPath *)indexPath {
    return indexPath.item;
}

- (NSIndexPath *)indexPathForRowOrItem:(NSInteger)rowOrItem inSection:(NSInteger)section {
    return [NSIndexPath indexPathForItem:rowOrItem inSection:section];
}

- (void)performBatchRecordModificationUpdates:(void (^)(void))updates {
    if (updates) {
        [self.collectionView performBatchUpdates:updates completion:nil];
    }
}

#pragma mark - Insertion and Removal - 

- (void)reloadManagedView {
    [super reloadManagedViewWithUpdates:^{
        [self.collectionView reloadData];
    }];
}

- (void)reloadSectionsAtIndexes:(NSIndexSet *)indexes {
    [super reloadSectionsAtIndexes:indexes managedViewUpdates:^(NSIndexSet *indexes) {
        [self.collectionView reloadSections:indexes];
    }];
}

- (void)reloadCellsAtIndexPaths:(NSArray *)indexPaths {
    [super reloadCellsAtIndexPaths:indexPaths managedViewUpdates:^(NSArray *indexPaths) {
        [self.collectionView reloadItemsAtIndexPaths:indexPaths];
    }];
}

- (void)setSectionRecords:(NSArray *)sectionRecords selectionStrategy:(FSQViewReloadCellSelectionStrategy)selectionStrategy {
    
    switch (selectionStrategy) {
        case FSQViewReloadCellSelectionStrategyDeselectAll: {
            [super replaceSectionRecords:sectionRecords 
                       selectionStrategy:selectionStrategy 
                      managedViewUpdates:^(NSArray *originalRecorcds) {
                          [self.collectionView reloadData];
                          
                          // Possibly not needed, UICollectionView's  reloadData method does this, but the behavior is not documented.
                          for (NSIndexPath *indexPath in [self.collectionView indexPathsForSelectedItems]) {
                              [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
                          }
                      }];
        }
            break;
        case FSQViewReloadCellSelectionStrategyMaintainSelectedIndexPaths: {
            [super replaceSectionRecords:sectionRecords 
                       selectionStrategy:selectionStrategy 
                      managedViewUpdates:^(NSArray *originalRecorcds) {
                          NSArray *indexPaths = [self.collectionView indexPathsForSelectedItems];
                          
                          [self.collectionView reloadData];
                          
                          for (NSIndexPath *indexPath in indexPaths) {
                              [self.collectionView selectItemAtIndexPath:indexPath 
                                                                animated:NO 
                                                          scrollPosition:UICollectionViewScrollPositionNone];
                          }
                      }];
        }
            break;
        case FSQViewReloadCellSelectionStrategyMaintainSelectedRecords: {
            NSSet *newIndexPathsToSelect = [self matchingIndexPathsForCurrentlySelectedIndexPaths:[self.collectionView indexPathsForSelectedItems] 
                                                                                newSectionRecords:sectionRecords];
            
            // Above must be done before super call so "currently" selected paths line up
            [super replaceSectionRecords:sectionRecords 
                       selectionStrategy:selectionStrategy 
                      managedViewUpdates:^(NSArray *originalRecorcds) {
                          [self.collectionView reloadData];
                          
                          for (NSIndexPath *indexPath in newIndexPathsToSelect) {
                              [self.collectionView selectItemAtIndexPath:indexPath 
                                                                animated:NO 
                                                          scrollPosition:UICollectionViewScrollPositionNone];
                          }
                      }];
        }
            break;
    }
}

- (NSArray *)insertCellRecords:(NSArray *)cellRecordsToInsert atIndexPath:(NSIndexPath *)indexPath {
    return [super insertCellRecords:cellRecordsToInsert 
                        atIndexPath:indexPath 
                 managedViewUpdates:^(NSArray *insertedIndexPaths) {
                     if ([insertedIndexPaths count] > 0) {
                         [self.collectionView insertItemsAtIndexPaths:insertedIndexPaths];
                     }
                 }];
}

- (NSIndexSet *)insertSectionRecords:(NSArray *)sectionRecords atIndex:(NSInteger)index {
    return [self insertSectionRecords:sectionRecords 
                              atIndex:index 
                   managedViewUpdates:^(NSIndexSet *insertedIndexes) {
                       if ([insertedIndexes count] > 0) {
                           [self.collectionView insertSections:insertedIndexes];
                       }
                   }];
}

- (BOOL)moveCellRecordAtIndexPath:(NSIndexPath *)initialIndexPath toIndexPath:(NSIndexPath *)targetIndexPath {
    return [super moveCellRecordAtIndexPath:initialIndexPath 
                                toIndexPath:targetIndexPath 
                         managedViewUpdates:^{
                             [self.collectionView moveItemAtIndexPath:initialIndexPath toIndexPath:targetIndexPath];
                         }];
}

- (BOOL)moveSectionRecordAtIndex:(NSInteger)initialIndex toIndex:(NSInteger)targetIndex {
    return [super moveSectionRecordAtIndex:initialIndex 
                                   toIndex:targetIndex 
                        managedViewUpdates:^{
                            [self.collectionView moveSection:initialIndex toSection:targetIndex];
                        }];
}

- (NSArray *)removeCellRecordsAtIndexPaths:(NSArray *)indexPaths removeEmptySections:(BOOL)shouldRemoveEmptySections {
    
    return [super removeCellRecordsAtIndexPaths:indexPaths 
                            removeEmptySections:shouldRemoveEmptySections 
                             managedViewUpdates:^(NSArray *removedIndexPaths, NSIndexSet *removedSectionIndexes) {
                                 if ([removedSectionIndexes count] > 0) {
                                     [self.collectionView performBatchUpdates:^{
                                         [self.collectionView deleteItemsAtIndexPaths:removedIndexPaths];
                                         [self.collectionView deleteSections:removedSectionIndexes];
                                     } completion:nil];
                                 }
                                 else {
                                     [self.collectionView deleteItemsAtIndexPaths:removedIndexPaths];
                                 }
                             }];
}

- (BOOL)removeSectionRecordsAtIndexes:(NSIndexSet *)indexes {
    return [super removeSectionRecordsAtIndexes:indexes 
                             managedViewUpdates:^{
                                 [self.collectionView deleteSections:indexes];
                             }];
}

- (NSArray *)replaceCellRecordsAtIndexPaths:(NSArray *)indexPaths withCellRecords:(NSArray *)newCellRecords {
    return [super replaceCellRecordsAtIndexPaths:indexPaths 
                                 withCellRecords:newCellRecords 
                              managedViewUpdates:^(NSArray *replacedIndexPaths) {
                                  if ([replacedIndexPaths count] > 0) {
                                      [self.collectionView reloadItemsAtIndexPaths:replacedIndexPaths];
                                  }
                              }];
    
}

- (NSIndexSet *)replaceSectionRecordsAtIndexes:(NSArray *)indexes withSectionRecords:(NSArray *)newSectionRecords {
    return [super replaceSectionRecordsAtIndexes:indexes 
                              withSectionRecords:newSectionRecords 
                              managedViewUpdates:^(NSIndexSet *replacedIndexes) {
                                  if ([replacedIndexes count] > 0) {
                                      [self.collectionView reloadSections:replacedIndexes];
                                  }
                              }];
}

#pragma mark - Collection View Data Source Methods -

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (self.collectionView == collectionView) {
        return [self numberOfSectionRecords];        
    }
    else {
        return 0;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.collectionView == collectionView) {
        return [self numberOfCellRecordsInSectionAtIndex:section];        
    }
    else {
        return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.collectionView == collectionView) {
        FSQCellRecord *record = [self cellRecordAtIndexPath:indexPath];
        
        if (!record) {
            return nil;
        }
        
        NSString *identifier = record.reuseIdentifier ?: NSStringFromClass(record.cellClass);
        
        if (!identifier || !record.cellClass) {
            NSAssert(0, @"Missing identifier or cell class in FSQCellManifest cellForItemAtIndexPath:");
            return nil;
        }
        
        [self registerIdentifier:identifier forCellClass:record.cellClass recordType:FSQCellRecordTypeBody];
        
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
        
        if (!cell) {
            @throw ([NSException exceptionWithName:kFSQIdentifierCellDequeueException 
                                            reason:[NSString stringWithFormat:@"Tried to dequeue cell of class %@ for identifier %@, but failed. Delegate: %@", record.cellClass, identifier, self.delegate]
                                          userInfo:nil]);
        }
        
        [self configureView:cell withRecord:record recordType:FSQCellRecordTypeBody atIndexPath:indexPath];
        [cell setNeedsLayout];
        return cell;
    }
    else {
        NSAssert(0, @"Unrecognized table view in FSQCellManifest cellForItemAtIndexPath:");
        return nil;
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if (self.collectionView == collectionView) {
        
        FSQCellRecord *record = nil;
        FSQCellRecordType recordType = FSQCellRecordTypeBody;
        
        if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
            record = [self sectionRecordAtIndex:indexPath.section].header;
            recordType = FSQCellRecordTypeHeader;
        }
        else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
            record = [self sectionRecordAtIndex:indexPath.section].footer;
            recordType = FSQCellRecordTypeFooter;
        }
        
        if (record) {
            NSString *identifier = record.reuseIdentifier ?: NSStringFromClass(record.cellClass);
            
            if (!identifier || !record.cellClass) {
                return nil;
            }
            
            [self registerIdentifier:identifier forCellClass:record.cellClass recordType:recordType];
            
            UICollectionReusableView *view = [self.collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:identifier forIndexPath:indexPath];
            
            if (!view) {
                @throw ([NSException exceptionWithName:kFSQIdentifierCellDequeueException 
                                                reason:[NSString stringWithFormat:@"Tried to dequeue supplementary view for kind %@ of class %@ for identifier %@, but failed. Delegate: %@", kind, record.cellClass, identifier, self.delegate]
                                              userInfo:nil]);
            }
            
            [self configureView:view withRecord:record recordType:recordType atIndexPath:indexPath];
            
            return view;
        }
        else {
            @throw ([NSException exceptionWithName:kFSQIdentifierCellDequeueException 
                                            reason:[NSString stringWithFormat:@"Missing record when trying to dequeue supplementary view for kind %@ at index path %@. Likely your delegate returned a non-zero size for an empty view. Delegate: %@", kind, indexPath, self.delegate]
                                          userInfo:nil]);
            return nil;
        }
    }
    else {
        NSAssert(0, @"Unrecognized table view in FSQCellManifest viewForSupplementaryElementOfKind:atIndexPath:");
        return nil;
    }
}

- (FSQIdentifierRegistrationResult)registerIdentifier:(NSString *)identifier forCellClass:(Class)cellClass recordType:(FSQCellRecordType)recordType {
    
    FSQIdentifierRegistrationResult result;
    
    switch (recordType) {
        case FSQCellRecordTypeBody:
            result = [super registerIdentifier:identifier forCellClass:cellClass recordType:recordType];
            break;
        case FSQCellRecordTypeHeader:
            result = [self registerIdentifier:identifier forCellClass:cellClass map:_headerIdentifierCellClassMap];
            break;
        case FSQCellRecordTypeFooter:
            result = [self registerIdentifier:identifier forCellClass:cellClass map:_footerIdentifierCellClassMap];
            break;
    }
    
    switch (result) {
        case FSQIdentifierRegistrationResultAlreadyExists:
            // do nothing
            break;
        case FSQIdentifierRegistrationResultAdded:
        {            
            switch (recordType) {
                case FSQCellRecordTypeBody:
                    [self.collectionView registerClass:cellClass forCellWithReuseIdentifier:identifier];
                    break;
                case FSQCellRecordTypeHeader:
                    [self.collectionView registerClass:cellClass forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:identifier];
                    break;
                case FSQCellRecordTypeFooter:
                    [self.collectionView registerClass:cellClass forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:identifier];
                    break;
            }
        }
            break;
        case FSQIdentifierRegistrationResultConflictingExistingType:
        {
            @throw ([NSException exceptionWithName:kFSQIdentifierClassMismatchException 
                                            reason:[NSString stringWithFormat:@"Tried to register class %@ for identifier %@, but a different class was already registered. Delegate: %@", cellClass, identifier, self.delegate]
                                          userInfo:nil]);
        }
    }
    return result;
}

#pragma mark - Collection View Delegate Methods -

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.collectionView) {
        FSQCellRecord *record = [self cellRecordAtIndexPath:indexPath];
        
        CGSize maxSize = [self maxSizeForRecord:record atIndexPath:indexPath defaultWidth:CGFLOAT_MAX defaultHeight:CGFLOAT_MAX];
        
        if ([self.delegate respondsToSelector:@selector(sizeForCellAtIndexPath:withManifest:record:maximumSize:)]) {
            return [self.delegate sizeForCellAtIndexPath:indexPath withManifest:self record:record maximumSize:maxSize];
        }
        else if ([record.cellClass conformsToProtocol:@protocol(FSQCellManifestCollectionViewCellProtocol)]) {
            return [record.cellClass manifest:self sizeForModel:record.model maximumSize:maxSize indexPath:indexPath record:record];
        }
        else {
            return CGSizeZero;
        }     
    }
    else {
        return CGSizeZero;
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.collectionView) {
        return [self recordShouldHighlightAtIndexPath:indexPath];        
    }
    else {
        return NO;
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.collectionView) {
        return [self recordShouldSelectAtIndexPath:indexPath];    
    }
    else {
        return NO;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.collectionView) {
        FSQCellRecord *record = [self cellRecordAtIndexPath:indexPath];
        
        [self withEachPluginAndDelegate:^(id delegate) {
            if ([delegate respondsToSelector:@selector(manifest:willSelectCellAtIndexPath:withRecord:)]) {
                [delegate manifest:self willSelectCellAtIndexPath:indexPath withRecord:record];
            }
        }];
        
        if (record.onSelection) {
            record.onSelection(indexPath, self, record);
        }
        
        [self withEachPluginAndDelegate:^(id delegate) {
            if ([delegate respondsToSelector:@selector(manifest:didSelectCellAtIndexPath:withRecord:)]) {
                [delegate manifest:self didSelectCellAtIndexPath:indexPath withRecord:record];
            }
        }]; 
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (collectionView == self.collectionView) {
        FSQCellRecord *record = [self sectionRecordAtIndex:section].header;
        if ([record.cellClass conformsToProtocol:@protocol(FSQCellManifestCollectionViewCellProtocol)]) {
            CGSize maxSize = [self maxSizeForRecord:record atIndexPath:nil defaultWidth:CGFLOAT_MAX defaultHeight:CGFLOAT_MAX];
            return [record.cellClass manifest:self sizeForModel:record.model maximumSize:maxSize indexPath:[NSIndexPath indexPathForItem:kRowIndexForHeaderIndexPaths inSection:section] record:record];
        }
        
        return CGSizeZero;
    }
    
    return collectionViewLayout.headerReferenceSize;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    if (collectionView == self.collectionView) {
        FSQCellRecord *record = [self sectionRecordAtIndex:section].footer;
        if ([record.cellClass conformsToProtocol:@protocol(FSQCellManifestCollectionViewCellProtocol)]) {
            CGSize maxSize = [self maxSizeForRecord:record atIndexPath:nil defaultWidth:CGFLOAT_MAX defaultHeight:CGFLOAT_MAX];
            return [record.cellClass manifest:self sizeForModel:record.model maximumSize:maxSize indexPath:[NSIndexPath indexPathForItem:kRowIndexForFooterIndexPaths inSection:section] record:record];
        }
    }
    
    return collectionViewLayout.footerReferenceSize; 
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    
    if (collectionView == self.collectionView) {
        FSQSectionRecord *record = [self sectionRecordAtIndex:section];
        if (record.collectionViewSectionInsetPrivate) {
            return record.collectionViewSectionInset;
        }
    }
    
    if ([collectionViewLayout respondsToSelector:@selector(sectionInset)]) {
        return ((UICollectionViewFlowLayout *)collectionViewLayout).sectionInset;
    }
    else {
        return UIEdgeInsetsZero;
    }   
}


@end

#pragma mark End Collection View Manifest -

#pragma mark - Begin Message Forwarder Implementations

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wprotocol"
@implementation FSQMessageForwarder (FSQManifestAdditions)
@end
#pragma clang diagnostic pop

@implementation FSQCellManifestMessageForwarderEnumerator {
    NSMutableArray *_manifestPlugins;
}

- (instancetype)init {
    if ((self = [super init])) {
        _messageForwarder = [FSQMessageForwarderWithEnumerator new];
        _messageForwarder.enumeratorGenerator = self;
        _manifestPlugins = [NSMutableArray new];
    }
    return self;
}


- (void)addPlugins:(NSArray *)newPlugins {
    [_manifestPlugins addObjectsFromArray:newPlugins];
}

- (void)removePlugins:(NSArray *)pluginsToRemove {
    [_manifestPlugins removeObjectsInArray:pluginsToRemove];
}

- (NSEnumerator *)childrenEnumeratorForMessageForwarder:(FSQMessageForwarder *)forwarder {
    _currentIndex = 0;
    return self;
}

- (id)nextObject {
    NSInteger index = _currentIndex;
    
    if (_manifest) {
        if (index == 0) {
            _currentIndex++;
            return self.manifest;
        }
        
        // Offset index minus one so it lines up with the plugin array index
        --index;
    }
    
    if (index < _manifestPlugins.count) {
        _currentIndex++;
        return _manifestPlugins[index];
    }
    else if (index == _manifestPlugins.count
             && _manifestDelegate) {
        _currentIndex++;
        return _manifestDelegate;
    }
    else {
        return nil;
    }
}

- (NSArray *)allObjects {
    NSMutableArray *allObjects = [NSMutableArray new];
    
    if (_manifest) {
        [allObjects addObject:_manifest];
    }
    
    if (_manifestPlugins.count > 0) {
        [allObjects addObjectsFromArray:_manifestPlugins];
    }
    
    if (_manifestDelegate) {
        [allObjects addObject:_manifestDelegate];
    }
    
    if (allObjects.count > 0) {
        return [allObjects copy];
    }
    else {
        return nil;
    }
}

@end

#pragma mark End Message Forwarder Implementations -
