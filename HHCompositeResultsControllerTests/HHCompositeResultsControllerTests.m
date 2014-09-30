//
//  HHCompositeResultsControllerTests.m
//  HHCompositeResultsControllerTests
//
//  Created by Hyuk Hur on 2014. 9. 29..
//  Copyright (c) 2014년 Hyuk Hur. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <XCTest/XCTest.h>
#import <HHFixedResultsController/HHFixedResultsController.h>
#import <OCMock/OCMock.h>
#import "HHCompositeResultsController.h"

@interface HHCompositeResultsControllerTests : XCTestCase <NSFetchedResultsControllerDelegate>
@property HHCompositeResultsController *frc;
@property NSFetchRequest *request;
@property NSFetchedResultsController *frc1;
@property NSFetchedResultsController *frc2;
@end

@implementation HHCompositeResultsControllerTests

- (void)setUp {
    [super setUp];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:nil];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"detail" ascending:YES]];
    request.predicate = [NSPredicate predicateWithValue:YES];
    [self setRequest:request];

    self.frc1 = (NSFetchedResultsController *)[[HHFixedResultsController alloc] initWithFetchRequest:request
                                                              objects:@[
                                                                        @{@"type":@"1type", @"title":@"title one", @"detail":@"test value1", @"type2":@""},
                                                                        @{@"type":@"2type", @"title":@"title two", @"detail":@"test value2", @"type2":@""},
                                                                        @{@"type":@"1types",@"title":@"title fouth", @"detail":@"test value4", @"type2":@""},
                                                                        @{@"type":@"1type", @"title":@"title zero", @"detail":@"test value0", @"type2":@""},
                                                                        @{@"type":@"1type", @"title":@"title", @"detail":@"test value0", @"type2":@""},
                                                                        ]
                                                   sectionNameKeyPath:@"type"
                                                            cacheName:nil];
    [self.frc1 performFetch:nil];
    self.frc2 = (NSFetchedResultsController *)[[HHFixedResultsController alloc] initWithFetchRequest:[request copy]
                                                              objects:@[
                                                                        @{@"type":@"a_type", @"title":@"title one", @"detail":@"test value1", @"type2":@""},
                                                                        @{@"type":@"b_type", @"title":@"title two", @"detail":@"test value2", @"type2":@""},
                                                                        @{@"type":@"a_types",@"title":@"title fouth", @"detail":@"test value4", @"type2":@""},
                                                                        @{@"type":@"a_type", @"title":@"title", @"detail":@"test value0", @"type2":@""},
                                                                        ]
                                                   sectionNameKeyPath:@"type"
                                                            cacheName:nil];
    [self.frc2 performFetch:nil];
    self.frc = [[HHCompositeResultsController alloc] initWithFetchRequest:nil managedObjectContext:nil sectionNameKeyPath:nil cacheName:nil];
    [self.frc addObject:self.frc1];
    [self.frc addObject:self.frc2];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testFetchAllObjects {
    XCTAssertEqual([[self.frc fetchedObjects] count], 9);
}

- (void) testSections {
    XCTAssertNotNil([self.frc sections]);
    XCTAssertEqual((NSUInteger)6, [[self.frc sections] count]);
    id<NSFetchedResultsSectionInfo> sectionInfo = [[self.frc sections] firstObject];
    XCTAssertEqualObjects(@"1type", [sectionInfo name]);
    XCTAssertEqualObjects(@"2type", [[[self.frc sections] objectAtIndex:1] name]);
    XCTAssertEqualObjects(@"a_types", [[[self.frc sections] lastObject] name]);
    XCTAssertEqual((NSUInteger)3, [[sectionInfo objects] count]);
    XCTAssertEqual((NSUInteger)1, [[[[self.frc sections] lastObject] objects] count]);
}

