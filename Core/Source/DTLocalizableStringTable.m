//
//  DTLocalizableStringTable.m
//  genstrings2
//
//  Created by Oliver Drobnik on 1/12/12.
//  Copyright (c) 2012 Drobnik KG. All rights reserved.
//

#import "DTLocalizableStringTable.h"

#import "DTLocalizableStringEntry.h"
#import "NSString+DTLocalizableStringScanner.h"

@implementation DTLocalizableStringTable
{
	NSString *_name;
	NSMutableArray *_entries;
	NSMutableDictionary *_entryIndexByKey;
}

- (id)initWithName:(NSString *)name
{
	self = [super init];
	if (self)
	{
		_name = [name copy];
	}
	
	return self;
}

- (void)addEntry:(DTLocalizableStringEntry *)entry
{
	NSAssert([entry.tableName isEqualToString:_name], @"Entry does not belong in this table");
	
	NSString *key = entry.key;
	
	NSParameterAssert(key);
	
	if (!_entries)
	{
		_entries = [[NSMutableArray alloc] init];
	}
	
	if (!_entryIndexByKey)
	{
		_entryIndexByKey = [[NSMutableDictionary alloc] init];
	}
	
	// check if we already have such an entry
	DTLocalizableStringEntry *existingEntry = [_entryIndexByKey objectForKey:key];
	
	if (existingEntry)
	{
		if (![existingEntry.value isEqualToString:entry.value])
		{
			printf("Key \"%s\" used with multiple values. Value \"%s\" kept. Value \"%s\" ignored.\n",
				   [key UTF8String], [existingEntry.value UTF8String], [entry.value UTF8String]);
		}
		
		for (NSString *oneComment in [entry sortedComments])
		{
			[existingEntry addComment:oneComment];
		}
		
		return;
	}
	
	// add entry to table and key index
	[_entries addObject:entry];
	[_entryIndexByKey setObject:entry forKey:entry.key];
}

- (BOOL)writeToFolderAtURL:(NSURL *)url encoding:(NSStringEncoding)encoding error:(NSError **)error
{
	NSString *fileName = [_name stringByAppendingPathExtension:@"strings"];
	NSURL *tableURL = [NSURL URLWithString:fileName relativeToURL:url];
	
	if (!tableURL)
	{
		// this must be junk
		return NO;
	}
	
	NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"key" ascending:YES];
	NSArray *sortedEntries = [_entries sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
	
	NSMutableString *tmpString = [NSMutableString string];
	
	for (DTLocalizableStringEntry *entry in sortedEntries)
	{
		NSArray *comments = [entry sortedComments];
		
		if ([comments count]>1)
		{
			NSString *tmpString = [comments componentsJoinedByString:@"\" & \""];
			printf("Warning: Key \"%s\" used with multiple comments \"%s\"\n", [entry.key UTF8String], [tmpString UTF8String]);
		}
		
		// multi-line comments are indented
		NSString *comment = [[entry sortedComments] componentsJoinedByString:@"\n   "];
		NSString *key = [entry key];
		NSString *value = [entry value];
		
		if (!comment)
		{
			comment = @"No comment provided by engineer.";
		}
		
		// output comment
		[tmpString appendFormat:@"/* %@ */\n", comment];
		
		// output line
		[tmpString appendFormat:@"\"%@\" = \"%@\";\n", key, value];
		
		[tmpString appendString:@"\n"];
	}
	
	return [tmpString writeToURL:tableURL
					  atomically:YES
						encoding:encoding
						   error:error];
}

#pragma mark Properties

@synthesize name = _name;

@end
