//
//  HHCompositeResultsControllerDelegateTests.m
//  HHCompositeResultsController
//
//  Created by Hyuk Hur on 2014. 10. 1..
//  Copyright (c) 2014년 Hyuk Hur. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <CoreData/CoreData.h>
#import <HHFixedResultsController/HHFixedResultsController.h>
#import "HHCompositeResultsController.h"

@interface HHSectionInfo : NSObject  <NSFetchedResultsSectionInfo>
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *indexTitle;
@property (nonatomic, readonly) NSUInteger numberOfObjects;
@property (nonatomic) NSMutableArray *objects;
@property (nonatomic) NSMutableArray *nextObjects;
@end

@interface HHCompositeResultsControllerDelegateTests : XCTestCase
@property NSArray *objects;
@property HHCompositeResultsController *hhfrc;
@property NSFetchedResultsController *frc;
@property OCMockObject<NSFetchedResultsControllerDelegate> *delegate;
@property NSFetchRequest *request;
@property HHFixedResultsController *frc1;
@property HHFixedResultsController *frc2;
@property OCMockObject *frc3;
@property OCMockObject *frc4;
@end

@implementation HHCompositeResultsControllerDelegateTests

- (id)checkWithSectionInfo:(NSString *)name indexTitle:(NSString *)indexTitle
{
    return [OCMArg checkWithBlock:^BOOL(HHSectionInfo *obj) {
        return [obj.name isEqualToString:name] && [obj.indexTitle isEqualToString:indexTitle];
    }];
}

- (void)setUp {
    [super setUp];
    
    self.objects = @[
                     [@{@"type":@"1type", @"title":@"title one", @"detail":@"test value1", @"type2":@""} mutableCopy],
                     @{@"type":@"2type", @"title":@"title two", @"detail":@"test value2", @"type2":@""},
                     @{@"type":@"1types",@"title":@"title fouth", @"detail":@"test value4", @"type2":@""},
                     @{@"type":@"1type", @"title":@"title zero", @"detail":@"test value0", @"type2":@""},
                     @{@"type":@"1type", @"title":@"title", @"detail":@"test value0", @"type2":@""},
                     ];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:nil];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"detail" ascending:YES]];
    request.predicate = [NSPredicate predicateWithValue:YES];
    [self setRequest:request];
    
    self.frc1 = [[HHFixedResultsController alloc] initWithFetchRequest:request
                                                               objects:@[
                                                                         @{@"type":@"a_type", @"title":@"title one", @"detail":@"test value1", @"type2":@""},
                                                                         @{@"type":@"b_type", @"title":@"title two", @"detail":@"test value2", @"type2":@""},
                                                                         @{@"type":@"a_types",@"title":@"title fouth", @"detail":@"test value4", @"type2":@""},
                                                                         @{@"type":@"a_type", @"title":@"title", @"detail":@"test value0", @"type2":@""},
                                                                         ]
                                                    sectionNameKeyPath:@"type"
                                                             cacheName:nil];
    [self.frc1 performFetch:nil];
    self.frc2 = [[HHFixedResultsController alloc] initWithFetchRequest:[request copy]
                                                               objects:@[
                                                                         @{@"type":@"1type", @"title":@"title one", @"detail":@"test value1", @"type2":@""},
                                                                         @{@"type":@"2type", @"title":@"title two", @"detail":@"test value2", @"type2":@""},
                                                                         @{@"type":@"1types",@"title":@"title fouth", @"detail":@"test value4", @"type2":@""},
                                                                         @{@"type":@"1type", @"title":@"title zero", @"detail":@"test value0", @"type2":@""},
                                                                         @{@"type":@"1type", @"title":@"title", @"detail":@"test value0", @"type2":@""},
                                                                         ]
                                                    sectionNameKeyPath:@"type"
                                                             cacheName:nil];
    [self.frc2 performFetch:nil];
    
    self.frc3 = [OCMockObject mockForClass:[NSFetchedResultsController class]];
    [[self.frc3 stub] setDelegate:[OCMArg any]];
    self.frc4 = [OCMockObject mockForClass:[NSFetchedResultsController class]];
    [[self.frc4 stub] setDelegate:[OCMArg any]];
    
    self.hhfrc = [[HHCompositeResultsController alloc] initWithFetchRequest:nil managedObjectContext:nil sectionNameKeyPath:nil cacheName:nil];
    self.frc = self.hhfrc.fetchedResultsController;
    self.delegate = [OCMockObject mockForProtocol:@protocol(NSFetchedResultsControllerDelegate)];
    self.frc.delegate = self.delegate;
    [self.hhfrc addObject:self.frc1.fetchedResultsController];
    [self.hhfrc addObject:(NSFetchedResultsController *)self.frc3];
    [self.hhfrc addObject:self.frc2.fetchedResultsController];
    [self.hhfrc addObject:(NSFetchedResultsController *)self.frc4];
    }