- (void) testObjectAtIndexPath {
    id model = [self.frc objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    XCTAssertNotNil(model);
    
    XCTAssertEqualObjects(@"title zero", [model valueForKey:@"title"]);
    XCTAssertEqualObjects(@"test value0", [model valueForKey:@"detail"]);
    XCTAssertEqualObjects(@"1type", [model valueForKey:@"type"]);
    
    model = [self.frc objectAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:3]];
    XCTAssertNotNil(model);
    
    XCTAssertEqualObjects(@"title one", [model valueForKey:@"title"]);
    XCTAssertEqualObjects(@"test value1", [model valueForKey:@"detail"]);
    XCTAssertEqualObjects(@"a_type", [model valueForKey:@"type"]);
}

- (void) testIndexPathForObject {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:1];
    id lastObject = [self.frc objectAtIndexPath:indexPath];
    NSIndexPath *expectedIndexPath = [self.frc indexPathForObject:lastObject];
    XCTAssertNotNil(lastObject);
    XCTAssertNotNil(expectedIndexPath);
    XCTAssertEqual(indexPath, expectedIndexPath);
    XCTAssertEqual(indexPath.section, expectedIndexPath.section);
    XCTAssertEqual(indexPath.row, expectedIndexPath.row);
    
    expectedIndexPath = [self.frc indexPathForObject:[[self.frc2 fetchedObjects] lastObject]];
    XCTAssertNotNil(expectedIndexPath);
    XCTAssertEqual(expectedIndexPath.section, 5);
    XCTAssertEqual(expectedIndexPath.row, 0);
    expectedIndexPath = [self.frc indexPathForObject:@{@"type":@"type1", @"title":@"title", @"detail":@"test value0"}];
    XCTAssertNil(expectedIndexPath);
    expectedIndexPath = [self.frc indexPathForObject:[[[self.frc1 fetchedObjects] firstObject] copy]];
    XCTAssertNotNil(expectedIndexPath);
    XCTAssertEqual(expectedIndexPath.section, 0);
    XCTAssertEqual(expectedIndexPath.row, 0);
}

- (void) testSectionIndexTitles {
    NSArray *titles = [self.frc sectionIndexTitles];
    XCTAssertEqual((NSUInteger)4, [titles count]);
    XCTAssertEqualObjects(@"1", [titles firstObject]);
    XCTAssertEqualObjects(@"2", [titles objectAtIndex:1]);
    XCTAssertEqualObjects(@"A", [titles objectAtIndex:2]);
    XCTAssertEqualObjects(@"B", [titles lastObject]);
}

- (void) testSectionForSectionIndexTitleAtIndex {
    NSInteger index = [self.frc sectionForSectionIndexTitle:@"1" atIndex:0];
    XCTAssertEqual(0, index);
    index = [self.frc sectionForSectionIndexTitle:@"2" atIndex:1];
    XCTAssertEqual(1, index);
    index = [self.frc sectionForSectionIndexTitle:@"A" atIndex:2];
    XCTAssertEqual(2, index);
    index = [self.frc sectionForSectionIndexTitle:@"B" atIndex:3];
    XCTAssertEqual(3, index);
}

- (void) testSectionIndexTitleForSectionName {
    NSString *indexTitle = [self.frc sectionIndexTitleForSectionName:@"atype"];
    XCTAssertEqualObjects(@"A", indexTitle);
}

