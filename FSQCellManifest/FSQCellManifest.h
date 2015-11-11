//
//  FSQCellManifest.h
//
//  Copyright (c) 2015 Foursquare. All rights reserved.
//

@import UIKit;

#import "FSQCellManifestProtocols.h"
#import "FSQCellRecord.h"
#import "FSQSectionRecord.h"

/**
 You can pass one of the following selection strategies to the manifest when fully replacing the existing
 set of section records. It is used to determine what it should do about any already selected cells.
 
 If there are no selected cells when you set new section records, then the strategy is not used.
 */
typedef NS_ENUM(NSInteger, FSQViewReloadCellSelectionStrategy) {
    
    /**
     All existing selected cells will be deselected.
     */
    FSQViewReloadCellSelectionStrategyDeselectAll,
    
    /**
     The manifest will attempt to re-select the new cell records at the index paths that were previously selected.
     Selection blocks and delegate callbacks will not be called.
     */
    FSQViewReloadCellSelectionStrategyMaintainSelectedIndexPaths,
    
    /**
     The manifest will attempt to re-select the same cell records that were previously selected, even if they have
     changed positions in the table. Records are compared using isEqualToCellRecord:
     
     Selection blocks and delegate callbacks will not be called.
     
     @note This strategy is more expensive than the other ones. It you need this, it is recommended you 
     use insert/move/replace/remove methods instead of replacing the entire array of section records when possible.
     */
    FSQViewReloadCellSelectionStrategyMaintainSelectedRecords,
};

/**
 Methods about headers which include an indexPath will use this value for the row index.
 
 You can use this to distinguish header index paths from footer or normal cell paths.
 */
extern const NSInteger kRowIndexForHeaderIndexPaths;

/**
 Methods about footers which include an indexPath will use this value for the row index.
 
 You can use this to distinguish footer index paths from header or normal cell paths.
 */
extern const NSInteger kRowIndexForFooterIndexPaths;

@interface FSQCellManifest : NSObject <NSFastEnumeration, UIScrollViewDelegate>

/**
 Will be either the table or collection view managed by this manifest if you are using one of those subclasses.
 
 Otherwise will be nil.
 
 Useful for generic accessing where you do not care about which type of view the manifest is managing, or you want
 to manually inspect the type.
 */
@property (nonatomic, weak, readonly) UIScrollView *managedView;

/**
 An optional delegate that can receive callbacks from the manifest. The callbacks will be received after any plugins.
 
 The delegate can implement methods from any of the following protocols to get the corresponding callbacks:
 * FSQCellManifestRecordModificationDelegate
 * FSQCellManifestRecordSizingDelegate
 * FSQCellManifestRecordConfigurationDelegate
 * FSQCellManifestRecordSelectionDelegate
 * UIScrollViewDelegate
 * UITableViewDelegate (only for FSQTableViewCellManifest)
 * UITableViewDataSource (only for FSQTableViewCellManifest)
 * UICollectionViewDelegate (only for FSQCollectionViewCellManifest)
 * UICollectionViewDelegateFlowLayout (only for FSQCollectionViewCellManifest)
 * UICollectionViewDataSource (only for FSQCollectionViewCellManifest)
 
 If the methods have a return value and the message is not implemented by the manifest, the return value of the first
 delegate or plugin to respond will be used. Delegates who wish to have their return values
 override this behavior should implement FSQMessageForwardee's shouldUseResponseForInvocation:
 */
@property (nonatomic, weak) id delegate;