- (void)testPerformFetch {
    [[self.delegate expect] controllerWillChangeContent:self.frc];
    [[self.delegate expect] controllerDidChangeContent:self.frc];
    [[self.frc3 expect] performFetch:[OCMArg anyObjectRef]];
    [[self.delegate expect] controllerWillChangeContent:self.frc];
    [[self.delegate expect] controllerDidChangeContent:self.frc];
    [[self.frc4 expect] performFetch:[OCMArg anyObjectRef]];
    [[self.delegate stub] controller:self.frc sectionIndexTitleForSectionName:[OCMArg any]];
    
    NSError *error = nil;
    XCTAssertTrue([self.frc performFetch:&error]);
    
    [self.frc3 verify];
    [self.frc4 verify];
}

- (void) testDidChangeObjectWithNSFetchedResultsChangeInsert {
    [[self.delegate stub] controllerWillChangeContent:self.frc];
    [[self.delegate stub] controllerDidChangeContent:self.frc];
    [[self.delegate stub] controller:self.frc sectionIndexTitleForSectionName:OCMOCK_ANY];
    [[[self.delegate stub] ignoringNonObjectArgs] controller:self.frc didChangeSection:[OCMArg isNotNil] atIndex:0 forChangeType:(NSFetchedResultsChangeInsert)];
    
    [[self.delegate expect] controller:self.frc didChangeObject:OCMOCK_ANY atIndexPath:[OCMArg isNil] forChangeType:(NSFetchedResultsChangeInsert) newIndexPath:[OCMArg isEqual:[NSIndexPath indexPathForRow:0 inSection:7]]];
    [[[self.frc3 stub] andReturn:@[@""]] sections];
    
    [self.frc2 addObject:@{@"type":@"a_type", @"title":@"titl", @"detail":@"test value9 and value", @"type2":@""}];
    [self.frc2 performFetch:nil];

    [self.delegate verify];
}

/*
 On add and remove operations, only the added/removed object is reported.
 It’s assumed that all objects that come after the affected object are also moved, but these moves are not reported.
 */
- (void) testDidChangeObjectWithNSFetchedResultsChangeDelete {
    [[self.delegate stub] controller:self.frc sectionIndexTitleForSectionName:[OCMArg any]];

    [[self.delegate expect] controllerWillChangeContent:self.frc];
    [[self.delegate expect] controllerDidChangeContent:self.frc];
    [[[self.frc3 stub] andReturn:@[@""]] sections];
    [[self.delegate expect] controller:self.frc didChangeObject:[OCMArg isNotEqual:@{@"type":@"1type", @"title":@"title one", @"detail":@"test value1", @"type2":@""}] atIndexPath:[OCMArg isEqual:[NSIndexPath indexPathForRow:2 inSection:4]] forChangeType:(NSFetchedResultsChangeDelete) newIndexPath:[OCMArg isNil]];

    NSArray *changedObjects = @[
                                @{@"type":@"2type", @"title":@"title two", @"detail":@"test value2", @"type2":@""},
                                @{@"type":@"1types",@"title":@"title fouth", @"detail":@"test value4", @"type2":@""},
                                @{@"type":@"1type", @"title":@"title zero", @"detail":@"test value0", @"type2":@""},
                                @{@"type":@"1type", @"title":@"title", @"detail":@"test value0", @"type2":@""},
                                ];
    
    
    [self.frc2 setObjects:changedObjects];
    [self.frc2 performFetch:nil];
    [self.delegate verify];
}