- (void) testAddObject {
    NSArray *sections = [[self.frc sections] copy];
    NSArray *objects = [[self.frc fetchedObjects] copy];
    id<NSFetchedResultsSectionInfo> sectionInfo = [[self.frc sections] lastObject];
    XCTAssertEqual((NSUInteger)1, [[sectionInfo objects] count]);
    XCTAssertEqualObjects(@"a_types", [sectionInfo name]);
    
    NSFetchedResultsController *frc = (NSFetchedResultsController *)[[HHFixedResultsController alloc] initWithFetchRequest:[self.request copy]
                                                                                 objects:@[
                                                                                           @{@"type":@"가_type", @"title":@"title one", @"detail":@"test value1", @"type2":@""},
                                                                                           @{@"type":@"나_type", @"title":@"title two", @"detail":@"test value2", @"type2":@""},
                                                                                           @{@"type":@"가_types",@"title":@"title fouth", @"detail":@"test value4", @"type2":@""},
                                                                                           @{@"type":@"가_type", @"title":@"title", @"detail":@"test value0", @"type2":@""},
                                                                                           ]
                                                                      sectionNameKeyPath:@"type"
                                                                               cacheName:nil];
    [frc performFetch:nil];
    [self.frc addObject:frc];
    
    XCTAssertNotNil([self.frc sections]);
    XCTAssertEqual([sections count] + 3, [[self.frc sections] count]);
    XCTAssertEqual([objects count] + 4, [[self.frc fetchedObjects] count]);
    
    sectionInfo = [[self.frc sections] firstObject];
    XCTAssertEqual((NSUInteger)3, [[sectionInfo objects] count]);
    XCTAssertEqualObjects(@"1type", [sectionInfo name]);
    XCTAssertEqualObjects(@"2type", [[[self.frc sections] objectAtIndex:1] name]);

    sectionInfo = [[self.frc sections] lastObject];
    XCTAssertEqual((NSUInteger)1, [[sectionInfo objects] count]);
    XCTAssertEqualObjects(@"가_types", [sectionInfo name]);
}

- (void) testAddObjects {
    NSArray *sections = [[self.frc sections] copy];
    NSArray *objects = [[self.frc fetchedObjects] copy];
    id<NSFetchedResultsSectionInfo> sectionInfo = [[self.frc sections] lastObject];
    XCTAssertEqual((NSUInteger)1, [[sectionInfo objects] count]);
    XCTAssertEqualObjects(@"a_types", [sectionInfo name]);
    
    NSFetchedResultsController *frc1 = (NSFetchedResultsController *)[[HHFixedResultsController alloc] initWithFetchRequest:[self.request copy]
                                                                                                                   objects:@[
                                                                                                                             @{@"type":@"가_type", @"title":@"title one", @"detail":@"test value1", @"type2":@""},
                                                                                                                             @{@"type":@"나_type", @"title":@"title two", @"detail":@"test value2", @"type2":@""},
                                                                                                                             @{@"type":@"가_types",@"title":@"title fouth", @"detail":@"test value4", @"type2":@""},
                                                                                                                             @{@"type":@"가_type", @"title":@"title", @"detail":@"test value0", @"type2":@""},
                                                                                                                             ]
                                                                                                        sectionNameKeyPath:@"type"
                                                                                                                 cacheName:nil];
    [frc1 performFetch:nil];
    
    NSFetchedResultsController *frc2 = (NSFetchedResultsController *)[[HHFixedResultsController alloc] initWithFetchRequest:[self.request copy]
                                                                                       objects:@[
                                                                                                 @{@"type":@"가_type", @"title":@"title one", @"detail":@"test value1", @"type2":@""},
                                                                                                 @{@"type":@"나_type", @"title":@"title two", @"detail":@"test value2", @"type2":@""},
                                                                                                 @{@"type":@"가_types",@"title":@"title fouth", @"detail":@"test value4", @"type2":@""},
                                                                                                 @{@"type":@"가_type", @"title":@"title", @"detail":@"test value0", @"type2":@""},
                                                                                                 ]
                                                                            sectionNameKeyPath:@"type"
                                                                                     cacheName:nil];
    [frc2 performFetch:nil];
    [self.frc addObjectFromArray:@[frc1, frc2]];
    
    XCTAssertNotNil([self.frc sections]);
    XCTAssertEqual([sections count] + 3 * 2, [[self.frc sections] count]);
    XCTAssertEqual([objects count] + 4 * 2, [[self.frc fetchedObjects] count]);
    
    sectionInfo = [[self.frc sections] firstObject];
    XCTAssertEqual((NSUInteger)3, [[sectionInfo objects] count]);
    XCTAssertEqualObjects(@"1type", [sectionInfo name]);
    XCTAssertEqualObjects(@"2type", [[[self.frc sections] objectAtIndex:1] name]);
    
    sectionInfo = [[self.frc sections] lastObject];
    XCTAssertEqual((NSUInteger)1, [[sectionInfo objects] count]);
    XCTAssertEqualObjects(@"가_types", [sectionInfo name]);
}

