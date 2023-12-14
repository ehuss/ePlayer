//
//  EPEntry.h
//  ePlayer
//
//  Created by Eric Huss on 10/7/15.
//  Copyright © 2015 Eric Huss. All rights reserved.
//

/*
 Note: Realm does not exactly support abstract base classes.
 There is some faking going on to support the inverse
 relationship "parents".
 
 See:
 https://github.com/realm/realm-cocoa/issues/1109
 https://github.com/realm/realm-java/issues/761
 https://github.com/realm/realm-cocoa/issues/3241
 
*/

#import <Realm/Realm.h>

@class EPEntry;
@class EPRoot;

RLM_ARRAY_TYPE(EPEntry)

@interface EPEntry : RLMObject
@property NSString * uuid;
@property NSString * name;
@property NSDate * addDate;
@property NSDate * playDate;
@property NSDate * releaseDate;
@property NSInteger playCount;
@property (readonly) RLMLinkingObjects *parents;

// ePlayer URL used for copy-and-paste.  Subclasses must implement.
- (NSURL *)url;
// Duration of this entry.  Subclasses must implement.
- (NSTimeInterval)duration;
// Returns an array of strings that represent the paths where this
// item is found (with forward slash style names).
- (NSArray *)pathNames;

- (void)propagatePlayCount:(NSInteger)count;
- (void)propagatePlayDate:(NSDate *)date;
- (void)propagateAddDate:(NSDate *)date;
- (void)propagateReleaseDate:(NSDate *)date;

// Number of songs in this entry.  For EPSong, this returns 1.
- (NSUInteger)songCount;

@end
