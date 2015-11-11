//
//  FSQCellManifestProtocols.h
//
//  Copyright (c) 2015 Foursquare. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FSQCellRecord, FSQSectionRecord, FSQCellManifest, FSQTableViewCellManifest, FSQCollectionViewCellManifest;

/**
 This block type is used for FSQCellRecord onConfigure blocks.
 
 This block property is called when a cell is dequeued, after the cell's own configureWithModel: method is called,
 but before the manifest's plugin or delegate callbacks are called.
 
 You can set this block on an FSQCellRecord to do extra customization of the cell after it gets dequeued.
 Make sure that any values you change here are reset in another configure method or block or incorrect
 data may be displayed due to cell reuse.
 
 @param cell      The view that was dequeued.
 @param indexPath The index path this view will be displayed at.
 @param manifest  The manifest that dequeued this view.
 @param record    The record associated with this view.
 
 @see onConfigure
 @see manifest:configureWithModel:indexPath:record:
 @see FSQCellManifestRecordConfigurationDelegate
 */
typedef void (^FSQCellRecordConfigBlock)(id cell, NSIndexPath *indexPath, FSQCellManifest *manifest, FSQCellRecord *record);

/**
 This block type is used for FSQCellRecord onSelection blocks.
 
 This block property is called when a cell is selected in the table or collection view.
 
 You can set this block on a FSQCellRecord to do an action when the cell is selected. Alternatively if many
 cells in the view do the same or similar code when selected, you may want to use 
 FSQCellManifestRecordSelectionDelegate methods.
 
 
 @param indexPath The index path of the cell that was selected.
 @param manifest  The manifest managing the selected cell.
 @param record    The record associated with the selected cell.
 
 @see onSelection
 @see FSQCellManifestRecordSelectionDelegate
 */
typedef void (^FSQCellRecordSelectBlock)(NSIndexPath *indexPath, FSQCellManifest *manifest, FSQCellRecord *record);

@protocol FSQCellManifestCellProtocol <NSObject>
/**
 This method will be called on the view when it is dequeued from the table or collection view.
 
 The view should use the passed in model object to set its own views and attributes. Any part of the cell that can be
 changed should be set or reset to a new value so that old values are not used during cell reuse.
 
 @param manifest  The manifest dequeueing this view.
 @param model     The model from the FSQCellRecord. You should change the type of this parameter from id to the actual
 type of your model.
 @param indexPath The indexPath that this view will be displayed at.
 @param record    The cell record for this view.
 
 @see onConfigure
 @see FSQCellManifestRecordConfigurationDelegate
 */
- (void)manifest:(FSQCellManifest *)manifest configureWithModel:(id)model indexPath:(NSIndexPath *)indexPath record:(FSQCellRecord *)record;
@end

@protocol FSQCellManifestTableViewCellProtocol <FSQCellManifestCellProtocol>

/**
 This method will be called on each cell class in a table view manifest to determine the height of the cell to report
 to UITableView.
 
 The class should use the passed in model object to determine the height an instance of itself rendering that model
 will be.
 
 Your cell will end up being the height you return from this method. You should make sure your height calculation
 here matches any layout code you have for the view.
 
 @param manifest    The manifest asking for the view's height.
 @param model       The model that will be rendered in a dequeued instance of your class.
 @param maximumSize The maximum size your view should be. You can return a value larger than maximumSize.height but
 your view may then render incorrectly. You should use maximumSize.width as the width constraint
 for any height calculations.
 @param indexPath   The index path this model and class will be displayed at.
 @param record      The cell record associated with this model/class/indexPath
 
 @return The height a cell rendering the given model should be created with.
 
 @see defaultMaximumCellSizeForManifest:
 @see maximumSizeForCellAtIndexPath:withManifest:record:
 @see sizeForCellAtIndexPath:withManifest:record:maximumSize:
 */
+ (CGFloat)manifest:(FSQTableViewCellManifest *)manifest heightForModel:(id)model maximumSize:(CGSize)maximumSize indexPath:(NSIndexPath *)indexPath record:(FSQCellRecord *)record;
@end

