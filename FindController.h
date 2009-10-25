//
//  FindPanel.h
//  NiceFind
//
//  Created by Brian Collins on 09-10-23.
//  Copyright 2009 Brian Collins. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OakProjectController.h"

@interface FindController : NSWindowController {
	NSButton *findButton;
	NSTextField *query;
	NSTableView *resultsTable;
	NSMutableArray *results;
	OakProjectController *project;
	NSMutableString *buffer;
}

@property (nonatomic, retain) IBOutlet NSButton *findButton;
@property (nonatomic, retain) IBOutlet NSTextField *query;
@property (nonatomic, retain) IBOutlet NSTableView *resultsTable;
@property (nonatomic, retain) OakProjectController *project;
@property (nonatomic, retain) NSMutableArray *results;
@property (nonatomic, retain) NSMutableString *buffer;

- (IBAction)performFind:(id)sender;


@end
