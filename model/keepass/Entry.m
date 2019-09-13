//
//  Entry.m
//  Strongbox
//
//  Created by Mark on 17/10/2018.
//  Copyright © 2018 Mark McGuill. All rights reserved.
//

#import "Entry.h"
#import "KeePassDatabase.h"
#import "History.h"
#import "SimpleXmlValueExtractor.h"

@interface Entry ()

@property (nonatomic) NSMutableDictionary<NSString*, StringValue*> *strings;

@end

@implementation Entry

static NSString* const kTitleStringKey = @"Title";
static NSString* const kUserNameStringKey = @"UserName";
static NSString* const kPasswordStringKey = @"Password";
static NSString* const kUrlStringKey = @"URL";
static NSString* const kNotesStringKey = @"Notes";

const static NSSet<NSString*> *wellKnownKeys;

+ (void)initialize {
    if(self == [Entry class]) {
        wellKnownKeys = [NSSet setWithArray:@[  kTitleStringKey,
                                                kUserNameStringKey,
                                                kPasswordStringKey,
                                                kUrlStringKey,
                                                kNotesStringKey]];
    }
}

+ (const NSSet<NSString*>*)reservedCustomFieldKeys {
    return wellKnownKeys;
}

- (instancetype)initWithContext:(XmlProcessingContext*)context {
    if(self = [super initWithXmlElementName:kEntryElementName context:context]) {
        self.uuid = NSUUID.UUID;
        self.times = [[Times alloc] initWithXmlElementName:kTimesElementName context:context];
        self.history = [[History alloc] initWithXmlElementName:kHistoryElementName context:context];
        self.strings = [NSMutableDictionary dictionary];
        self.binaries = [NSMutableArray array];
        self.icon = nil;
        self.customIcon = nil;
    }
    
    return self;
}

- (id<XmlParsingDomainObject>)getChildHandler:(nonnull NSString *)xmlElementName {
    if([xmlElementName isEqualToString:kTimesElementName]) {
        return [[Times alloc] initWithContext:self.context];
    }
    else if([xmlElementName isEqualToString:kHistoryElementName]) {
        return [[History alloc] initWithContext:self.context];
    }
    else if([xmlElementName isEqualToString:kStringElementName]) {
        return [[String alloc] initWithContext:self.context];
    }
    else if([xmlElementName isEqualToString:kBinaryElementName]) {
        return [[Binary alloc] initWithContext:self.context];
    }
    
    return [super getChildHandler:xmlElementName];
}

- (BOOL)addKnownChildObject:(id<XmlParsingDomainObject>)completedObject withXmlElementName:(nonnull NSString *)withXmlElementName {
    if([withXmlElementName isEqualToString:kUuidElementName]) {
        self.uuid = [SimpleXmlValueExtractor getUuid:completedObject];
        return YES;
    }
    else if([withXmlElementName isEqualToString:kTimesElementName]) {
        self.times = (Times*)completedObject;
        return YES;
    }
    else if([withXmlElementName isEqualToString:kHistoryElementName]) {
        self.history = (History*)completedObject;
        return YES;
    }
    else if([withXmlElementName isEqualToString:kStringElementName]) {
        String* str = (String*)completedObject;
        self.strings[str.key] = [StringValue valueWithString:str.value protected:str.protected];
        return YES;
    }
    else if([withXmlElementName isEqualToString:kBinaryElementName]) {
        [self.binaries addObject:(Binary*)completedObject];
        return YES;
    }
    else if([withXmlElementName isEqualToString:kIconIdElementName]) {
        self.icon = [SimpleXmlValueExtractor getNumber:completedObject];
        return YES;
    }
    else if([withXmlElementName isEqualToString:kCustomIconUuidElementName]) {
        self.customIcon = [SimpleXmlValueExtractor getUuid:completedObject];
        return YES;
    }

    return NO;
}

