//
//  EPUpdateResultsController.m
//  ePlayer
//
//  Created by Eric Huss on 5/6/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "EPUpdateResultsController.h"

@implementation EPUpdateResultsController

- (void)viewDidLoad
{
    UITextView *textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    textView.text = self.results;
    textView.editable = NO;
    textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:textView];
}

@end