/*
 A move is reported when the changed attribute on the object is one of the sort descriptors used in the fetch request.
 An update of the object is assumed in this case, but no separate update message is sent to the delegate.
 */
- (void) testDidChangeObjectWithNSFetchedResultsChangeMove {
    [[self.delegate stub] controller:self.frc sectionIndexTitleForSectionName:[OCMArg any]];
    
    [[self.delegate expect] controllerWillChangeContent:self.frc];
    [[self.delegate expect] controllerDidChangeContent:self.frc];

    self.frc.delegate = nil;
    [self.frc2 setObjects:self.objects];
    [self.frc2 performFetch:nil];
    self.frc.delegate = self.delegate;
    
    [[self.delegate reject] controller:self.frc didChangeObject:OCMOCK_ANY atIndexPath:OCMOCK_ANY forChangeType:NSFetchedResultsChangeInsert newIndexPath:OCMOCK_ANY];
    [[self.delegate reject] controller:self.frc didChangeObject:OCMOCK_ANY atIndexPath:OCMOCK_ANY forChangeType:NSFetchedResultsChangeDelete newIndexPath:OCMOCK_ANY];
    [[self.delegate reject] controller:self.frc didChangeObject:OCMOCK_ANY atIndexPath:OCMOCK_ANY forChangeType:NSFetchedResultsChangeUpdate newIndexPath:OCMOCK_ANY];

    [[[self.frc3 stub] andReturn:@[@""]] sections];

    [[self.delegate expect] controller:self.frc didChangeObject:[OCMArg isEqual:@{@"type":@"1type", @"title":@"title", @"detail":@"test value0", @"type2":@""}] atIndexPath:[OCMArg isEqual:[NSIndexPath indexPathForRow:1 inSection:4]] forChangeType:(NSFetchedResultsChangeMove) newIndexPath:[OCMArg isEqual:[NSIndexPath indexPathForRow:2 inSection:4]]];
    [[self.delegate expect] controller:self.frc didChangeObject:[OCMArg isEqual:@{@"type":@"1type", @"title":@"title zero", @"detail":@"test value0", @"type2":@""}] atIndexPath:[OCMArg isEqual:[NSIndexPath indexPathForRow:0 inSection:4]] forChangeType:(NSFetchedResultsChangeMove) newIndexPath:[OCMArg isEqual:[NSIndexPath indexPathForRow:1 inSection:4]]];
    [[self.delegate expect] controller:self.frc didChangeObject:[OCMArg isEqual:@{@"type":@"1type", @"title":@"title one", @"detail":@"test value", @"type2":@""}] atIndexPath:[OCMArg isEqual:[NSIndexPath indexPathForRow:2 inSection:4]] forChangeType:(NSFetchedResultsChangeMove) newIndexPath:[OCMArg isEqual:[NSIndexPath indexPathForRow:0 inSection:4]]];
    
    [self.objects[0] setObject:@"test value" forKey:@"detail"];
    [self.frc2 performFetch:nil];
    [self.delegate verify];
}

#pragma mark - sections