@protocol FSQCellManifestCollectionViewCellProtocol  <FSQCellManifestCellProtocol>

/**
 This method will be called on each cell class in a collection view manifest to determine the height of the cell to 
 report to UICollectionView.
 
 The class should use the passed in model object to determine the size an instance of itself rendering that model
 will be.
 
 Your cell will end up being the size you return from this method. You should make sure your size calculation
 here matches any layout code you have for the view.
 
 @param manifest    The manifest asking for the view's size.
 @param model       The model that will be rendered in a dequeued instance of your class.
 @param maximumSize The maximum size your view should be. You can return a value larger than maximumSize but
 your view may then render incorrectly. Depdending on your collection view's layout, you may
 want to use maximumSize.width or .height as a constraint used to calculate the size of the other.
 @param indexPath   The index path this model and class will be displayed at.
 @param record      The cell record associated with this model/class/indexPath
 
 @return The size a cell rendering the given model should be created as.
 
 @see defaultMaximumCellSizeForManifest:
 @see maximumSizeForCellAtIndexPath:withManifest:record:
 @see sizeForCellAtIndexPath:withManifest:record:maximumSize:
 
 */
+ (CGSize)manifest:(FSQCollectionViewCellManifest *)manifest sizeForModel:(id)model maximumSize:(CGSize)maximumSize indexPath:(NSIndexPath *)indexPath record:(FSQCellRecord *)record;
@end

/**
 This protocol contains callbacks that will inform the delegate when its records are inserted/moved/replaced/removed.
 and when the managed view receives calls to change the records it is rendering.
 
 A "will" call is _always_ followed by the correspding "did" call.
 
 Each set of callbacks corresponds to a method on FSQCellManifest and only one set of will be sent per-manifest method.
 E.g. even though `setSectionRecords` both replaces section records _and_ may reload the managed view, you will only
 receive the [will/did]ReplaceSectionRecords callbacks.
 */
@protocol FSQCellManifestRecordModificationDelegate <NSObject>
@optional
- (void)manifest:(FSQCellManifest *)manifest willReplaceSectionRecords:(NSArray<FSQSectionRecord *> *)currentSectionRecords withRecords:(NSArray<FSQSectionRecord *> *)newSectionRecords;
- (void)manifest:(FSQCellManifest *)manifest didReplaceSectionRecords:(NSArray<FSQSectionRecord *> *)oldSectionRecords withRecords:(NSArray<FSQSectionRecord *> *)currentSectionRecords;

- (void)manifestWillReloadManagedView:(FSQCellManifest *)manifest;
- (void)manifestDidReloadManagedView:(FSQCellManifest *)manifest;

- (void)manifest:(FSQCellManifest *)manifest willInsertCellRecords:(NSArray<FSQCellRecord *> *)cellRecords atIndexPath:(NSIndexPath *)indexPath;
- (void)manifest:(FSQCellManifest *)manifest didInsertCellRecords:(NSArray<FSQCellRecord *> *)cellRecords atIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;

- (void)manifest:(FSQCellManifest *)manifest willMoveCellRecordAtIndexPath:(NSIndexPath *)initialIndexPath toIndexPath:(NSIndexPath *)targetIndexPath;
- (void)manifest:(FSQCellManifest *)manifest didMoveCellRecordAtIndexPath:(NSIndexPath *)initialIndexPath toIndexPath:(NSIndexPath *)targetIndexPath;

- (void)manifest:(FSQCellManifest *)manifest willReplaceCellRecordsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRecords:(NSArray<FSQCellRecord *> *)cellRecords;
- (void)manifest:(FSQCellManifest *)manifest didReplaceCellRecordsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRecords:(NSArray<FSQCellRecord *> *)newCellRecords replacedRecords:(NSArray<FSQCellRecord *> *)originalCellRecords;