/**
 An array of plugins to receive callbacks from the manifest.
 
 The intention of the plugin pattern is to give the ability to add extra functionality to the manifest without
 needing to separately subclass the table and collection view versions, copying code between each. Individual users of 
 the manifest should generally not be creating new plugins every time. It should be treated more like making
 a new subclass.
 
 Each plugin in the array will get the method callbacks in order, giving them a chance to do extra work
 whenever the manifest does an action. Callbacks will be sent in order to items in the array. If the manifest has
 a delegate, it will receive the callbacks last.
 
 Plugins can implement methods from any of the following protocols to get the corresponding callbacks:
 * FSQCellManifestPlugin
 * FSQCellManifestRecordModificationDelegate
 * FSQCellManifestRecordConfigurationDelegate
 * FSQCellManifestRecordSelectionDelegate
 * UIScrollViewDelegate
 * UITableViewDelegate (only for FSQTableViewCellManifest)
 * UITableViewDataSource (only for FSQTableViewCellManifest)
 * UICollectionViewDelegate (only for FSQCollectionViewCellManifest)
 * UICollectionViewDelegateFlowLayout (only for FSQCollectionViewCellManifest)
 * UICollectionViewDataSource (only for FSQCollectionViewCellManifest)
 
 If the methods have a return value and the message is not implemented by the manifest, the return value of the first
 delegate or plugin to respond will be used. Plugins who wish to have their return values
 override this behavior should implement FSQMessageForwardee's shouldUseResponseForInvocation:
 
 To alter the items in this array, pass them into the manifest's init method, or use addPlugins: and/or removePlugins:
 
 @note A strong reference is retained to the objects.
 */
@property (nonatomic, readonly) NSArray *plugins;

/**
 An array of FSQSectionRecord objects that represent the invididual sections in a table view or collection view.
 Setting this property is equivalent to calling `setSectionRecords:selectionStrategy:`
 with a selection strategy of FSQViewReloadCellSelectionStrategyDeselectAll.
 */
@property (nonatomic) NSArray<FSQSectionRecord *> *sectionRecords;

/**
 Controls whether the manifest methods that alter its records will automatically call through to the
 appropriate methods on its managed table or collection view to render the update.
 
 You can set this to NO if you intend to immediately update the managed view yourself after calling the 
 manifest's methods.
 
 Defaults to YES.
 
 @note Also see: performRecordModificationUpdatesWithoutUpdatingManagedView:
 */
@property (nonatomic, assign) BOOL automaticallyUpdateManagedView;

/**
 Controls whether or not cells should be selectable and highlightable if there is 
 no selectBlock and allows[Highlighting/Selection] hasn't been manually overwritten.
 */
@property (nonatomic, assign) BOOL cellSelectionEnabledByDefault;

/**
 Add plugins to the plugins array in order, after any existing plugins.
 */
- (void)addPlugins:(NSArray *)plugins;

/**
 Remove plugins from the plugins array.
 */
- (void)removePlugins:(NSArray *)plugins;

/**
 Designated initializer for FSQCellManifest.
 
 You normally will want to use the initializer for FSQTableViewCellManifest or FSQCollectionViewCellManifest
 instead of this method.
 
 @param delegate Option delegate for the manifest.
 @param plugins  Optional array of manifest plugins.
 
 @return A new FSQCellManifest instance.
 */
- (instancetype)initWithDelegate:(id)delegate 
                         plugins:(NSArray *)plugins;

/**
 Allows you to do batch updates on the manifest's managed view.
 
 If this is a table view manifest, your updates block will be wrapped in beginUpdates and endUpdates calls.
 
 If this is a collection view manifest, your updates block will be passed to performBatchUpdates:completion:
 */
- (void)performBatchRecordModificationUpdates:(void (^)(void))updates;

/**
 Allows you to do make record modification calls without the manifest calling through to its managed view
 to render the updates.
 
 If you use this method, you are responsible for updating the managed view properly.
 
 @note If you change the value of the automaticallyUpdateManagedView property in the updates block, the behavior
       of this method is undefined.
 */
- (void)performRecordModificationUpdatesWithoutUpdatingManagedView:(void (^)(void))updates;

/**
 Replace the existing array of section records with the passed in array.
 
 This method will automatically call reloadData on the table or collection view it is managing after applying
 the new records. If you do not want this behavior, see `performRecordModificationUpdatesWithoutUpdatingManagedView`.

 @param sectionRecords    An array of FSQSectionRecord objects. The array will be copied.
 @param selectionStrategy A hint to the manifest on what to do with any existing selected rows.
 */
- (void)setSectionRecords:(NSArray<FSQSectionRecord *> *)sectionRecords
        selectionStrategy:(FSQViewReloadCellSelectionStrategy)selectionStrategy;

/**
 Accessor for getting individual section records.
 
 @param index The index of the record you want.
 
 @return The section record at that index, or nil if the index is out of bounds.
 */