- (BOOL)writeXml:(id<IXmlSerializer>)serializer {
    if(![serializer beginElement:self.originalElementName
                            text:self.originalText
                      attributes:self.originalAttributes]) {
        return NO;
    }
    
    if (![serializer writeElement:kUuidElementName uuid:self.uuid]) return NO;
    if (self.icon && ![serializer writeElement:kIconIdElementName integer:self.icon.integerValue]) return NO;
    if (self.customIcon && ![serializer writeElement:kCustomIconUuidElementName uuid:self.customIcon]) return NO;
    
    for (NSString* key in self.strings.allKeys) {
        StringValue* value = self.strings[key];
        // Strip Empty "Predefined or Well Known Fields"
        // Verify it's ok to strip empty strings. Looks like it is:
        // https://sourceforge.net/p/keepass/discussion/329221/thread/fd78ba87/
        //
        // MMcG: Don't strip custom emptys, it is useful to allow empty values in the custom fields

        if(value.protected == NO && value.value.length == 0 && [wellKnownKeys containsObject:key]) {
            continue;
        }

        if(![serializer beginElement:kStringElementName]) {
            return NO;
        }
        
        if(![serializer writeElement:kKeyElementName text:key]) return NO;
        
        // Don't trim Values - Whitespace might be important...
        
        if(![serializer writeElement:kValueElementName text:value.value protected:value.protected trimWhitespace:NO]) {
            return NO;
        }
        
        [serializer endElement];
    }
    
    if(self.binaries) {
        for (Binary *binary in self.binaries) {
            [binary writeXml:serializer];
        }
    }
    
    if(self.times && ![self.times writeXml:serializer]) return NO;
    
    if(self.history && self.history.entries && self.history.entries.count) {
        [self.history writeXml:serializer];
    }
    
    if(![super writeUnmanagedChildren:serializer]) {
        return NO;
    }
    
    [serializer endElement];
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Strings

- (StringValue*)getString:(NSString*)key {
    return self.strings[key];
}

- (NSString*)getStringOrDefault:(NSString*)key {
    StringValue* string = [self getString:key];
    return string == nil || string.value == nil ? @"" : string.value;
}

- (void)setString:(NSString*)key value:(NSString*)value {
    StringValue* string = [self getString:key];
    
    if(!string) {
        self.strings[key] = [StringValue valueWithString:value protected:NO];
    }
    else {
        string.value = value ? value : @"";
    }
}

- (void)setString:(NSString*)key value:(NSString*)value protected:(BOOL)protected {
    StringValue* string = [self getString:key];
    
    if(!string) {
        self.strings[key] = [StringValue valueWithString:value protected:protected];
    }
    else {
        string.value = value ? value : @"";
        string.protected = protected;
    }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Well Known Strings

- (NSString *)title {
    return [self getStringOrDefault:kTitleStringKey];
}

-(void)setTitle:(NSString *)title {
    [self setString:kTitleStringKey value:title protected:NO]; // FUTURE: Default Protection can be specified in the header
}

- (NSString *)username {
    return [self getStringOrDefault:kUserNameStringKey];
}

- (void)setUsername:(NSString *)username {
    [self setString:kUserNameStringKey value:username protected:NO];  // FUTURE: Default Protection can be specified in the header
}

- (NSString *)password {
    return [self getStringOrDefault:kPasswordStringKey];
}

- (void)setPassword:(NSString *)password {
    [self setString:kPasswordStringKey value:password protected:YES];  // FUTURE: Default Protection can be specified in the header
}

- (NSString *)url {
    return [self getStringOrDefault:kUrlStringKey];
}

- (void)setUrl:(NSString *)url {
    [self setString:kUrlStringKey value:url protected:NO];  // FUTURE: Default Protection can be specified in the header
}

- (NSString *)notes {
    return [self getStringOrDefault:kNotesStringKey];
}

- (void)setNotes:(NSString *)notes {
    [self setString:kNotesStringKey value:notes protected:NO];  // FUTURE: Default Protection can be specified in the header
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Custom Strings Readonly

- (void)removeAllStrings {
    [self.strings removeAllObjects];
}

- (NSDictionary<NSString *,StringValue *> *)allStrings {
    return self.strings;
}

- (NSDictionary<NSString *,StringValue *> *)customStrings {
    NSMutableDictionary<NSString*, StringValue*> *ret = [NSMutableDictionary dictionary];
    
    for (NSString* key in self.strings.allKeys) {
        if(![wellKnownKeys containsObject:key]) {
            StringValue* string = self.strings[key];
            ret[key] = string;
        }
    }
    
    return ret;
}

- (BOOL)isEqual:(id)object {
    if (object == nil) {
        return NO;
    }
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[Entry class]]) {
        return NO;
    }
    
    Entry* other = (Entry*)object;
    if (![self.uuid isEqual:other.uuid]) {
        return NO;
    }
    if (![self.times isEqual:other.times]) {
        return NO;
    }
    if (!(self.icon == nil && other.icon == nil) && ![self.icon isEqual:other.icon]) {
        return NO;
    }
    if (!(self.customIcon == nil && other.customIcon == nil) && ![self.customIcon isEqual:other.customIcon]) {
        return NO;
    }
    if (!(self.allStrings == nil && other.allStrings == nil) && !stringsAreEqual(self.allStrings, other.allStrings)) {
        return NO;
    }
    if (![self.binaries isEqual:other.binaries]) {
        return NO;
    }
    if (![self.history isEqual:other.history]) {
        return NO;
    }
    
    return YES;
}

BOOL stringsAreEqual(NSDictionary<NSString *,StringValue *> * a, NSDictionary<NSString *,StringValue *> * b) {
    return matchesSemantically(a, b) && matchesSemantically(b,a);
}

BOOL matchesSemantically(NSDictionary<NSString *,StringValue *> * a, NSDictionary<NSString *,StringValue *> * b) {
    for(NSString* key in a.allKeys) {
        StringValue *bVal = b[key];
        if(bVal) {
            StringValue *aVal = a[key];
            if(![aVal isEqual:bVal]) {
                return NO;
            }
        }
        else {
            StringValue *aVal = a[key];
            if(aVal.value.length != 0) {
                return NO;
            }
        }
    }
    
    return YES;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"[%@]-[%@]-[%@]-[%@]-[%@]\nUUID = [%@]\nTimes = [%@], iconId = [%@]/[%@]\ncustomFields = [%@]",
            self.title, self.username, self.password, self.url, self.notes, self.uuid, self.times, self.icon, self.customIcon, self.customStrings];
}

@end
