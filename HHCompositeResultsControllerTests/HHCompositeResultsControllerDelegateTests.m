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


@interface HHCompositeResultsControllerDelegateTests : XCTestCase
@property HHCompositeResultsController *frc;
@property NSFetchRequest *request;
@property NSFetchedResultsController *frc1;
@property NSFetchedResultsController *frc2;
@end

@implementation HHCompositeResultsControllerDelegateTests

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

- (void)testPerformFetch {

}

@end