- (FSQSectionRecord *)sectionRecordAtIndex:(NSInteger)index;

/**
 Accessor for getting individual cell records.
 
 @param indexPath The index path of the record you want.
 
 @return The section record at that index, or nil if the index path is out of bounds.
 */
- (FSQCellRecord *)cellRecordAtIndexPath:(NSIndexPath *)indexPath;

/**
 Accessor for the getting the current number of sections.
 
 @return Current number of section records managed by this manifest.
 */
- (NSInteger)numberOfSectionRecords;

/**
 Accessor for the getting the current number of cell records in a section.
 
 @param index The index of the section you are interested in.
 
 @return The number of cell records in the specified section.
 */
- (NSInteger)numberOfCellRecordsInSectionAtIndex:(NSInteger)index;

/**
 Insert new cell records in order starting at the given index path without animation.
 
 This method will automatically call the appropriate methods on its table or collection view to show the new cells.
 If you do not want this behavior, see `performRecordModificationUpdatesWithoutUpdatingManagedView`.
 
 @param cellRecords An array of FSQCellRecord objects.
 @param indexPath   The index path that the first new record should be inserted at. 
 The section index of this index path must  be less than numberOfSectionRecords (i.e. an existing section).
 and the row or item index must be less than or equal to the number of cell records in that section.
 
 @return An array of NSIndexPaths of the newly inserted cellRecords.
 */
- (NSArray<NSIndexPath *> *)insertCellRecords:(NSArray<FSQCellRecord *> *)cellRecords 
                                  atIndexPath:(NSIndexPath *)indexPath;

/**
 Insert new section records in order starting at the given index without animation.
 
 This method will automatically call the appropriate methods on its table or collection view to show the new sections. 
 If you do not want this behavior, see `performRecordModificationUpdatesWithoutUpdatingManagedView`.
 
 @param sectionRecords An array of FSQSectionRecord objects.
 @param index          The index that the first new record should be inserted at.
 This index must be less than or equal to the number of section records.
 
 @return An index set containing the indexes of the newly inserted sectionRecords.
 */
- (NSIndexSet *)insertSectionRecords:(NSArray<FSQSectionRecord *> *)sectionRecords 
                             atIndex:(NSInteger)index;

/**
 Move a cell record at one index path to another.
 
 This method will automatically call the appropriate methods on its table or collection view to show the move.
 If you do not want this behavior, see `performRecordModificationUpdatesWithoutUpdatingManagedView`.
 
 @param initialIndexPath The index path of the cell to move. This must be a valid existing index path.
 @param targetIndexPath  The index path that the cell should end up at. The section index of the index path must
 reference a valid existing section. The row or item index must be no greater than the number of cell records in
 the section AFTER the record at initialIndexPath is removed.
 
 @return YES if the records were successfully moved, NO if one or both of the index paths were invalid.
 */
- (BOOL)moveCellRecordAtIndexPath:(NSIndexPath *)initialIndexPath 
                      toIndexPath:(NSIndexPath *)targetIndexPath;

/**
 Move a section record at one index to another.
 
 This method will automatically call the appropriate methods on its table or collection view to show the move.
 If you do not want this behavior, see `performRecordModificationUpdatesWithoutUpdatingManagedView`.
 
 @param initialIndex The index of the section to move. This must be a valid existing section index.
 @param targetIndex  The index that the section should end up at. This must be a valid existing index.
 
 @return YES if the records were successfully moved, NO if one or both of the indexes were invalid.
 */
- (BOOL)moveSectionRecordAtIndex:(NSInteger)initialIndex 
                         toIndex:(NSInteger)targetIndex;

/**
 Remove cell records at the specified index paths.
 
 This method will automatically call the appropriate methods on its table or collection view to show the removals.
 If you do not want this behavior, see `performRecordModificationUpdatesWithoutUpdatingManagedView`.
 
 @param indexPaths                  An array of NSIndexPath objects of rows to remove. 
                                    Any invalid index paths will be ignored.
 @param shouldRemoveEmptySections   If YES, when all cells in a section would be removed, than that section is 
                                    removed instead.
 
 @return An array of NSIndexPath objects that were actually removed. It does not include any invalid index paths.
 It also does not include any index paths in a section that was entirely removed if shouldRemoveEmptySections is YES.
 */
