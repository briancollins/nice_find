//
//  FindPanel.m
//  NiceFind
//
//  Created by Brian Collins on 09-10-23.
//  Copyright 2009 Brian Collins. All rights reserved.
//

#import "FindController.h"
#import "RegexKitLite.h"

@implementation FindController
@synthesize query, findButton, project, resultsTable, queryField, results, buffer, useGit, caseSensitive;

- (void)windowDidLoad {
	[self.window makeKeyAndOrderFront:self];
}

- (id)font {
	return [[objc_getClass("OakFontsAndColorsController") sharedInstance] font];
}

- (void)textFieldDidEndEditing:(NSTextField *)textField {
	[self performFind:self];
}


- (BOOL)useGitGrep {
	return [self.useGit state] == NSOnState;
}

- (BOOL)useCaseSensitive {
	return [self.caseSensitive state] == NSOnState;
}

- (void)find:(NSString *)q inDirectory:(NSString *)directory {
	self.query = q;
	NSTask *task = [[NSTask alloc] init];
    [task setStandardOutput:[NSPipe pipe]];
    [task setStandardError:[task standardOutput]];
	
	[task setLaunchPath:@"/usr/bin/env"];
	[task setCurrentDirectoryPath:directory];
	
	NSMutableArray *args = [NSMutableArray array];
	
	if ([self useGitGrep]) {
		[args addObjectsFromArray:[NSArray arrayWithObjects:@"git", @"grep", nil]];
	} else
		[args addObjectsFromArray:[NSArray arrayWithObjects:@"grep", @"-Ir", nil]];
	
	if (![self useCaseSensitive]) 
		[args addObject:@"-i"];
		
	[args addObjectsFromArray:[NSArray arrayWithObjects:@"-n", @"-e", q, directory, nil]];
	[task setArguments:args];
	
    [[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(getData:) 
												 name:NSFileHandleReadCompletionNotification 
											   object:[[task standardOutput] fileHandleForReading]];
    
    [[[task standardOutput] fileHandleForReading] readInBackgroundAndNotify];
    [task launch];    
}

- (IBAction)performFind:(id)sender {
	self.results = [NSMutableArray array];
	[self.resultsTable reloadData];
	self.buffer = [NSMutableString string];
	[self find:[self.queryField stringValue] inDirectory:[self.project projectDirectory]];
}

	 
- (void)getData:(NSNotification *)aNotification{
	NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];

	if ([data length]) {
		[self.buffer appendString:[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]];
		NSArray *parts = [self.buffer componentsSeparatedByString:@"\n"];
		if ([parts count] > 1) {
			self.buffer = [NSMutableString stringWithString:[parts objectAtIndex:1]];
			[self addResult:[parts objectAtIndex:0]];
		}
	} else {
		//[self stopProcess];
	}
	
	[[aNotification object] readInBackgroundAndNotify];  
}


- (NSAttributedString *)prettifyString:(NSString *)s query:(NSString *)q {
	return [[NSAttributedString alloc] initWithString:s
									attributes:[NSDictionary dictionaryWithObjectsAndKeys:
												[self font], NSFontAttributeName,
												nil]];
}

- (NSAttributedString *)prettifyString:(NSString *)s { 
	return [self prettifyString:s query:nil];
}

- (void)addResult:(NSString *)aResult {
	NSArray *components = [aResult componentsSeparatedByRegex:@":\\d+:"];
	if ([components count] > 1) {
		[self prettifyString:[components objectAtIndex:0]];
		
		[self.results addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [self prettifyString:[components objectAtIndex:0]], @"file", 
								 [self prettifyString:[components objectAtIndex:1]], @"match", nil]];
		[self.resultsTable reloadData];
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [self.results count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	return [[self.results objectAtIndex:rowIndex] objectForKey:[aTableColumn identifier]];
	NSLog(@"%@", [self.results objectAtIndex:rowIndex]); 
}

@end
