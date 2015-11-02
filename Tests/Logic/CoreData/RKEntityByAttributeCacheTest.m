//
//  RKEntityByAttributeCacheTest.m
//  RestKit
//
//  Created by Blake Watters on 5/1/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKEntityByAttributeCache.h"
#import "RKHuman.h"
#import "RKChild.h"

@interface RKEntityByAttributeCacheTest : RKTestCase
@property (nonatomic, strong) RKManagedObjectStore *managedObjectStore;
@property (weak, nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) RKEntityByAttributeCache *cache;
@end

@implementation RKEntityByAttributeCacheTest

@synthesize managedObjectStore = _managedObjectStore;
@synthesize cache = _cache;

- (void)setUp
{
    [RKTestFactory setUp];
    self.managedObjectStore = [RKTestFactory managedObjectStore];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    self.cache = [[RKEntityByAttributeCache alloc] initWithEntity:entity
                                                       attributes:@[ @"railsID" ]
                                             managedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
}

- (void)tearDown
{
    self.cache = nil;
    self.managedObjectStore = nil;
    [RKTestFactory tearDown];
}

#pragma mark - Identity Tests

- (void)testEntityIsAssigned
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    assertThat(self.cache.entity, is(equalTo(entity)));
}

- (void)testManagedObjectContextIsAssigned
{
    assertThat(self.cache.managedObjectContext, is(equalTo(self.managedObjectStore.persistentStoreManagedObjectContext)));
}

- (void)testAttributeNameIsAssigned
{
    assertThat(self.cache.attributes, is(equalTo(@[ @"railsID" ])));
}

#pragma mark - Loading and Flushing

- (void)testLoadSetsLoadedToYes
{
    [self.cache load:nil];
    expect([self.cache isLoaded]).will.equal(YES);
}

- (void)testLoadSetsCountAppropriately
{
    __block RKHuman *human;
    __block NSError *error = nil;
    
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human.railsID = @12345;
        [self.managedObjectStore.persistentStoreManagedObjectContext save:&error];
    }];
    
    assertThat(error, is(nilValue()));
    [self.cache load:nil];
    expect([self.cache count]).will.equal(1);
}

- (void)testFlushCacheRemovesObjects
{
    __block RKHuman *human1;
    __block RKHuman *human2;
    __block BOOL done = NO;
    
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human1.railsID = @12345;
        human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human2.railsID = @12345;
        [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];
        
        [self.cache addObjects:[NSSet setWithObjects:human1, human2, nil] completion:^{
            done = YES;
        }];
    }];
    
    expect(done).will.equal(YES);
    
    done = NO;
    [self.cache flush:^{
        expect([self.cache containsObject:human1]).to.equal(NO);
        expect([self.cache containsObject:human2]).to.equal(NO);
        done = YES;
    }];
    expect([self.cache isLoaded]).will.equal(NO);
    expect(done).will.equal(YES);
}

- (void)testFlushCacheReturnsCountToZero
{
    __block RKHuman *human1;
    __block RKHuman *human2;
    
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human1.railsID = @12345;
        human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human2.railsID = @12345;
        [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];
        
        [self.cache addObjects:[NSSet setWithObjects:human1, human2, nil] completion:nil];
    }];
    expect([self.cache count]).will.equal(2);
    [self.cache flush:nil];
    expect([self.cache count]).will.equal(0);
}

#pragma mark - Retrieving Objects

- (void)testRetrievalByNumericValue
{
    __block RKHuman *human;
    
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human.railsID = @12345;
        [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];
    }];
    
    [self.cache load:nil];
    expect([self.cache isLoaded]).will.equal(YES);
    
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = self.managedObjectStore.persistentStoreManagedObjectContext;
    NSManagedObject *object = [self.cache objectWithAttributeValues:@{ @"railsID": @12345 } inContext:childContext];
    assertThat(object.objectID, is(equalTo(human.objectID)));
}

- (void)testRetrievalOfNumericPropertyByStringValue
{
    __block RKHuman *human;
    
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human.railsID = @12345;
        [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];
    }];
    
    [self.cache load:nil];
    expect([self.cache isLoaded]).will.equal(YES);
    
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = self.managedObjectStore.persistentStoreManagedObjectContext;
    NSManagedObject *object = [self.cache objectWithAttributeValues:@{ @"railsID": @"12345" } inContext:childContext];
    assertThat(object, is(notNilValue()));
    assertThat(object.objectID, is(equalTo(human.objectID)));
}

- (void)testRetrievalOfObjectsWithAttributeValue
{
    __block RKHuman *human1;
    __block RKHuman *human2;
    __block BOOL done = NO;
    
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human1.railsID = @12345;
        human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human2.railsID = @12345;
        [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];
        
        [self.cache addObjects:[NSSet setWithObjects:human1, human2, nil] completion:^{
            done = YES;
        }];
    }];
    
    expect(done).will.equal(YES);
    
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = self.managedObjectStore.persistentStoreManagedObjectContext;
    NSSet *objects = [self.cache objectsWithAttributeValues:@{ @"railsID": @(12345) } inContext:childContext];
    expect(objects).to.haveCountOf(2);
    expect([[objects anyObject] isKindOfClass:[NSManagedObject class]]).to.equal(YES);
}

