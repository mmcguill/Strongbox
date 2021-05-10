//
//  DatabaseAuditReport.m
//  Strongbox
//
//  Created by Mark on 17/04/2020.
//  Copyright © 2014-2021 Mark McGuill. All rights reserved.
//

#import "DatabaseAuditReport.h"
#import "NSArray+Extensions.h"

@interface DatabaseAuditReport ()

@property NSSet<NSUUID*>* noPasswords;
@property NSDictionary<NSString*, NSSet<NSUUID *>*>* duplicatedPasswords;
@property NSSet<NSUUID*>* commonPasswords;
@property NSDictionary<NSString*, NSSet<NSUUID *>*>* similarPasswords;
@property NSSet<NSUUID*>* tooShort;
@property NSSet<NSUUID*>* pwned;
@property NSSet<NSUUID*>* lowEntropy;

@end

@implementation DatabaseAuditReport

- (instancetype)initWithNoPasswordEntries:(NSSet<NSUUID *> *)noPasswords
                      duplicatedPasswords:(NSDictionary<NSString *,NSSet<NSUUID *> *> *)duplicatedPasswords
                          commonPasswords:(NSSet<NSUUID *> *)commonPasswords
                                  similar:(nonnull NSDictionary<NSUUID *,NSSet<NSUUID *> *> *)similar
                                 tooShort:(NSSet<NSUUID *> *)tooShort
                                    pwned:(NSSet<NSUUID *> *)pwned
                               lowEntropy:(NSSet<NSUUID *> *)lowEntropy {
    self = [super init];
    
    if (self) {
        self.noPasswords = noPasswords.copy;
        self.duplicatedPasswords = duplicatedPasswords.copy;
        self.commonPasswords = commonPasswords.copy;
        self.similarPasswords = similar.copy;
        self.tooShort = tooShort.copy;
        self.pwned = pwned.copy;
        self.lowEntropy = lowEntropy.copy;
    }
    
    return self;
}

- (NSSet<NSUUID *> *)entriesWithNoPasswords {
    return self.noPasswords;
}

- (NSSet<NSUUID *> *)entriesWithDuplicatePasswords {
    NSArray<NSUUID*>* flattened = [self.duplicatedPasswords.allValues flatMap:^NSArray * _Nonnull(NSSet<NSUUID *> * _Nonnull obj, NSUInteger idx) {
        return obj.allObjects;
    }];
    
    return [NSSet setWithArray:flattened];
}

- (NSSet<NSUUID *> *)entriesWithCommonPasswords {
    return self.commonPasswords;
}

- (NSSet<NSUUID *> *)entriesWithSimilarPasswords {
    NSArray<NSUUID*>* flattened = [self.similarPasswords.allValues flatMap:^NSArray * _Nonnull(NSSet<NSUUID *> * _Nonnull obj, NSUInteger idx) {
        return obj.allObjects;
    }];
    
    return [NSSet setWithArray:flattened];
}

- (NSSet<NSUUID *> *)entriesTooShort {
    return self.tooShort;
}

- (NSSet<NSUUID *> *)entriesPwned {
    return self.pwned;
}

- (NSSet<NSUUID *> *)entriesWithLowEntropyPasswords {
    return self.lowEntropy;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"No Passswords = [%@], Duplicates = [%@], Common = [%@], Similar = [%@], tooShort = [%@], pwned = [%@], lowEntropy = [%@]",
            self.noPasswords, self.duplicatedPasswords, self.commonPasswords, self.similarPasswords, self.tooShort, self.pwned, self.lowEntropy];
}

@end