- (void)testRemoveObject {
    [self.frc setDelegate:self];

    XCTAssertEqual((id<NSFetchedResultsControllerDelegate>)self.frc, [self.frc1 delegate]);
    XCTAssertEqual((id<NSFetchedResultsControllerDelegate>)self.frc, [self.frc2 delegate]);

    [self.frc removeObject:self.frc1];
    XCTAssertNil([self.frc1 delegate]);
    XCTAssertEqual((id<NSFetchedResultsControllerDelegate>)self.frc, [self.frc2 delegate]);
    
    id<NSFetchedResultsSectionInfo> sectionInfo = [[self.frc sections] firstObject];
    XCTAssertEqualObjects(@"a_types", [[[self.frc sections] lastObject] name]);
    XCTAssertEqual((NSUInteger)2, [[sectionInfo objects] count]);
    XCTAssertEqual((NSUInteger)1, [[[[self.frc sections] lastObject] objects] count]);
    
    id model = [self.frc objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    XCTAssertNotNil(model);
    
    XCTAssertEqualObjects(@"title", [model valueForKey:@"title"]);
    XCTAssertEqualObjects(@"test value0", [model valueForKey:@"detail"]);
    XCTAssertEqualObjects(@"a_type", [model valueForKey:@"type"]);

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:1];
    id lastObject = [self.frc objectAtIndexPath:indexPath];
    XCTAssertNotNil(lastObject);
    NSIndexPath *expectedIndexPath = [self.frc indexPathForObject:lastObject];
    XCTAssertNotNil(expectedIndexPath);

    NSArray *titles = [self.frc sectionIndexTitles];
    XCTAssertEqual((NSUInteger)2, [titles count]);
    XCTAssertEqualObjects(@"A", [titles objectAtIndex:0]);
    XCTAssertEqualObjects(@"B", [titles lastObject]);
}

- (void)testRemoveObjects {
    [self.frc setDelegate:self];
    
    XCTAssertEqual((id<NSFetchedResultsControllerDelegate>)self.frc, [self.frc1 delegate]);
    XCTAssertEqual((id<NSFetchedResultsControllerDelegate>)self.frc, [self.frc2 delegate]);
    
    [self.frc removeObjectsInArray:@[self.frc1, self.frc2]];
    XCTAssertNil([self.frc1 delegate]);
    XCTAssertNil([self.frc2 delegate]);
    XCTAssertEqual((NSUInteger)0, [[self.frc sections] count]);
    XCTAssertEqual((NSUInteger)0, [[self.frc fetchedObjects] count]);
    XCTAssertEqual((NSUInteger)0, [[self.frc sectionIndexTitles] count]);
    
    XCTAssertNil([self.frc objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]);
    
}

- (void)testDelegate {
    XCTAssertNil([self.frc delegate]);
    XCTAssertNil([self.frc1 delegate]);
    XCTAssertNil([self.frc2 delegate]);
    
    [self.frc setDelegate:self];
    
    XCTAssertEqual(self, [self.frc delegate]);
    XCTAssertEqual((id<NSFetchedResultsControllerDelegate>)self.frc, [self.frc1 delegate]);
    XCTAssertEqual((id<NSFetchedResultsControllerDelegate>)self.frc, [self.frc2 delegate]);
}

- (void)testPerformanceExample {
    [self measureBlock:^{
        XCTAssertEqual([[self.frc fetchedObjects] count], 9);
        XCTAssertNotNil([self.frc objectAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:3]]);
        XCTAssertNotNil([self.frc indexPathForObject:[[self.frc2 fetchedObjects] lastObject]]);
    }];
}

@end