- (NSArray<NSIndexPath *> *)removeCellRecordsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths 
                                      removeEmptySections:(BOOL)shouldRemoveEmptySections;

/**
 Remove sections at the specified indexes.
 
 This method will automatically call the appropriate methods on its table or collection view to show the removals.
 If you do not want this behavior, see `performRecordModificationUpdatesWithoutUpdatingManagedView`.
 
 @param indexes An set of indexes to remove. All indexes must be valid section indexes or none will be removed.
 
 @return YES if sections were removed. NO if any of the indexes were invalid.
 */
- (BOOL)removeSectionRecordsAtIndexes:(NSIndexSet *)indexes;

/**
 Replace cell records with a different records.
 
 This method will automatically call the appropriate methods on its table or collection view to show the replacement.
 If you do not want this behavior, see `performRecordModificationUpdatesWithoutUpdatingManagedView`.
 
 @param indexPaths     An array of NSIndexPaths to existing cell records to replace. 
                       Any invalid index paths will not be replaced.
 @param newCellRecords An array of cell records to replace the existing records with. The size of this array must
                       be equal to the size of indexPaths
 
 @return The actual array of index paths that were replaced, not including any invalid paths.
 */
- (NSArray<NSIndexPath *> *)replaceCellRecordsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths 
                                           withCellRecords:(NSArray<FSQCellRecord *> *)newCellRecords;

/**
 Replace section records with different records.
 
 This method will automatically call the appropriate methods on its table or collection view to show the replacement.
 If you do not want this behavior, see `performRecordModificationUpdatesWithoutUpdatingManagedView`.
 
 @param indexes           An array of NSNumber-boxed NSIntegers of existing section record indexes to replace. 
                          Any invalid indexes will not be replaced.
 @param newSectionRecords An array of section records to replace the existing records with. The size of this array
                          must be equal to the number of indexes.
 
 @return A set of indexes that were actually replaced, not including any invalid indexes.
 */
- (NSIndexSet *)replaceSectionRecordsAtIndexes:(NSArray *)indexes 
                            withSectionRecords:(NSArray<FSQSectionRecord *> *)newSectionRecords;

/**
 Does either tableView or collectionView reload data method as appropriate and informs manifest delegates and plugins.
 
 Does not update any records.
 
 You should use this method instead of calling reload on your managed view directly.
 */
- (void)reloadManagedView;

/**
 Calls appropriate method on managed view to reload the specified index paths and informs manifest 
 delegates and plugins. 
 
 Does not update any records.
 
 You should use this method instead of calling reload on your managed view directly.
 
 @param indexPaths Index paths of cells to reload.
 */
- (void)reloadCellsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;

/**
 Calls appropriate method on managed view to reload the specified indexes and informs manifest delegates and plugins. 
 
 Does not update any records.
 
 You should use this method instead of calling reload on your managed view directly.

 @param indexes Indexes of sections to reload.
 */
- (void)reloadSectionsAtIndexes:(NSIndexSet *)indexes;

/**
 Will return you either indexPath.row or indexPath.item depending on whether this is a table or collection 
 view manifest.
 */
- (NSInteger)rowOrItemIndexForIndexPath:(NSIndexPath *)indexPath;

/**
 Creates an indexPath using either indexPathForRow:inSection: or indexPathForItem:inSection: depending on whether this 
 is a table or collection view manifest.
 */
- (NSIndexPath *)indexPathForRowOrItem:(NSInteger)rowOrItem inSection:(NSInteger)section;

/**
 Will tell you whether the record at the specified index path is able to be highlighted, based on the 
 current manifest configuration
 
 The corresponding UIKit delegate callback for this method is handled for you, but if you would like to know this
 data for your own purposes you can call this method.
 
 @param indexPath Index path which you would like to know about.
 
 @return YES if the record can highlight, NO if it cannot.
 */
- (BOOL)recordShouldHighlightAtIndexPath:(NSIndexPath *)indexPath;

