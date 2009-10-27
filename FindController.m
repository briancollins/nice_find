//
//  FindPanel.m
//  NiceFind
//
//  Created by Brian Collins on 09-10-23.
//  Copyright 2009 Brian Collins. All rights reserved.
//

#import "FindController.h"
#import "RegexKitLite.h"
#import "NSStringExtensions.h"

@implementation FindController
@synthesize query, findButton, project, resultsTable, queryField, results, buffer, gitGrep, caseSensitive, regex;

static FindController *fc;

+ (id)sharedInstance {
	if (fc != nil) {
				return fc;
	} else {
		return fc = [[self alloc] initWithWindowNibName:@"FindPanel"];
				[fc showWindow:self];
	}
}

- (void)goToFile:(id)sender {
	NSDictionary *row = [self.results objectAtIndex:[self.resultsTable selectedRow]];
	[[[NSApplication sharedApplication] delegate] 
	 openFiles:[NSArray arrayWithObject:[row objectForKey:@"path"]]];
	[[self.project textView] goToLineNumber:[row objectForKey:@"line"]];
}

- (id)initWithWindowNibName:(NSString *)windowNibName {
	if (self = [super initWithWindowNibName:windowNibName]) {

	}
	return self;
}

- (void)windowDidLoad {
	[self.resultsTable setDoubleAction:@selector(goToFile:)];
}

- (void)show {
	self.project = [[[NSApplication sharedApplication] keyWindow] windowController];
	[self showWindow:self];
	[self.window makeFirstResponder:self.queryField]; 
}


- (id)font {
	return [[objc_getClass("OakFontsAndColorsController") sharedInstance] font];
}

- (void)textFieldDidEndEditing:(NSTextField *)textField {
	[self performFind:self];
}

- (BOOL)useRegex {
	return [self.regex state] == NSOffState;
}

- (BOOL)useGitGrep {
	return [self.gitGrep state] == NSOnState;
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
	
	if ([self useRegex])
		[args addObject:@"-F"];
	
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

- (NSString *)directory {
	return [self.project projectDirectory];
}

- (IBAction)performFind:(id)sender {
	[self stopProcess];
	self.results = [NSMutableArray array];
	self.buffer = [NSMutableString string];
	
	[self.resultsTable reloadData];
	
	[self find:[self.queryField stringValue] inDirectory:[self directory]];
}

- (void)stopProcess {
	[[[task standardOutput] fileHandleForReading] closeFile];
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


- (NSAttributedString *)prettifyString:(NSString *)s range:(NSString *)range {
	NSMutableAttributedString *pretty = [[NSMutableAttributedString alloc] initWithString:s attributes:
										 [NSDictionary dictionaryWithObject:[self font] forKey:NSFontAttributeName]];


	if (range) {
		NSRange r = NSRangeFromString(range);
		[pretty setAttributes:[NSDictionary dictionaryWithObject:[self bold] forKey:NSFontAttributeName] range:r];
	}
	
	return pretty;
}




- (void)addResult:(NSString *)aResult { 
	NSArray *components = [aResult componentsSeparatedByRegex:@":\\d+:"];
	NSNumber *line = [NSNumber numberWithInt:[[aResult stringByMatching:@":(\\d+):" capture:1] intValue]];
	if ([components count] > 1) {
		NSString *filePath;
		if ([self useGitGrep]) // git returns relative paths :(
			filePath = [[self directory] stringByAppendingPathComponent:[components objectAtIndex:0]];
		else
			filePath = [components objectAtIndex:0];
		
		for (NSString *range in [[components objectAtIndex:1] rangesOfString:self.query caseless:![self useCaseSensitive] regex:[self useRegex]]) {
			[self.results addObject:[NSDictionary dictionaryWithObjectsAndKeys:
									 [filePath lastPathComponent], @"file",
									 filePath, @"path",
									 line, @"line",
									 [self prettifyString:[components objectAtIndex:1] range:range], @"match", nil]];
			[self.resultsTable reloadData];
		}
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [self.results count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	return [[self.results objectAtIndex:rowIndex] objectForKey:[aTableColumn identifier]];
}

@end