- (void) testDidChangeSectionWithNSFetchedResultsChangeInsert {
    [[self.delegate stub] controller:self.frc sectionIndexTitleForSectionName:[OCMArg any]];

    [[self.delegate expect] controllerWillChangeContent:self.frc];
    [[self.delegate expect] controllerDidChangeContent:self.frc];

    [[[self.delegate stub] ignoringNonObjectArgs] controller:self.frc didChangeObject:[OCMArg any] atIndexPath:[OCMArg any] forChangeType:0 newIndexPath:[OCMArg any]];
    [[[self.frc3 stub] andReturn:@[@""]] sections];
    [[self.delegate expect] controller:self.frc didChangeSection:[self checkWithSectionInfo:@"1types" indexTitle:@"1types"] atIndex:6 forChangeType:(NSFetchedResultsChangeDelete)];
    [[self.delegate expect] controller:self.frc didChangeSection:[self checkWithSectionInfo:@"3type" indexTitle:@"3type"] atIndex:6 forChangeType:(NSFetchedResultsChangeInsert)];
    
    [self.frc2 addObject:@{@"type":@"3type", @"title":@"title third", @"detail":@"test value3", @"type2":@""}];
    [self.frc2 performFetch:nil];
    [self.delegate verify];
}

- (void) testDidChangeSectionWithNSFetchedResultsChangeDelete {
    [[self.delegate stub] controllerWillChangeContent:self.frc];
    [[self.delegate stub] controllerDidChangeContent:self.frc];
    [[self.delegate stub] controller:self.frc sectionIndexTitleForSectionName:[OCMArg any]];
    
    [[[self.frc3 stub] andReturn:@[@""]] sections];
    [[self.delegate expect] controller:self.frc didChangeSection:[self checkWithSectionInfo:@"1types" indexTitle:@"1"] atIndex:6 forChangeType:(NSFetchedResultsChangeDelete)];
    [[self.delegate expect] controller:self.frc didChangeObject:[OCMArg isEqual:@{@"type":@"1types",@"title":@"title fouth", @"detail":@"test value4", @"type2":@""}] atIndexPath:[OCMArg isEqual:[NSIndexPath indexPathForRow:0 inSection:6]] forChangeType:(NSFetchedResultsChangeDelete) newIndexPath:[OCMArg isNil]];
    

    
    NSArray *changedObjects = @[
                                @{@"type":@"1type", @"title":@"title one", @"detail":@"test value1", @"type2":@""},
                                @{@"type":@"2type", @"title":@"title two", @"detail":@"test value2", @"type2":@""},
                                @{@"type":@"1type", @"title":@"title zero", @"detail":@"test value0", @"type2":@""},
                                @{@"type":@"1type", @"title":@"title", @"detail":@"test value0", @"type2":@""},
                                ];
    
    [self.frc2 setObjects:changedObjects];
    [self.frc2 performFetch:nil];
    [self.delegate verify];
}


#pragma mark - something chagned

- (void) testWillAndDidChangeContentAndDidChangeContentWhenObjectRemoved {
    [[self.delegate stub] controller:self.frc sectionIndexTitleForSectionName:[OCMArg any]];
    [[self.delegate expect] controllerWillChangeContent:self.frc];
    [[self.delegate expect] controllerDidChangeContent:self.frc];
    [[[self.frc3 stub] andReturn:@[@""]] sections];
    
    NSArray *changedObjects = @[
                                @{@"type":@"1type", @"title":@"title one", @"detail":@"test value1", @"type2":@""},
                                @{@"type":@"2type", @"title":@"title two", @"detail":@"test value2", @"type2":@""},
                                @{@"type":@"1types",@"title":@"title fouth", @"detail":@"test value4", @"type2":@""},
                                @{@"type":@"1type", @"title":@"title zero", @"detail":@"test value0", @"type2":@""},
                                @{@"type":@"1type", @"title":@"title", @"detail":@"test value0", @"type2":@""},
                                ];
    [self.frc2 setObjects:changedObjects];
    [self.frc2 performFetch:nil];
    [self.delegate verify];
}

