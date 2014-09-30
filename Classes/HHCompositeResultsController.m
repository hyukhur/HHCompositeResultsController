//
//  HHCompositeResultsController.m
//  HHCompositeResultsController
//
//  Created by Hyuk Hur on 2014. 9. 29..
//  Copyright (c) 2014년 Hyuk Hur. All rights reserved.
//

#import "HHCompositeResultsController.h"

struct HHCompositeResultsControllerIndex {
    NSUInteger index;
    NSUInteger section;
};

typedef struct HHCompositeResultsControllerIndex HHCompositeResultsControllerIndex;

@interface HHCompositeResultsController ()
@property (nonatomic, strong) NSMutableArray *fetchedResultsControllers;
@property(nonatomic, weak) id<NSObject, NSFetchedResultsControllerDelegate> delegate;
@end

@interface HHCompositeResultsController (Delegate) <NSFetchedResultsControllerDelegate>
@end

@implementation HHCompositeResultsController (Private)
- (HHCompositeResultsControllerIndex)indexOfFetchedResultsControllerAtIndexPathSection:(NSUInteger)section sectionIndex:(BOOL)fromSectionIndex
{
    __block NSUInteger fetchedResultsControllerIndex = NSNotFound;
    __block NSUInteger sectionsCount = 0;
    [self.fetchedResultsControllers enumerateObjectsUsingBlock:^(NSFetchedResultsController *obj, NSUInteger idx, BOOL *stop) {
        NSUInteger sectionCount = fromSectionIndex ? [[obj sectionIndexTitles] count] : [[obj sections] count];
        sectionsCount += sectionCount;
        if (sectionsCount > section) {
            sectionsCount -= sectionCount;
            fetchedResultsControllerIndex = idx;
            *stop = YES;
        }
    }];
    return (HHCompositeResultsControllerIndex){.index = fetchedResultsControllerIndex, .section = MAX(0, section - sectionsCount)};
}

@end

@implementation HHCompositeResultsController (NSFetchedResultsController)

- (id)initWithFetchRequest:(NSFetchRequest *)fetchRequest managedObjectContext: (NSManagedObjectContext *)context sectionNameKeyPath:(NSString *)sectionNameKeyPath cacheName:(NSString *)name
{
    self = [self initWithFetchedResultsController:nil];
    if (self)
    {
        if (context) {
            [self addObject:[[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:sectionNameKeyPath cacheName:name]];
        }
    }
    return self;
}

- (BOOL)performFetch:(NSError **)error
{
    return NO;
}

- (NSFetchRequest *)fetchRequest
{
    return nil;
}

- (NSManagedObjectContext *)managedObjectContext
{
    return nil;
}

- (NSString *)sectionNameKeyPath
{
    return nil;
}

- (NSString *)cacheName
{
    return nil;
}

+ (void)deleteCacheWithName:(NSString *)name
{
    
}

- (NSArray *)fetchedObjects
{
    NSMutableArray *result = [NSMutableArray array];
    [self.fetchedResultsControllers enumerateObjectsUsingBlock:^(NSFetchedResultsController *obj, NSUInteger idx, BOOL *stop) {
        [result addObjectsFromArray:[obj fetchedObjects]];
    }];
    return result;
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath || [indexPath section] == NSNotFound || [indexPath row] == NSNotFound) {
        return nil;
    }
    HHCompositeResultsControllerIndex index = [self indexOfFetchedResultsControllerAtIndexPathSection:indexPath.section sectionIndex:NO];
    if (index.index == NSNotFound) {
        return nil;
    }
    NSFetchedResultsController *fetchedResultsController = [self.fetchedResultsControllers objectAtIndex:index.index];
    NSIndexPath *searchedIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:index.section];
    return [fetchedResultsController objectAtIndexPath:searchedIndexPath];
}

- (NSIndexPath *)indexPathForObject:(id)object
{
    if (!object) {
        return nil;
    }
    __block NSUInteger sectionsCount = 0;
    __block NSIndexPath *searchedIndexPath = nil;
    [self.fetchedResultsControllers enumerateObjectsUsingBlock:^(NSFetchedResultsController *obj, NSUInteger idx, BOOL *stop) {
        NSUInteger sectionCount = [[obj sections] count];
        sectionsCount += sectionCount;
        NSIndexPath *indexPath = [obj indexPathForObject:object];
        if (indexPath && [indexPath section] != NSNotFound && [indexPath row] != NSNotFound) {
            sectionsCount -= sectionCount;
            searchedIndexPath = indexPath;
            *stop = YES;
        }
    }];
    if (!searchedIndexPath) {
        return nil;
    }
    return [NSIndexPath indexPathForRow:searchedIndexPath.row inSection:sectionsCount + searchedIndexPath.section];
}

