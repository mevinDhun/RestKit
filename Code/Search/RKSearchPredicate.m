//
//  RKSearchPredicate.m
//  RestKit
//
//  Created by Blake Watters on 7/27/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKSearchPredicate.h"
#import "RKStringTokenizer.h"

@implementation RKSearchPredicate

+ (NSPredicate *)searchPredicateWithText:(NSString *)searchText type:(NSCompoundPredicateType)type
{
    return [[self alloc] initWithSearchText:searchText type:type];
}

- (instancetype)init
{
    NSAssert(NO, @"Incorrect designated initialiser used for this class");
    return [self initWithSearchText:nil type:0];
}
- (instancetype)initWithCoder:(NSCoder *)coder
{
    NSAssert(NO, @"Incorrect designated initialiser used for this class");
    return [self initWithSearchText:nil type:0];
}
- (instancetype)initWithType:(NSCompoundPredicateType)type subpredicates:(NSArray<NSPredicate *> *)subpredicates
{
    NSAssert(NO, @"Incorrect designated initialiser used for this class");
    return [self initWithSearchText:nil type:0];
}

- (instancetype)initWithSearchText:(NSString *)searchText type:(NSCompoundPredicateType)type
{
    RKStringTokenizer *tokenizer = [RKStringTokenizer new];
    NSSet *searchWords = [tokenizer tokenize:searchText];

    NSMutableArray *subpredicates = [NSMutableArray arrayWithCapacity:[searchWords count]];
    for (NSString *searchWord in searchWords) {
        [subpredicates addObject:[NSPredicate predicateWithFormat:@"(ANY searchWords.word beginswith %@)", searchWord]];
    }

    return [super initWithType:type subpredicates:subpredicates];
}

@end