- (void) testWillAndDidChangeContentAndDidChangeContentWhenObjectAdded {
    [[self.delegate stub] controller:self.frc sectionIndexTitleForSectionName:[OCMArg any]];
    [[[self.delegate stub] ignoringNonObjectArgs] controller:self.frc didChangeObject:[OCMArg any] atIndexPath:[OCMArg any] forChangeType:0 newIndexPath:[OCMArg any]];
    [[self.delegate expect] controllerWillChangeContent:self.frc];
    [[self.delegate expect] controllerDidChangeContent:self.frc];
    [[[self.frc3 stub] andReturn:@[@""]] sections];
    
    [self.frc2 addObject:@{@"type":@"1type", @"title":@"title five", @"detail":@"test value5", @"type2":@""}];
    [self.frc2 performFetch:nil];
    [self.delegate verify];
}


- (void) testWillAndDidChangeContentAndDidChangeContentWhenAnObjectAdded {
    [[self.delegate stub] controller:self.frc sectionIndexTitleForSectionName:[OCMArg any]];
    [[[self.delegate stub] ignoringNonObjectArgs] controller:self.frc didChangeObject:[OCMArg any] atIndexPath:[OCMArg any] forChangeType:0 newIndexPath:[OCMArg any]];
    
    [[self.delegate expect] controllerWillChangeContent:self.frc];
    [[self.delegate expect] controllerDidChangeContent:self.frc];
    [[[self.frc3 stub] andReturn:@[@""]] sections];
    
    [self.frc2 addObject:@{@"type":@"1type", @"title":@"title five", @"detail":@"test value5", @"type2":@""}];
    [self.frc2 performFetch:nil];
    [self.delegate verify];
}

- (void) testWillAndDidChangeContentAndDidChangeContentWhenObjectMoved {
    [[self.delegate stub] controller:self.frc sectionIndexTitleForSectionName:[OCMArg any]];
    [[self.delegate expect] controllerWillChangeContent:self.frc];
    [[self.delegate expect] controllerDidChangeContent:self.frc];
    [[[self.frc3 stub] andReturn:@[@""]] sections];
    [[self.delegate stub] controller:self.frc didChangeObject:[OCMArg any] atIndexPath:[OCMArg any] forChangeType:(NSFetchedResultsChangeMove) newIndexPath:[OCMArg any]];
    
    NSArray *changedObjects = @[
                                @{@"type":@"1type", @"title":@"title one", @"detail":@"test value1", @"type2":@""},
                                @{@"type":@"1types",@"title":@"title fouth", @"detail":@"test value4", @"type2":@""},
                                @{@"type":@"2type", @"title":@"title two", @"detail":@"test value2", @"type2":@""},
                                @{@"type":@"1type", @"title":@"title", @"detail":@"test value0", @"type2":@""},
                                @{@"type":@"1type", @"title":@"title zero", @"detail":@"test value0", @"type2":@""},
                                ];
    
    [self.frc2 setObjects:changedObjects];
    [self.frc2 performFetch:nil];
    [self.delegate verify];
}


- (void) testWillAndDidChangeContentAndDidChangeContentWhenObjectChanged {
    [[self.delegate stub] controller:self.frc sectionIndexTitleForSectionName:[OCMArg any]];
    [[[self.delegate stub] ignoringNonObjectArgs] controller:self.frc didChangeObject:[OCMArg any] atIndexPath:[OCMArg any] forChangeType:0 newIndexPath:[OCMArg any]];
    [[[self.delegate stub] ignoringNonObjectArgs] controller:self.frc didChangeSection:[OCMArg isNotNil] atIndex:0 forChangeType:(NSFetchedResultsChangeDelete)];
    
    
    [[self.delegate expect] controllerWillChangeContent:self.frc];
    [[self.delegate expect] controllerDidChangeContent:self.frc];
    [[[self.frc3 stub] andReturn:@[@""]] sections];
    
    NSArray *changedObjects = @[
                                @{@"type":@"1type", @"title":@"title 1", @"detail":@"test value one", @"type2":@""},
                                @{@"type":@"2type", @"title":@"title 2", @"detail":@"test value two", @"type2":@""},
                                @{@"type":@"1types",@"title":@"title 4", @"detail":@"test value four", @"type2":@""},
                                @{@"type":@"1type", @"title":@"title 0", @"detail":@"test value zero", @"type2":@""},
                                @{@"type":@"1type", @"title":@"title", @"detail":@"test value0", @"type2":@""},
                                ];
    
    [self.frc2 setObjects:changedObjects];
    [self.frc2 performFetch:nil];
    [self.delegate verify];
}

