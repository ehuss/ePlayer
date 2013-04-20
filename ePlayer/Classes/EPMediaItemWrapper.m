//
//  EPMediaItemWrapper.m
//  ePlayer
//
//  Created by Eric Huss on 4/15/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPMediaItemWrapper.h"

@implementation EPMediaItemWrapper

+ (EPMediaItemWrapper *)wrapperFromItem:(MPMediaItem *)mediaItem
{
    EPMediaItemWrapper *wrapper = [[EPMediaItemWrapper alloc] init];
    wrapper.item = mediaItem;
    return wrapper;
}

+ (NSArray *)sortedArrayOfWrappers:(NSArray *)wrappers
                           inOrder:(EPSortOrder)order
                          alphaKey:(NSString *)alphaKey
{
    NSString *key;
    BOOL ascending = NO;
    switch (order) {
        case EPSortOrderAlpha:
            key = alphaKey;
            ascending = YES;
            break;
        case EPSortOrderAddDate:
            [NSException raise:@"InvalidSortOrder" format:@"Add date is not supported."];
            break;
        case EPSortOrderPlayDate:
            key = @"lastPlayedDate";
            break;
        case EPSortOrderReleaseDate:
            key = @"releaseDate";
            break;
        default:
            [NSException raise:@"UnknownSortOrder" format:@"Unknown sort order %i.", order];
    }
    
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:key
                                                               ascending:ascending];
    NSArray *sortedEntries = [wrappers sortedArrayUsingDescriptors:@[sortDesc]];
    return sortedEntries;
}

- (NSNumber *)persistentID
{
    return [self.item valueForProperty:MPMediaItemPropertyPersistentID];
}

- (NSNumber *)albumPersistentID
{
    return [self.item valueForProperty:MPMediaItemPropertyAlbumPersistentID];
}

- (NSString *)title
{
    return [self.item valueForProperty:MPMediaItemPropertyTitle];
}

- (NSString *)albumTitle
{
    return [self.item valueForProperty:MPMediaItemPropertyAlbumTitle];
}

- (NSString *)artist
{
    return [self.item valueForProperty:MPMediaItemPropertyArtist];
}

- (NSString *)albumArtist
{
    NSString *name = [self.item valueForProperty:MPMediaItemPropertyAlbumArtist];
    if (name == nil) {
        return [self.item valueForProperty:MPMediaItemPropertyArtist];
    } else {
        return name;
    }
}

- (NSDate *)lastPlayedDate
{
    return [self.item valueForKey:MPMediaItemPropertyLastPlayedDate];
}

- (NSDate *)playCount
{
    return [self.item valueForKey:MPMediaItemPropertyPlayCount];
}

NSDate *dateFromYear(int year)
{
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear:year];
    return [gregorianCalendar dateFromComponents:comps];
}

- (NSDate *)releaseDate
{
    if (_releaseDate == nil) {
        _releaseDate = [self.item valueForProperty:MPMediaItemPropertyReleaseDate];
        if (_releaseDate == nil) {
            int year = self.releaseYear;
            if (year == 0) {
                // Or "distantPast"?
                _releaseDate = [NSDate date];
            } else {
                _releaseDate = dateFromYear(year);
            }
        }
    }
    return _releaseDate;
}

- (int)releaseYear
{
    // Sigh, unfortunately MPMediaItemPropertyReleaseDate does
    // not seem to work very often.  Using an undocumented property.
    return [[self.item valueForProperty:@"year"] intValue];
}

- (NSString *)sectionTitleForSortOrder:(EPSortOrder)sortOrder
                              alphaKey:(NSString *)alphaKey
{
    switch (sortOrder) {
        case EPSortOrderAlpha:
            return [[self.item valueForProperty:alphaKey] substringToIndex:1];

        case EPSortOrderAddDate:
            [NSException raise:@"SortOrderUnsupported" format:@"MPMedia does not support add date."];
            break;
            
        case EPSortOrderPlayDate:
            if (self.lastPlayedDate == nil) {
                return @"Never";
            } else {
                return yearFromDate(self.lastPlayedDate);
            }

        case EPSortOrderReleaseDate:
            return [NSString stringWithFormat:@"%i", self.releaseYear];

        default:
            [NSException raise:@"UnknownSortOrder" format:@"Unknown sort order %i.", sortOrder];
    }
    return nil; // Silence warning.
}

@end
