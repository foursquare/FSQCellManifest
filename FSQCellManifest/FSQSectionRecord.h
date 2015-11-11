//
//  FSQSectionRecord.h
//
//  Copyright (c) 2015 Foursquare. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FSQCellRecord, FSQCellManifest;

@interface FSQSectionRecord : NSObject <NSFastEnumeration>

/**
 An optional header for this section.
 
 For a UITableView, the cellClass should be a UITableViewHeaderFooterView subclass.
 For a UICollectionView, the cellClass should be a UICollectionReusableView subclass.
 
 @note Setting a header for a collection view will do nothing unless the collection view's layout supports headers.
 */
@property (nonatomic, retain) FSQCellRecord *header;

/**
 An optional footer for this section. 
 
 For a UITableView, the cellClass should be a UITableViewHeaderFooterView subclass.
 For a UICollectionView, the cellClass should be a UICollectionReusableView subclass.
 
 @note Setting a footer for a collection view will do nothing unless the collection view's layout supports footers.
 */
@property (nonatomic, retain) FSQCellRecord *footer;

/**
 An array of FSQCellRecord objects that correspond to the rows or items in a table view or collection view section.
 
 Individual records, once set, can be accessed via cellRecordAtIndex:
 
 @note To update a FSQSectionRecord that is already on a FSQCellManifest,
 do not set this property. Instead, use the insertion/removal methods in FSQCellManifest.
 */
@property (nonatomic, copy) NSArray<FSQCellRecord *> *cellRecords;

/**
 Insets for this section in a collection view.
 
 If you are not using a collection view manifest with a flow layout (or another layout using the same
 delegate methods) this property is not used.
 
 If not set, collectionViewLayout.sectionInset will be used.
 */
@property (nonatomic) UIEdgeInsets collectionViewSectionInset;

/**
 This contents of this dictionary are not used internally by the manifest classes. 
 You can use it to attach arbitrary data to the cell record for your own later use.
 */
@property (nonatomic, readonly) NSMutableDictionary *userInfo;

/**
 The number of records in this section
 */
- (NSInteger)numberOfCellRecords;

/**
 The cell record in this section at the given index, or nil if the index is out of bounds.
 */
- (FSQCellRecord *)cellRecordAtIndex:(NSInteger)index;

/**
 Convenience initializer with commonly set properties as method parameters
 
 All parameters are optional.
 
 @param cellRecords An array of FSQCellRecord objects.
 @param header      See header property description.
 @param footer      See footer property description.
 
 @return A new FSQSectionRecord object with the given properties set.
 */
- (instancetype)initWithCellRecords:(NSArray<FSQCellRecord *> *)cellRecords
                             header:(FSQCellRecord *)header
                             footer:(FSQCellRecord *)footer;

/**
 Used to determine if two records are equivalent.
 
 Records are considered to be equivalent if the following are all true:
 * They are the same subclass of FSQSectionRecord
 * Their cell, header, and section records are the same according to isEqualToCellRecord:
 * They have the same collection view insets or both have none.
 * Their userInfo dictionaries are the same according to isEqualToDictionary:
 
 @param anotherSectionRecord Another FSQSectionRecord to compare with.
 
 @return YES if the records appear to be equivalent. NO if they do not.
 */
- (BOOL)isEqualToSectionRecord:(FSQSectionRecord *)anotherSectionRecord;

@end