- (NSString *)sectionIndexTitleForSectionName:(NSString *)sectionName
{
    if ([self.delegate respondsToSelector:@selector(controller:sectionIndexTitleForSectionName:)]) {
        return [self.delegate controller:(NSFetchedResultsController *)self sectionIndexTitleForSectionName:sectionName];
    }
    NSUInteger index = [self.fetchedResultsControllers indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [obj isKindOfClass:[NSFetchedResultsController class]];
    }];
    if (index != NSNotFound) {
        NSFetchedResultsController *fetchedResultsController = [self.fetchedResultsControllers objectAtIndex:index];
        if (fetchedResultsController) {
            return [fetchedResultsController sectionIndexTitleForSectionName:sectionName];
        }
    }
    return [sectionName length] > 0 ? [NSString stringWithFormat: @"%C", [[sectionName capitalizedString] characterAtIndex:0]] : sectionName;
}

- (NSArray *)sectionIndexTitles
{
    NSMutableArray *sectionIndexTitles = [NSMutableArray array];
    [self.fetchedResultsControllers enumerateObjectsUsingBlock:^(NSFetchedResultsController *obj, NSUInteger idx, BOOL *stop) {
        [sectionIndexTitles addObjectsFromArray:[obj sectionIndexTitles]];
    }];
    return sectionIndexTitles;
}

- (NSArray *)sections
{
    NSMutableArray *result = [NSMutableArray array];
    [self.fetchedResultsControllers enumerateObjectsUsingBlock:^(NSFetchedResultsController *obj, NSUInteger idx, BOOL *stop) {
        [result addObjectsFromArray:[obj sections]];
    }];
    return result;
}

- (NSInteger)sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)sectionIndex
{
    HHCompositeResultsControllerIndex index = [self indexOfFetchedResultsControllerAtIndexPathSection:sectionIndex sectionIndex:YES];
    if (index.index == NSNotFound) {
        return NSNotFound;
    }
    NSFetchedResultsController *fetchedResultsController = [self.fetchedResultsControllers objectAtIndex:index.index];
    NSInteger section = [fetchedResultsController sectionForSectionIndexTitle:title atIndex:index.section];
    return sectionIndex - index.section + section;
}

@end

@implementation HHCompositeResultsController

- (instancetype)initWithFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController
{
    self = [self init];
    if (self) {
        _fetchedResultsControllers = [NSMutableArray array];
    }
    return self;
}

- (void)setDelegate:(id<NSObject, NSFetchedResultsControllerDelegate>)delegate
{
    _delegate = delegate;
    if (delegate) {
        [self.fetchedResultsControllers makeObjectsPerformSelector:@selector(setDelegate:) withObject:self];
    }
}

- (void)addObject:(NSFetchedResultsController *)object
{
    [self.fetchedResultsControllers addObject:object];
    if (self.delegate) {
        [object setDelegate:self];
    }
}

- (void)addObjectFromArray:(NSArray *)objects
{
    [self.fetchedResultsControllers addObjectsFromArray:objects];
    if (self.delegate) {
        [objects makeObjectsPerformSelector:@selector(setDelegate:) withObject:self];
    }
}

- (void)removeObject:(NSFetchedResultsController *)anObject
{
    [self.fetchedResultsControllers removeObject:anObject];
    [anObject setDelegate:nil];
}

- (void)removeObjectsInArray:(NSArray *)otherArray
{
    [self.fetchedResultsControllers removeObjectsInArray:otherArray];
    [otherArray makeObjectsPerformSelector:@selector(setDelegate:) withObject:nil];
}

@end

@implementation HHCompositeResultsController (Delegate)

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    
}

- (NSString *)controller:(NSFetchedResultsController *)controller sectionIndexTitleForSectionName:(NSString *)sectionName
{
    return nil;
}

@end