- (void) testWillAndDidChangeContentAndDidChangeContentWhenSectionChanged {
    [[self.delegate stub] controller:self.frc sectionIndexTitleForSectionName:[OCMArg any]];
    [[[self.delegate stub] ignoringNonObjectArgs] controller:self.frc didChangeObject:[OCMArg any] atIndexPath:[OCMArg any] forChangeType:0 newIndexPath:[OCMArg any]];
    
    [[self.delegate expect] controllerWillChangeContent:self.frc];
    [[self.delegate expect] controllerDidChangeContent:self.frc];
    [[[self.frc3 stub] andReturn:@[@""]] sections];
    
    [[self.delegate expect] controller:self.frc didChangeSection:[self checkWithSectionInfo:@"type" indexTitle:@"type"] atIndex:4 forChangeType:(NSFetchedResultsChangeInsert)];
    [[self.delegate expect] controller:self.frc didChangeSection:[self checkWithSectionInfo:@"types" indexTitle:@"types"] atIndex:5 forChangeType:(NSFetchedResultsChangeInsert)];
    
    [[self.delegate expect] controller:self.frc didChangeSection:[self checkWithSectionInfo:@"1type" indexTitle:@"1"] atIndex:4 forChangeType:(NSFetchedResultsChangeDelete)];
    [[self.delegate expect] controller:self.frc didChangeSection:[self checkWithSectionInfo:@"2type" indexTitle:@"2"] atIndex:5 forChangeType:(NSFetchedResultsChangeDelete)];
    [[self.delegate expect] controller:self.frc didChangeSection:[self checkWithSectionInfo:@"1types" indexTitle:@"1"] atIndex:6 forChangeType:(NSFetchedResultsChangeDelete)];
    
    
    
    NSArray *changedObjects = @[
                                @{@"type":@"type", @"title":@"title one", @"detail":@"test value1", @"type2":@""},
                                @{@"type":@"type", @"title":@"title two", @"detail":@"test value2", @"type2":@""},
                                @{@"type":@"types",@"title":@"title fouth", @"detail":@"test value4", @"type2":@""},
                                @{@"type":@"type", @"title":@"title zero", @"detail":@"test value0", @"type2":@""},
                                @{@"type":@"type", @"title":@"title", @"detail":@"test value0", @"type2":@""},
                                ];
    
    [self.frc2 setObjects:changedObjects];
    [self.frc2 performFetch:nil];
    [self.delegate verify];
}


- (void) testWillNotAndDidNotChangeContentAndDidChangeContent {
    [[self.delegate stub] controllerWillChangeContent:self.frc];
    [[self.delegate stub] controllerDidChangeContent:self.frc];
    [[self.delegate stub] controller:self.frc sectionIndexTitleForSectionName:[OCMArg any]];
    
    [self.frc2 performFetch:nil];
    [self.delegate verify];
    
    [[self.delegate reject] controllerWillChangeContent:self.frc];
    [[self.delegate reject] controllerDidChangeContent:self.frc];
    [[self.delegate stub] controller:self.frc sectionIndexTitleForSectionName:[OCMArg any]];
    
    [self.frc2 performFetch:nil];
    [self.delegate verify];
}

