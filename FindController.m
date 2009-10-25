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
	task = [[NSTask alloc] init];
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
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(taskEnded:) 
												 name:NSTaskDidTerminateNotification 
											   object:task];
    
    [[[task standardOutput] fileHandleForReading] readInBackgroundAndNotify];
    [task launch];    
}

- (IBAction)performFind:(id)sender {
	[self stopProcess];
	self.results = [NSMutableArray array];
	[self.resultsTable reloadData];
	self.buffer = [NSMutableString string];
	[self find:[self.queryField stringValue] inDirectory:[self.project projectDirectory]];
}

- (void)stopProcess {
	[[task standardOutput] close];
	[task terminate];
}

- (void)taskEnded:(NSNotification *)aNotification {
	[[[[aNotification object] standardOutput] fileHandleForReading] closeFile];
	[self addResult:self.buffer];
}
	 
- (void)getData:(NSNotification *)aNotification{
	NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];

	[self.buffer appendString:[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]];
	NSArray *parts = [self.buffer componentsSeparatedByString:@"\n"];
	if ([parts count] > 1) {
		for (NSString *p in [parts subarrayWithRange:NSMakeRange (0, [parts count] - 1)]) {
			[self addResult:p];
		}
		self.buffer = [NSMutableString stringWithString:[parts lastObject]];
	}

	[[aNotification object] readInBackgroundAndNotify];  
}

- (NSFont *)bold {
	return [[NSFontManager sharedFontManager] convertFont:[self font] toHaveTrait:NSBoldFontMask];
}


- (NSAttributedString *)prettifyString:(NSString *)s query:(NSString *)q {
	NSMutableAttributedString *pretty = [[NSMutableAttributedString alloc] initWithString:s attributes:
										 [NSDictionary dictionaryWithObject:[self font] forKey:NSFontAttributeName]];


	if (q != nil) {
		NSRange range = NSMakeRange(0, NSUIntegerMax);
		NSRange found;
		while (range.location < [s length] &&
			   (found = [s rangeOfRegex:q options:RKLCaseless inRange:range capture:0 error:nil]).location != NSNotFound) {

			[pretty setAttributes:[NSDictionary dictionaryWithObject:[self bold] forKey:NSFontAttributeName] range:found];
			range.location = found.location + found.length;
			range.length = [s length] - range.location;
			NSLog(@"LOC %d %@", range.location, s);
		}
	}
	
	return pretty;
}

- (NSAttributedString *)prettifyString:(NSString *)s { 
	return [self prettifyString:s query:nil];
}


- (void)addResult:(NSString *)aResult { 
	NSLog(@"%@", aResult);
	NSArray *components = [aResult componentsSeparatedByRegex:@":\\d+:"];
	if ([components count] > 1) {
		
		[self.results addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [self prettifyString:[[components objectAtIndex:0] lastPathComponent]], @"file", 
								 [self prettifyString:[components objectAtIndex:1] query:self.query], @"match", nil]];
		[self.resultsTable reloadData];
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [self.results count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	return [[self.results objectAtIndex:rowIndex] objectForKey:[aTableColumn identifier]];
}

@end
