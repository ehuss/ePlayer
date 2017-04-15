//
//  EPEntry.h
//  ePlayer
//
//  Created by Eric Huss on 10/7/15.
//  Copyright © 2015 Eric Huss. All rights reserved.
//

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

// Checks if this song has been orphaned (call after removing from a folder).
- (void)checkForOrphan:(EPRoot *)root;

// Number of songs in this entry.  For EPSong, this returns 1.
- (NSUInteger)songCount;

@end