- (void)testRetrievalOfObjectsWithCollectionAttributeValue
{
    __block RKHuman *human1;
    __block RKHuman *human2;
    
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human1.railsID = @12345;
        human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human2.railsID = @5678;
        [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];
        
        [self.cache addObjects:[NSSet setWithObjects:human1, human2, nil] completion:nil];
    }];
    
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = self.managedObjectStore.persistentStoreManagedObjectContext;
    NSSet *objects = [self.cache objectsWithAttributeValues:@{ @"railsID": @[ @(12345), @(5678) ] } inContext:childContext];
    assertThat(objects, hasCountOf(2));
    assertThat([objects anyObject], is(instanceOf([NSManagedObject class])));
}

- (void)testRetrievalOfObjectsWithMoreThanOneCollectionAttributeValue
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    self.cache = [[RKEntityByAttributeCache alloc] initWithEntity:entity
                                                       attributes:@[ @"railsID", @"name" ]
                                             managedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    
    __block RKHuman *human1;
    __block RKHuman *human2;
    __block RKHuman *human3;
    
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human1.railsID = @12345;
        human1.name = @"Blake";
        human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human2.railsID = @5678;
        human2.name = @"Jeff";
        human3 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human3.railsID = @9999;
        human3.name = @"Blake";
        [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];
        
        [self.cache addObjects:[NSSet setWithObjects:human1, human2, human3, nil] completion:nil];
    }];
    
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = self.managedObjectStore.persistentStoreManagedObjectContext;
    NSSet *objects = [self.cache objectsWithAttributeValues:@{ @"railsID": @[ @(12345), @(5678) ], @"name": @"Blake" } inContext:childContext];
    // should find human1
    assertThat(objects, hasCountOf(1));
    assertThat([objects anyObject], is(instanceOf([NSManagedObject class])));
    assertThat([[objects anyObject] objectID], equalTo([human1 objectID]));
    
    objects = [self.cache objectsWithAttributeValues:@{ @"railsID": @[ @(12345), @(9999) ], @"name": @"Blake" } inContext:childContext];
    // should be human1 and human3
    assertThat(objects, hasCountOf(2));
    
    [childContext performBlockAndWait:^{
        assertThat([objects valueForKey:@"objectID"], hasItems([human1 objectID], [human3 objectID], nil));
    }];
    
    objects = [self.cache objectsWithAttributeValues:@{ @"railsID": @[ @(12345), @(9999) ], @"name": @[ @"Blake", @"Jeff" ] } inContext:childContext];
    // should be human1, human2 and human3
    assertThat(objects, hasCountOf(2));
    
    [childContext performBlockAndWait:^{
        assertThat([objects valueForKey:@"objectID"], hasItems([human1 objectID], [human3 objectID], nil));
    }];
    
    objects = [self.cache objectsWithAttributeValues:@{ @"railsID": @[ @(31337), @(8888) ], @"name": @[ @"Blake", @"Jeff" ] } inContext:childContext];
    // should be none
    assertThat(objects, hasCountOf(0));
}

// Do this with 3 attributes, 2 that are arrays and 1 that is not
// check
// Test blowing up if you request objects without enough cache keys

- (void)testAddingObjectToCache
{
    __block RKHuman *human;
    
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human.railsID = @12345;
        [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];
    }];
    
    [self.cache addObjects:[NSSet setWithObjects:human, nil] completion:nil];
    expect([self.cache containsObject:human]).will.equal(YES);
}

- (void)testAddingObjectWithDuplicateAttributeValue
{
    __block RKHuman *human1;
    __block RKHuman *human2;
    
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human1.railsID = @12345;
        human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human2.railsID = @12345;
        [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];
    }];
    
    [self.cache addObjects:[NSSet setWithObjects:human1, human2, nil] completion:nil];
    
    expect([self.cache containsObject:human1]).will.equal(YES);
    expect([self.cache containsObject:human2]).will.equal(YES);
}

- (void)testRemovingObjectFromCache
{
    __block RKHuman *human;
    
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human.railsID = @12345;
        [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];
        
        [self.cache addObjects:[NSSet setWithObjects:human, nil] completion:nil];
    }];
    
    expect([self.cache containsObject:human]).will.equal(YES);
    [self.cache removeObjects:[NSSet setWithObject:human] completion:nil];
    expect([self.cache containsObject:human]).will.equal(NO);
}