- (void)manifest:(FSQCellManifest *)manifest willRemoveCellRecordsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths removingEmptySections:(BOOL)willRemoveEmptySections;
- (void)manifest:(FSQCellManifest *)manifest didRemoveCellRecordsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths removedEmptySectionsAtIndexes:(NSIndexSet *)removedSections;

- (void)manifest:(FSQCellManifest *)manifest willReloadCellsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;
- (void)manifest:(FSQCellManifest *)manifest didReloadCellsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;

- (void)manifest:(FSQCellManifest *)manifest willInsertSectionRecords:(NSArray<FSQSectionRecord *> *)sectionRecords atIndex:(NSInteger)index;
- (void)manifest:(FSQCellManifest *)manifest didInsertSectionRecords:(NSArray<FSQSectionRecord *> *)sectionRecords atIndexes:(NSIndexSet *)indexes;

- (void)manifest:(FSQCellManifest *)manifest willMoveSectionRecordAtIndex:(NSInteger)initialIndex toIndex:(NSInteger)targetIndex;
- (void)manifest:(FSQCellManifest *)manifest didMoveSectionRecordAtIndex:(NSInteger)initialIndex toIndex:(NSInteger)targetIndex;

- (void)manifest:(FSQCellManifest *)manifest willReplaceSectionRecordsAtIndexes:(NSArray<NSNumber *> *)indexes withRecords:(NSArray<FSQSectionRecord *> *)sectionRecords;
- (void)manifest:(FSQCellManifest *)manifest didReplaceSectionRecordsAtIndexes:(NSArray<NSNumber *> *)indexes withRecords:(NSArray<FSQSectionRecord *> *)newSectionRecords replacedRecords:(NSArray<FSQSectionRecord *> *)originalSectionRecords;

- (void)manifest:(FSQCellManifest *)manifest willRemoveSectionRecordsAtIndexes:(NSIndexSet *)indexes;
- (void)manifest:(FSQCellManifest *)manifest didRemoveSectionRecordsAtIndexes:(NSIndexSet *)indexes;

- (void)manifest:(FSQCellManifest *)manifest willReloadSectionsAtIndexes:(NSIndexSet *)indexes;
- (void)manifest:(FSQCellManifest *)manifest didReloadSectionsAtIndexes:(NSIndexSet *)indexes;

@end

/**
 This protocol contains methods to override or supplement the behavior of record configuration
 */
@protocol FSQCellManifestRecordConfigurationDelegate <NSObject>
@optional

/**
 If implemented, your delegate will receive this callback when a cell is created or dequeued,
 before the cell's configureWithFSQCellRecordModel: method is called and also before
 the record's onConfigure block is called.
 
 Depending on your cells' design, it may be more appropriate to use a callback to do extra configuration globally
 for all cells in the manifest, instead of attaching an onConfigure block to each record.
 
 @param manifest   The manifest that is managing this cell.
 @param model      The model the cell will be configured with.
 @param cell       The cell that was created/dequeued. It will be a UITableViewCell or UICollectionViewCell subclass.
 @param indexPath  The indexPath that this cell will appear at.
 @param cellRecord The cell record that is generating this cell.
 
 @note This callback is not sent for views created/dequeued from header/footer records.
 */
- (void)manifest:(FSQCellManifest *)manifest willConfigureCell:(id)cell
                                                     withModel:(id)model
                                                   atIndexPath:(NSIndexPath *)indexPath
                                                        record:(FSQCellRecord *)cellRecord;

/**
 If implemented, your delegate will receive this callback when a cell is created or dequeued,
 after the cell's configureWithFSQCellRecordModel: method is called and also after
 the record's onConfigure block is called.
 
 Depending on your cells' design, it may be more appropriate to use a callback to do extra configuration globally
 for all cells in the manifest, instead of attaching an onConfigure block to each record.
 
 @param manifest   The manifest that is managing this cell.
 @param model      The model the cell was configured with.
 @param cell       The cell that was created/dequeued. It will be a UITableViewCell or UICollectionViewCell subclass.
 @param indexPath  The indexPath that this cell will appear at.

 @param cellRecord The cell record that is generating thi cell.
 
 @note This callback is not sent for views created/dequeued from header/footer records.
 */