/**
 Will tell you whether the record at the specified index path is able to be selected, based on the 
 current manifest configuration
 
 The corresponding UIKit delegate callback for this method is handled for you, but if you would like to know this
 data for your own purposes you can call this method.
 
 @param indexPath Index path which you would like to know about.
 
 @return YES if the record can be selected, NO if it cannot.
 */
- (BOOL)recordShouldSelectAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface FSQTableViewCellManifest : FSQCellManifest <UITableViewDataSource, UITableViewDelegate>

/**
 The table view this manifest is managing.
 */
@property (nonatomic, weak) UITableView *tableView;

/**
 Create a new manifest meant to manage a table view.
 
 @param delegate  Optional delegate to receive callbacks.
 @param plugins   Optional array of plugin delegates.
 @param tableView Optional table view to manage. You may assign or change the table view later through the
 exposed property if it is not available when creating the manifest.
 
 @return A new table view cell manifest.
 */
- (instancetype)initWithDelegate:(id)delegate 
                         plugins:(NSArray *)plugins
                       tableView:(UITableView *)tableView;

/**
 Insert new cell records in order at the given index path with a table view row animation.
 
 This method is identical to insertCellRecords:atIndexPath: except that the new rows will be inserted 
 with the given animation.
 
 @param cellRecords An array of FSQCellRecord objects
 @param indexPath   The index path that the first new record should be inserted at. 
 The section index of this index path must  be less than numberOfSectionRecords (i.e. an existing section).
 and the row or item index must be less than or equal to the number of cell records in that section.
 @param animation   The animation to use for inserting the cells into the table view.
 
 @return An array of NSIndexPaths of the newly inserted cellRecords
 */
- (NSArray<NSIndexPath *> *)insertCellRecords:(NSArray<FSQCellRecord *> *)cellRecords 
                                  atIndexPath:(NSIndexPath *)indexPath 
                                withAnimation:(UITableViewRowAnimation)animation;

/**
 Insert new section records in order starting at the given index with a table view row animation.
 
 This method is identical to insertSectionRecords:atIndex: except that the new rows will be inserted 
 with the given animation.
 
 @param sectionRecords An array of FSQSectionRecord objects.
 @param index          The index that the first new record should be inserted at.
 This index must be less than or equal to the number of section records.
 @param animation      The animation to use for inserting the sections into the table view.
 
 @return An index set containing the indexes of the newly inserted sectionRecords.
 */
- (NSIndexSet *)insertSectionRecords:(NSArray<FSQSectionRecord *> *)sectionRecords 
                             atIndex:(NSInteger)index
                       withAnimation:(UITableViewRowAnimation)animation;

/**
 Remove cell records at the specified index paths.
 
 This method is identical to removeCellRecordsAtIndexPaths:removeEmptySections: except that the rows will be removed 
 with the given animation.
 
 @param indexPaths                  An array of NSIndexPath objects of rows to remove. 
                                    Any invalid index paths will be ignored.
 @param shouldRemoveEmptySections   If YES, when all cells in a section would be removed, than that section is 
                                    removed instead.
 
 @return An array of NSIndexPath objects that were actually removed. It does not include any invalid index paths.
 It also does not include any index paths in a section that was entirely removed if shouldRemoveEmptySections is YES.
 */
- (NSArray<NSIndexPath *> *)removeCellRecordsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths 
                                            withAnimation:(UITableViewRowAnimation)animation 
                                      removeEmptySections:(BOOL)shouldRemoveEmptySections;

/**
 Remove sections at the specified indexes.
 
 This method is identical to removeSectionRecordsAtIndexes: except that the rows will be removed 
 with the given animation.
 
 @param indexes An set of indexes to remove. All indexes must be valid section indexes or none will be removed.
 
 @return YES if sections were removed. NO if any of the indexes were invalid.
 */
- (BOOL)removeSectionRecordsAtIndexes:(NSIndexSet *)indexes 
                        withAnimation:(UITableViewRowAnimation)animation;