- (void)testRemovingObjectWithExistingAttributeValue
{
    __block RKHuman *human1;
    __block RKHuman *human2;
    
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human1.railsID = @12345;
        human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human2.railsID = @12345;
        [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];
        
        [self.cache addObjects:[NSSet setWithObjects:human1, human2, nil] completion:nil];
    }];
    
    expect([self.cache containsObject:human1]).will.equal(YES);
    expect([self.cache containsObject:human2]).will.equal(YES);
    [self.cache removeObjects:[NSSet setWithObject:human1] completion:nil];
    expect([self.cache containsObject:human1]).will.equal(NO);
    expect([self.cache containsObject:human2]).will.equal(YES);
}

#pragma mark - Inspecting Cache State

- (void)testContainsObjectReturnsNoForDifferingEntities
{
    __block NSManagedObject *cloud;
    
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Cloud" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        cloud = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    }];
    assertThatBool([self.cache containsObject:cloud], is(equalToBool(NO)));
}

- (void)testContainsObjectReturnsNoForSubEntities
{
    __block RKHuman *human;
    __block RKHuman *child;
    __weak __typeof(self)weakSelf = self;
    __block BOOL done = NO;
    
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human.railsID = @12345;
        child = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        child.railsID = @12345;
        
        RKEntityByAttributeCache *cache = self.cache;
        [cache addObjects:[NSSet setWithObject:human] completion:^{
            expect([weakSelf.cache containsObject:human]).to.equal(YES);
            expect([weakSelf.cache containsObject:child]).to.equal(NO);
            done = YES;
        }];
    }];
    
    expect(done).will.equal(YES);
}

- (void)testContainsObjectWithAttributeValue
{
    __block RKHuman *human;
    
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human.railsID = @12345;
        [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];
        
        [self.cache addObjects:[NSSet setWithObject:human] completion:nil];
    }];
    
    assertThatBool([self.cache containsObjectWithAttributeValues:@{ @"railsID": @(12345) }], is(equalToBool(YES)));
}

- (void)testCount
{
    assertThatInteger([self.cache count], is(equalToInteger(0)));
    
    __block RKHuman *human1;
    __block RKHuman *human2;
    __block RKHuman *human3;
    
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human1.railsID = @12345;
        human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human2.railsID = @12345;
        human3 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human3.railsID = @123456;
        
        [self.cache addObjects:[NSSet setWithObjects:human1, human2, human3, nil] completion:nil];
    }];
    
    expect([self.cache count]).will.equal(3);
}

- (void)testCountOfAttributeValues
{
    __block RKHuman *human1;
    __block RKHuman *human2;
    __block RKHuman *human3;
    
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human1.railsID = @12345;
        human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human2.railsID = @12345;
        human3 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human3.railsID = @123456;
        [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];
        
        [self.cache addObjects:[NSSet setWithObjects:human1, human2, human3, nil] completion:nil];
    }];
    
    expect([self.cache countOfAttributeValues]).will.equal(2);
}

- (void)testCountWithAttributeValue
{
    __block RKHuman *human1;
    __block RKHuman *human2;
    
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human1.railsID = @12345;
        human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human2.railsID = @12345;
        [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];
        
        [self.cache addObjects:[NSSet setWithObjects:human1, human2, nil] completion:nil];
    }];
    
    expect([self.cache countWithAttributeValues:@{ @"railsID": @(12345) }]).will.equal(2);
}

- (void)testThatUnloadedCacheReturnsCountOfZero
{
    assertThatInteger([self.cache count], is(equalToInteger(0)));
}

#pragma mark - Compound Key Tests

// missing attributes
// padding nil
// trying to look-up by nil
// trying to lookup with empty dictionary
// using weird attribute types as cache keys

- (void)testEvictionOfArrayOfIdentifierAttributes
{
    // Put some objects into the cache
    // Delete them
    
    __block RKHuman *human1;
    __block RKHuman *human2;
    
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human1.railsID = @12345;
        human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human2.railsID = @56789;
        [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];
        
        [self.cache addObjects:[NSSet setWithObjects:human1, human2, nil] completion:nil];
        
        NSDictionary *attributeValues = @{ @"railsID" : @[ human1.railsID, human2.railsID ] };
        
        [self.managedObjectStore.persistentStoreManagedObjectContext deleteObject:human1];
        [self.managedObjectStore.persistentStoreManagedObjectContext deleteObject:human2];
        [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];
        
        [self.cache objectsWithAttributeValues:attributeValues inContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    }];
}

#if TARGET_OS_IPHONE
- (void)testCacheIsFlushedOnMemoryWarning
{
    __block RKHuman *human1;
    __block RKHuman *human2;
    
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human1.railsID = @12345;
        human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human2.railsID = @12345;
        [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];
        
        [self.cache addObjects:[NSSet setWithObjects:human1, human2, nil] completion:nil];
    }];
    
    expect([self.cache containsObject:human1]).will.equal(YES);
    expect([self.cache containsObject:human2]).will.equal(YES);
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveMemoryWarningNotification object:self];
    expect([self.cache containsObject:human1]).will.equal(NO);
    expect([self.cache containsObject:human2]).will.equal(NO);
}
#endif

@end
