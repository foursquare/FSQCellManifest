//
//  FSQCellRecord.h
//
//  Copyright (c) 2015 Foursquare. All rights reserved.
//

#import "FSQCellManifestProtocols.h"

@class FSQCellRecord, FSQCellManifest, FSQTableViewCellManifest, FSQCollectionViewCellManifest;

@interface FSQCellRecord : NSObject

/**
 This model value is passed to the cell's configureWithFSQCellRecordModel: and heightForFSQCellRecordModel:maximumSize:
 methods. It can be any type, and should contain all the information necessary to pre-calculate the height of the cell
 and to configure its appearance.
 
 The class of the model should match the class that this record's cellClass is expecting for the aforementioned methods.
 */
@property (nonatomic, retain) id model;

/**
 The cellClass must conform to FSQCellManifestCellProtocol.
 
 If you are using the manifest for a UITableView then:
 * it must conform to FSQCellManifestTableViewCellProtocol
 * it must be a UITableViewCell subclass for "body" records
 * it must be a UITableViewHeaderFooterView subclass for header or footer records.
 
 If you are using the manifest for a UICollectionView then:
 * it must conform to FSQCellManifestCollectionViewCellProtocol   
 * it must be a UICollectionViewCell subclass for "body" records
 * it must be a UICollectionReusableView subclass for header or footer records.
 */
@property (nonatomic, retain) Class cellClass;

/**
 If set, this block will be called when a cell is created or dequeued, 
 after the cell's configureWithFSQCellRecordModel: method is called,
 and before the manifest delegate's didConfigureCell:atIndexPath:withManifest:record: method is called 
 */
@property (nonatomic, copy) FSQCellRecordConfigBlock onConfigure;

/**
 If set, this method will be called when the cell is selected,
 before the manifest delegate's didSelectCellatIndexPath:withManifest:record: method is called.
 
 If set, it also changes the default value of allowsHighlighting and allowsSelection to YES.
 */
@property (nonatomic, copy) FSQCellRecordSelectBlock onSelection;

/**
 Controls whether this row is allowed to be highlighted/selected.
 
 If not set, and there is a select block, the cell will be highlightable. Otherwise
 the value of manifest.cellSelectionEnabledByDefault will be used.
 
 You can manually override this behavior by setting a value yourself 
 (e.g. if you are using the didSelectCell: delegate method instead of the onSelection block).
 
 @note Due to how UIKit works, cells that do not highlight cannot be selected (although for UITableView
 you can instead change the cell's selection style to UITableViewCellSelectionStyleNone to achieve a similar
 result).
 */
@property (nonatomic, assign) BOOL allowsHighlighting;

/**
 Controls whether this row is allowed to be selected.
 
 If not set, it is equal to allowsHighlighting
 
 You can manually override this behavior by setting a value yourself
 (e.g. if you want to have cells that highlight but cannot be selected)
 
 @note Most times when you want to make a cell be selectable or unselectable, you actually want to change
        the allowsHighlighting value instead.
 */
@property (nonatomic, assign) BOOL allowsSelection;

/**
 The reusable cell identifier used to dequeue instances of this class from the table or collection view.
 If not specified, defaults to NSStringFromClass(cellClass)
 
 @warning The same reuseIdentifer cannot be used for more than one class (although the same class can be used
 by more than one identifier). If you set an identifier that has already been used for a different class in the
 same view an exception will be raised when the manifest attempts to deqeue the second view.
 */
@property (nonatomic, copy) NSString *reuseIdentifier;

/**
 This contents of this dictionary are not used internally by the manifest classes. 
 You can use it to attach arbitrary data to the cell record for your own later use.
 */
@property (nonatomic, readonly) NSMutableDictionary *userInfo;

/**
 Convenience initializer with the most commonly set properties as method parameters
 
 You must include a cellClass. All other parameters are optional.
 */
- (instancetype)initWithModel:(id)model 
                    cellClass:(Class)cellClass 
                  onConfigure:(FSQCellRecordConfigBlock)onConfigure
                  onSelection:(FSQCellRecordSelectBlock)onSelection;

/**
 Used to determine if two records are equivalent.
 
 Records are considered to be equivalent if the following are all true:
 * They are the same subclass of FSQCellRecord
 * Their models are equal according to isEqual: or neither have models.
 * They generate the same cellClass or neither has a cellClass.
 * They have the same reuseIdentifer or neither has a reuseIdentifier.
 * They both have an onConfigure block or both do not.
 * They both have an onSelection block or both do not.
 * They have the same userInfo according to isEqualToDictionary:
 * Their allowsHighlighting value is the same.
 * Their allowsSelection value is the same.
 
 @param anotherCellRecord Another FSQCellRecord to compare with.
 
 @return YES if the records appear to be equivalent. NO if they do not.
 */
- (BOOL)isEqualToCellRecord:(FSQCellRecord *)anotherCellRecord;

@end