- (void)manifest:(FSQCellManifest *)manifest didConfigureCell:(id)cell 
                                                    withModel:(id)model
                                                  atIndexPath:(NSIndexPath *)indexPath
                                                       record:(FSQCellRecord *)cellRecord;

/**
 If implemented, your delegate will receive this callback when a header view is created or dequeued,
 before the view's configureWithFSQCellRecordModel: method is called and also before
 the record's onConfigure block is called.
 
 Depending on your views' design, it may be more appropriate to use a callback to do extra configuration globally
 for all headers in the manifest, instead of attaching an onConfigure block to each record.
 
 @param manifest   The manifest that is managing this view.
 @param model      The model the view will be configured with.
 @param view       The view that was created/dequeued. 
                   It will be a UITableViewHeaderFooterView or UICollectionReusableView subclass.
 @param index      The section index that this header will appear at.
 @param cellRecord The cell record that is generating this view.
 */
- (void)manifest:(FSQCellManifest *)manifest willConfigureHeader:(id)view 
                                                       withModel:(id)model
                                                         atIndex:(NSInteger)index
                                                          record:(FSQCellRecord *)cellRecord;

/**
 If implemented, your delegate will receive this callback when a header view is created or dequeued,
 after the view's configureWithFSQCellRecordModel: method is called and also after
 the record's onConfigure block is called.
 
 Depending on your views' design, it may be more appropriate to use a callback to do extra configuration globally
 for all headers in the manifest, instead of attaching an onConfigure block to each record.
 
 @param manifest   The manifest that is managing this view.
 @param view       The view that was created/dequeued. 
                   It will be a UITableViewHeaderFooterView or UICollectionReusableView subclass.
 @param index      The section index that this header will appear at.
 @param model      The model the view was configured with.
 @param cellRecord The cell record that is generating this view.
 */
- (void)manifest:(FSQCellManifest *)manifest didConfigureHeader:(id)view 
                                                      withModel:(id)model
                                                        atIndex:(NSInteger)index
                                                         record:(FSQCellRecord *)cellRecord;

/**
 If implemented, your delegate will receive this callback when a footer view is created or dequeued,
 before the view's configureWithFSQCellRecordModel: method is called and also before
 the record's onConfigure block is called.
 
 Depending on your views' design, it may be more appropriate to use a callback to do extra configuration globally
 for all footers in the manifest, instead of attaching an onConfigure block to each record.

 @param manifest   The manifest that is managing this view.
 @param view       The view that was created/dequeued. 
                   It will be a UITableViewHeaderFooterView or UICollectionReusableView subclass.
 @param index      The section index that this footer will appear at.
 @param model      The model the view will be configured with.
 @param cellRecord The cell record that is generating this view.
 */
- (void)manifest:(FSQCellManifest *)manifest willConfigureFooter:(id)view 
                                                       withModel:(id)model
                                                         atIndex:(NSInteger)index
                                                          record:(FSQCellRecord *)cellRecord;

/**
 If implemented, your delegate will receive this callback when a footer view is created or dequeued,
 after the view's configureWithFSQCellRecordModel: method is called and also after
 the record's onConfigure block is called.
 
 Depending on your views' design, it may be more appropriate to use a callback to do extra configuration globally
 for all footers in the manifest, instead of attaching an onConfigure block to each record.
 
 @param manifest   The manifest that is managing this view.
 @param view       The view that was created/dequeued. 
                   It will be a UITableViewHeaderFooterView or UICollectionReusableView subclass.
 @param index      The section index that this footer will appear at. 
 @param model      The model the view was configured with.
 @param cellRecord The cell record that is generating this view.
 */
- (void)manifest:(FSQCellManifest *)manifest didConfigureFooter:(id)view 
                                                      withModel:(id)model
                                                        atIndex:(NSInteger)index
                                                         record:(FSQCellRecord *)cellRecord;