- (void) testSectionIndexTitleForSectionName {
    self.frc.delegate = nil;
    [self.frc2 setObjects:nil];
    [self.frc2 performFetch:nil];
    self.frc.delegate = self.delegate;
    
    [[[self.frc3 stub] andReturn:@[@""]] sections];
    [[self.delegate expect] controllerWillChangeContent:self.frc];
    [[self.delegate expect] controllerDidChangeContent:self.frc];
    [[self.delegate expect] controller:self.frc sectionIndexTitleForSectionName:[OCMArg isEqual:@"1type"]];
    [[self.delegate expect] controller:self.frc sectionIndexTitleForSectionName:[OCMArg isEqual:@"2type"]];
    [[self.delegate expect] controller:self.frc sectionIndexTitleForSectionName:[OCMArg isEqual:@"1types"]];
    [[self.delegate expect] controller:self.frc sectionIndexTitleForSectionName:[OCMArg isEqual:@"1type"]];
    [[self.delegate expect] controller:self.frc sectionIndexTitleForSectionName:[OCMArg isEqual:@"1type"]];
    [[self.delegate stub] controller:self.frc didChangeSection:[OCMArg any] atIndex:4 forChangeType:(NSFetchedResultsChangeInsert)];
    [[self.delegate stub] controller:self.frc didChangeSection:[OCMArg any] atIndex:5 forChangeType:(NSFetchedResultsChangeInsert)];
    [[self.delegate stub] controller:self.frc didChangeSection:[OCMArg any] atIndex:6 forChangeType:(NSFetchedResultsChangeInsert)];
    [[self.delegate stub] controller:self.frc didChangeObject:[OCMArg any] atIndexPath:[OCMArg isNil] forChangeType:NSFetchedResultsChangeInsert newIndexPath:[OCMArg any]];
    [[self.delegate stub] controller:self.frc didChangeObject:[OCMArg any] atIndexPath:[OCMArg isNil] forChangeType:NSFetchedResultsChangeInsert newIndexPath:[OCMArg any]];
    [[self.delegate stub] controller:self.frc didChangeObject:[OCMArg any] atIndexPath:[OCMArg isNil] forChangeType:NSFetchedResultsChangeInsert newIndexPath:[OCMArg any]];
    [[self.delegate stub] controller:self.frc didChangeObject:[OCMArg any] atIndexPath:[OCMArg isNil] forChangeType:NSFetchedResultsChangeInsert newIndexPath:[OCMArg any]];
    [[self.delegate stub] controller:self.frc didChangeObject:[OCMArg any] atIndexPath:[OCMArg isNil] forChangeType:NSFetchedResultsChangeInsert newIndexPath:[OCMArg any]];

    [self.frc2 setObjects:self.objects];
    [self.frc2 performFetch:nil];
    [self.delegate verify];
}


- (void) testSectionIndexTitleForSectionNameWithoutChanged {
    [[self.delegate stub] controllerWillChangeContent:self.frc];
    [[self.delegate stub] controllerDidChangeContent:self.frc];
    [[self.delegate stub] controller:self.frc sectionIndexTitleForSectionName:[OCMArg any]];
    
    [self.frc2 setObjects:self.objects];
    [self.frc2 performFetch:nil];
    
    [[self.delegate reject] controllerWillChangeContent:self.frc];
    [[self.delegate reject] controllerDidChangeContent:self.frc];
    [[self.delegate reject] controller:self.frc sectionIndexTitleForSectionName:[OCMArg any]];
    
    [self.frc2 setObjects:self.objects];
    [self.frc2 performFetch:nil];
    [self.delegate verify];
}




#pragma mark - KVO