/**
 Replace cell records with a different records with a table view row animation.
 
 This method is identical to replaceCellRecordsAtIndexPaths:withCellRecords: except that the rows will be replaced 
 with the given animation.
 
 @param indexPaths     An array of NSIndexPaths to existing cell records to replace. 
 Any invalid index paths will not be replaced.
 @param newCellRecords An array of cell records to replace the existing records with. The size of this array must
 be equal to the size of indexPaths
 @param animation      The animation to use for reloading the replaced cells.
 
 @return The actual array of index paths that were replaced, not including any invalid paths.
 */
- (NSArray<NSIndexPath *> *)replaceCellRecordsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths 
                                           withCellRecords:(NSArray<FSQCellRecord *> *)newCellRecords
                                             withAnimation:(UITableViewRowAnimation)animation;

/**
 Replace section records with different records with a table view row animation.
 
 This method is identical to replaceSectionRecordsAtIndexes:withSectionRecords: except that the sections will be 
 replaced with the given animation.
 
 @param indexes           An array of NSNumber-boxed NSIntegers of existing section record indexes to replace. 
 Any invalid indexes will not be replaced.
 @param newSectionRecords An array of section records to replace the existing records with. The size of this array
 must be equal to the number of indexes.
 @param animation      The animation to use for reloading the replaced sections.
 
 @return A set of indexes that were actually replaced, not including any invalid indexes.
 */
- (NSIndexSet *)replaceSectionRecordsAtIndexes:(NSArray *)indexes 
                            withSectionRecords:(NSArray<FSQSectionRecord *> *)newSectionRecords
                                 withAnimation:(UITableViewRowAnimation)animation;

/**
 Calls appropriate method on managed view to reload the specified index paths and informs manifest 
 delegates and plugins. 
 
 This method is identical to reloadCellsAtIndexPaths: except that the rows will be reloaded 
 with the given animation.
 
 You should use this method instead of calling reload on your managed view directly.
 
 @param indexPaths Index paths of cells to reload.
 */
- (void)reloadCellsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths 
                  withAnimation:(UITableViewRowAnimation)animation;

/**
 Calls appropriate method on managed view to reload the specified indexes and informs manifest delegates and plugins. 
 
 This method is identical to reloadSectionsAtIndexes: except that the sections will be reloaded 
 with the given animation.
 
 You should use this method instead of calling reload on your managed view directly.
 
 @param indexes Indexes of sections to reload.
 */
- (void)reloadSectionsAtIndexes:(NSIndexSet *)indexes 
                  withAnimation:(UITableViewRowAnimation)animation;


// The following table view delegate and data source methods are implemented by the manifest
// and so any subclasses must call super on these to get correct behavior.

// Delegate methods
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath NS_REQUIRES_SUPER;
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section NS_REQUIRES_SUPER;
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section NS_REQUIRES_SUPER;
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section NS_REQUIRES_SUPER;
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section NS_REQUIRES_SUPER;
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath NS_REQUIRES_SUPER;
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath NS_REQUIRES_SUPER;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath NS_REQUIRES_SUPER;

// Data source methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView NS_REQUIRES_SUPER;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section NS_REQUIRES_SUPER;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath NS_REQUIRES_SUPER;

@end

@interface FSQCollectionViewCellManifest : FSQCellManifest <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

/**
 The collection view this manifest is managing.
 */
@property (nonatomic, weak) UICollectionView *collectionView;

/**
 Create a new manifest meant to manage a collection view.
 
 @param delegate       Optional delegate to receive callbacks.
 @param collectionView Optional collection view to manage. You may assign or change the table view later through the
 exposed property if it is not available when creating the manifest.
 
 @return A new collection view cell manifest.
 */
- (instancetype)initWithDelegate:(id)delegate 
                         plugins:(NSArray *)plugins
                  collectionView:(UICollectionView *)collectionView;


// The following collection view delegate and data source methods are implemented by the manifest
// and so any subclasses must call super on these to get correct behavior.

// Delegate methods
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView NS_REQUIRES_SUPER;
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section NS_REQUIRES_SUPER;
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath NS_REQUIRES_SUPER;
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath NS_REQUIRES_SUPER;
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section NS_REQUIRES_SUPER;

// Data source methods
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath NS_REQUIRES_SUPER;
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath NS_REQUIRES_SUPER;
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath NS_REQUIRES_SUPER;

@end
