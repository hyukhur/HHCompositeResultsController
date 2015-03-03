//
//  HHCompositeResultsController.m
//  HHCompositeResultsController
//
//  Created by Hyuk Hur on 2014. 9. 29..
//  Copyright (c) 2014년 Hyuk Hur. All rights reserved.
//

#import "HHCompositeResultsController.h"

NSString *const HHCocoaErrorDomain = @"HHCocoaErrorDomain";

enum : NSInteger {
    HHMultipleErrorsError                  = 1560
};

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
            NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:sectionNameKeyPath cacheName:name];
            if (fetchedResultsController) {
                [self addObject:fetchedResultsController];
            }
        }
    }
    return self;
}

- (BOOL)performFetch:(NSError **)error
{
    __block BOOL result = NO;
    NSMutableArray *errors = error ? [NSMutableArray array] : nil;
    [self.fetchedResultsControllers enumerateObjectsUsingBlock:^(NSFetchedResultsController *obj, NSUInteger idx, BOOL *stop) {
        NSError *error = nil;
        BOOL success = [obj performFetch:&error];
        [errors addObject:error?:@(success)];
        result |= success;
    }];
    if ([errors count]) {
        *error = [NSError errorWithDomain:HHCocoaErrorDomain code:HHMultipleErrorsError userInfo:@{NSUnderlyingErrorKey:errors}];
    }
    return result;
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

- (instancetype)initWithFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController, ... NS_REQUIRES_NIL_TERMINATION
{
    self = [self init];
    if (self) {
        _fetchedResultsControllers = [NSMutableArray array];
        va_list args;
        va_start(args, fetchedResultsController);
        for (NSFetchedResultsController *arg = fetchedResultsController; arg != nil; arg = va_arg(args, NSFetchedResultsController *)) {
            [self addObject:arg];
        }
        va_end(args);
    }
    return self;
}

- (NSFetchedResultsController *)fetchedResultsController
{
    return (NSFetchedResultsController *)self;
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

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)anIndexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)aNewIndexPath
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
        __block NSUInteger sectionsCount = 0;
        [self.fetchedResultsControllers enumerateObjectsUsingBlock:^(NSFetchedResultsController *obj, NSUInteger idx, BOOL *stop) {
            if (obj == controller) {
                *stop = YES;
            } else {
                sectionsCount += [[obj sections] count];
            }
        }];
        NSIndexPath *indexPath = anIndexPath ? [NSIndexPath indexPathForRow:anIndexPath.row inSection:sectionsCount + anIndexPath.section] : nil;
        NSIndexPath *newIndexPath = aNewIndexPath ? [NSIndexPath indexPathForRow:aNewIndexPath.row inSection:sectionsCount + aNewIndexPath.section] : nil;
        [self.delegate controller:self.fetchedResultsController didChangeObject:anObject atIndexPath:indexPath forChangeType:type newIndexPath:newIndexPath];
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(controller:didChangeSection:atIndex:forChangeType:)]) {
        __block NSUInteger sectionsCount = 0;
        [self.fetchedResultsControllers enumerateObjectsUsingBlock:^(NSFetchedResultsController *obj, NSUInteger idx, BOOL *stop) {
            if (obj == controller) {
                *stop = YES;
            } else {
                sectionsCount += [[obj sections] count];
            }
        }];
        [self.delegate controller:self.fetchedResultsController didChangeSection:sectionInfo atIndex:sectionsCount + sectionIndex forChangeType:type];
    }
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(controllerWillChangeContent:)]) {
        [self.delegate controllerWillChangeContent:self.fetchedResultsController];
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(controllerDidChangeContent:)]) {
        [self.delegate controllerDidChangeContent:self.fetchedResultsController];
    }
}

- (NSString *)controller:(NSFetchedResultsController *)controller sectionIndexTitleForSectionName:(NSString *)sectionName
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(controller:sectionIndexTitleForSectionName:)]) {
        return [self.delegate controller:self.fetchedResultsController sectionIndexTitleForSectionName:sectionName];
    }
    /*
     The default implementation returns the capitalized first letter of the section name.
     */
    return [sectionName length] > 0 ? [NSString stringWithFormat: @"%C", [[sectionName capitalizedString] characterAtIndex:0]] : sectionName;
}

@end