- (void) testWillAndDidChangeContentWithoutPerfomPatch {
    [[self.delegate stub] controller:self.frc sectionIndexTitleForSectionName:[OCMArg any]];
    [[self.delegate stub] controller:self.frc didChangeSection:[OCMArg isNotNil] atIndex:0 forChangeType:(NSFetchedResultsChangeInsert)];
    
//    [[self.delegate expect] controller:self.frc didChangeObject:[OCMArg any] atIndexPath:[OCMArg any] forChangeType:(NSFetchedResultsChangeUpdate) newIndexPath:[OCMArg any]];
    
    self.objects[0][@"detail"] = @"value1 test";
    [self.frc2 notifiyChangeObject:self.objects[0] key:@"detail" oldValue:@"test value1" newValue:@"value1 test"];
    [self.delegate verify];
}


/*
 An update is reported when an object’s state changes, but the changed attributes aren’t part of the sort keys.
 */
- (void) testDidChangeObjectWithNSFetchedResultsChangeUpdate {
    [[self.delegate stub] controllerWillChangeContent:self.frc];
    [[self.delegate stub] controllerDidChangeContent:self.frc];
    [[self.delegate stub] controller:self.frc sectionIndexTitleForSectionName:[OCMArg any]];
    [[self.delegate stub] controller:self.frc didChangeSection:[OCMArg isNotNil] atIndex:0 forChangeType:(NSFetchedResultsChangeInsert)];
    
//    [[self.delegate expect] controller:self.frc didChangeObject:[OCMArg checkWithBlock:^BOOL(id obj) {
//        return [self.objects[0][@"detail"] isEqualToString:@"value1 test"];
//    }] atIndexPath:[OCMArg any] forChangeType:(NSFetchedResultsChangeUpdate) newIndexPath:[OCMArg any]];
    
    self.objects[0][@"detail"] = @"value1 test";
    [self.frc2 notifiyChangeObject:self.objects[0] key:@"detail" oldValue:@"test value1" newValue:@"value1 test"];
    [self.delegate verify];
}

- (void) testDidNotChangeObjectWithNSFetchedResultsChangeUpdate {
    [[self.delegate stub] controllerWillChangeContent:self.frc];
    [[self.delegate stub] controllerDidChangeContent:self.frc];
    [[self.delegate stub] controller:self.frc sectionIndexTitleForSectionName:[OCMArg any]];
    [[self.delegate stub] controller:self.frc didChangeSection:[OCMArg isNotNil] atIndex:0 forChangeType:(NSFetchedResultsChangeInsert)];
    
    [[self.delegate stub] controller:self.frc didChangeObject:[OCMArg checkWithBlock:^BOOL(id obj) {
        return [self.objects[0][@"detail"] isEqualToString:@"test value1"];
    }] atIndexPath:[OCMArg any] forChangeType:(NSFetchedResultsChangeUpdate) newIndexPath:[OCMArg any]];
    
    self.objects[0][@"detail"] = @"value1 test";
    [self.frc2 notifiyChangeObject:self.objects[0] key:@"detail" oldValue:@"test value1" newValue:@"test value1"];
    [self.delegate verify];
}

- (void) _testDidChangeObjectWithChangingSectionKeyValue {
    [[self.delegate stub] controllerWillChangeContent:self.frc];
    [[self.delegate stub] controllerDidChangeContent:self.frc];
    [[self.delegate expect] controller:self.frc sectionIndexTitleForSectionName:[OCMArg any]];
    [[self.delegate expect] controller:self.frc didChangeSection:[self checkWithSectionInfo:@"" indexTitle:@""] atIndex:0 forChangeType:(NSFetchedResultsChangeMove)];
    
    [[self.delegate expect] controller:self.frc didChangeObject:[OCMArg checkWithBlock:^BOOL(id obj) {
        return [self.objects[0][@"detail"] isEqualToString:@"value1 test"];
    }] atIndexPath:[OCMArg any] forChangeType:(NSFetchedResultsChangeUpdate) newIndexPath:[OCMArg any]];
    
    self.objects[0][@"detail"] = @"value1 test";
    [self.frc2 notifiyChangeObject:self.objects[0] key:@"type" oldValue:@"1type" newValue:@"3type"];
    [self.delegate verify];
}



@end
