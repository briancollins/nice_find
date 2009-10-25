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
	NSTextField *queryField;
	NSTableView *resultsTable;
	NSMutableArray *results;
	OakProjectController *project;
	NSMutableString *buffer;
	NSButton *useGit;
	NSButton *caseSensitive;
	NSString *query;
	NSTask *task;
}

@property (nonatomic, retain) IBOutlet NSButton *findButton;
@property (nonatomic, retain) IBOutlet NSTextField *queryField;
@property (nonatomic, retain) IBOutlet NSTableView *resultsTable;
@property (nonatomic, retain) IBOutlet NSButton *useGit;
@property (nonatomic, retain) IBOutlet NSButton *caseSensitive;
@property (nonatomic, retain) NSString *query;
@property (nonatomic, retain) OakProjectController *project;
@property (nonatomic, retain) NSMutableArray *results;
@property (nonatomic, retain) NSMutableString *buffer;

+ (id)sharedInstance;
- (IBAction)performFind:(id)sender;
- (void)stopProcess;
- (void)taskEnded:(NSNotification *)aNotification;
- (void)addResult:(NSString *)aResult;

@end

