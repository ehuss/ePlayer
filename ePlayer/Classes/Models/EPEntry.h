//
//  Entry.h
//  ePlayer
//
//  Created by Eric Huss on 4/10/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EPEntry : NSObject <NSCoding, NSCopying>

@property (strong, nonatomic) NSString * name;
@property (strong, nonatomic) NSDate * addDate;
@property (strong, nonatomic) NSDate * playDate;
@property (strong, nonatomic) NSDate * releaseDate;
@property (assign, nonatomic) NSInteger playCount;
// Set of Folders that are parents.
@property (strong, nonatomic) NSMutableSet *parents;

- (NSURL *)url;
- (NSTimeInterval)duration;
- (NSArray *)pathNames;

- (void)propagatePlayCount:(NSInteger)count;
- (void)propagatePlayDate:(NSDate *)date;
- (void)propagateAddDate:(NSDate *)date;
- (void)propagateReleaseDate:(NSDate *)date;

// Checks if this song has been orphaned (call after removing from a folder).
- (void)checkForOrphan;

@end