@end

/**
 This protocol contains methods to override or supplement the behavior of record selection
 */
@protocol FSQCellManifestRecordSelectionDelegate <NSObject>
@optional

/**
 If implemented, your delegate will receive this callback when a cell is selected,
 after the record's onSelection block is called.
 
 Depending on your cells' design, it may be more appropriate to use this callback to handle selection globally
 for all cells in the manifest, instead of attaching an onSelection block to each record.
 
 @param manifest   The manifest that is managing this cell.
 @param indexPath  The indexPath of the selected cell.
 @param cellRecord The cell record for the selected cell.
 
 @note This callback is not sent for header/footer records.
 */
- (void)manifest:(FSQCellManifest *)manifest didSelectCellAtIndexPath:(NSIndexPath *)indexPath 
                                                           withRecord:(FSQCellRecord *)cellRecord;

/**
 If implemented, your delegate will receive this callback when a cell is about to be selected,
 before the records' onSelection block is called.
 
 @param manifest   The manifest that is managing this cell.
 @param indexPath  The indexPath of the selected cell.
 @param cellRecord The cell record for the selected cell.
 
 @note This callback is not sent for header/footer records.
 */
- (void)manifest:(FSQCellManifest *)manifest willSelectCellAtIndexPath:(NSIndexPath *)indexPath 
                                                            withRecord:(FSQCellRecord *)cellRecord;
@end

/**
 This protocol contains methods to override size calculations for cells
 */
@protocol FSQCellManifestRecordSizingDelegate <NSObject>
@optional

/**
 If implemented, the return value of this method is used to determine the size of cells instead
 of an automatic call to the cells' heightForFSQCellRecordModel:maximumSize 
 or sizeForFSQCellRecordModel:maximumSize: methods.
 
 
 
 @param indexPath   The index path of the cell whose size needs to be calculated.
 @param manifest    The manifest that is managing this cell.
 @param cellRecord  The cell record for this cell.
 @param maximumSize The maximum size that this cell should be.

 @return The size that the cell should be created as. If you are using a table view manifest, the width field of the 
         return value is ignored. UITableViewCells are always created with the width of the table view.
 */
- (CGSize)sizeForCellAtIndexPath:(NSIndexPath *)indexPath 
                    withManifest:(FSQCellManifest *)manifest 
                          record:(FSQCellRecord *)cellRecord
                     maximumSize:(CGSize)maximumSize;

/**
 If implemented, the return value of this method is used to determine the maximum size of cells instead
 of using the defaultMaximumCellSizeForManifest: method. 
 
 @param indexPath  The index path of the cell whose size needs to be calculated.
 @param manifest   The manifest that is managing this cell.
 @param cellRecord The cell record for this cell.
 
 @return The maximum size this cell should be, passed through to size calculation methods.
 
 @note UITableViewCells will always be created as the width of the table view, but the width field of the returned
       size will still be used for its height calculation.
 */
- (CGSize)maximumSizeForCellAtIndexPath:(NSIndexPath *)indexPath 
                           withManifest:(FSQCellManifest *)manifest 
                                 record:(FSQCellRecord *)cellRecord;

/**
 This is the default maximum size that will be passed to cell, header, and footer records' 
 sizeForFSQCellRecordModel:maximumSize: method.
 
 If not implemented, defaults to  { tableView.width, CGFLOAT_MAX } for table views
 and { CGFLOAT_MAX, CGFLOAT_MAX } for collection views.
 */
- (CGSize)defaultMaximumCellSizeForManifest:(FSQCellManifest *)manifest;
@end


@protocol FSQCellManifestPlugin <NSObject>
@optional
- (void)wasAttachedToManifest:(FSQCellManifest *)manifest;
- (void)wasRemovedFromManifest:(FSQCellManifest *)manifest;
- (void)manifest:(FSQCellManifest *)manifest managedViewDidChange:(UIScrollView *)newManagedView oldView:(UIScrollView *)oldManagedView;
@end
