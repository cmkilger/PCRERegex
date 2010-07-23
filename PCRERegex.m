//  Created by Cory Kilger on 7/22/10.
//
//	Copyright (c) 2010 Cory Kilger
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.

#import "PCRERegex.h"
#import <pcre.h>

NSString * PCRERegexErrorDomain = @"com.corykilger.pcre.ErrorDomain";
NSString * PCRERegexErrorOffsetKey = @"PCRERegexErrorOffsetKey";

@implementation PCRERegex

// Convenience method to create a new regex object
+ (id) regexWithPattern:(NSString *)pattern error:(NSError **)error {
	return [[[self alloc] initWithPattern:pattern error:error] autorelease];
}

// Initializes a new regex object with a pattern string. If compilation fails it can return an error by reference.
- (id) initWithPattern:(NSString *)pattern error:(NSError **)error {
	if (![super init])
		return nil;
	
	// Compile the pattern
	int errorCode = 0;
	const char * errorString = NULL;
	int errorOffset = 0;
	compiledPattern = pcre_compile2([pattern cStringUsingEncoding:NSUTF8StringEncoding], PCRE_UTF8|PCRE_MULTILINE, &errorCode, &errorString, &errorOffset, NULL);
	
	// If compilation fails, create an error, cleanup, and return nil
	if (!compiledPattern) {
		if (error) {
			NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSString stringWithCString:errorString encoding:NSUTF8StringEncoding], NSLocalizedDescriptionKey,
									   [NSNumber numberWithInt:errorOffset], PCRERegexErrorOffsetKey,
									   nil];
			*error = [NSError errorWithDomain:PCRERegexErrorDomain code:errorCode userInfo:userInfo];
		}
		[self release];
		return nil;
	}
	
	// Study the pattern
	errorString = NULL;
	studyInfo = pcre_study(compiledPattern, 0, &errorString);
	
	// If studying returns an error, just print it as a warning
	if (errorString)
		NSLog(@"Pattern study failed. %s", errorString);
		
	return self;
}

// Cleanup
- (void) dealloc {
	if (compiledPattern)
		pcre_free(compiledPattern);
	if (studyInfo)
		pcre_free(studyInfo);
	[super dealloc];
}

#pragma mark -

#define MAX_CAPTURE_COUNT 30 // Maximum number of captures allowed.  This limits the buffer size for the ranges.

// Finds the first match in the string, starting from the start offset. Returns NO if no match was found, and sets error if an error occurs.  Runs the block if successful.
- (BOOL) firstMatchInString:(NSString *)string withStartOffset:(NSUInteger)startOffset error:(NSError**)error usingBlock:(void (^)(NSUInteger captureCount, NSRange capturedRanges[captureCount]))block {
	// Perform the matching
	int ovector[MAX_CAPTURE_COUNT*3];
	int captureCount = pcre_exec(compiledPattern, studyInfo, [string cStringUsingEncoding:NSUTF8StringEncoding], [string length], startOffset, 0, ovector, MAX_CAPTURE_COUNT*3);
	
	// Just return NO if no match was found, but there was no real error
	if (captureCount == -1) {
		return NO;
	}
	
	// Return the error if an error occurs
	else if (captureCount < 0) {
		if (error) {
			NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									   [PCRERegex localizedDescriptionForErrorCode:captureCount], NSLocalizedDescriptionKey,
									   nil];
			*error = [NSError errorWithDomain:PCRERegexErrorDomain code:captureCount userInfo:userInfo];
		}
		return NO;
	}
	
	// Allocate memory for the ranges
	NSRange * capturedRanges = malloc(captureCount * sizeof(NSRange));
	
	// Fill the memory with the appropriate ranges
	for (int i = 0; i < captureCount; i++) {
		NSUInteger start = ovector[i*2];
		NSUInteger end = ovector[i*2+1];
		capturedRanges[i] = NSMakeRange(start, end-start);
	}
	
	// Rune the block
	block(captureCount, capturedRanges);
	
	// Free the range memory
	free(capturedRanges);
	
	return YES;
}

// Returns a localized string for an error code that results from pcre_exec.
+ (NSString *) localizedDescriptionForErrorCode:(int)errorCode {
	switch (errorCode) {
		case PCRE_ERROR_NOMATCH:
			return NSLocalizedString(@"The subject string did not match the pattern.", nil);
		case PCRE_ERROR_NULL:
			return NSLocalizedString(@"The subject string did not match the pattern.", nil);
		case PCRE_ERROR_BADOPTION:
			return NSLocalizedString(@"An unrecognized bit was set in the options argument.", nil);
		case PCRE_ERROR_BADMAGIC:
			return NSLocalizedString(@"PCRE stores a 4-byte \"magic number\" at the start of the compiled code, to catch the case when it is passed a junk pointer and to detect when a pattern that was compiled in an environment of one endianness is run in an environment with the other endianness. This is the error that PCRE gives when the magic number is not present.", nil);
		case PCRE_ERROR_UNKNOWN_OPCODE:
			return NSLocalizedString(@"While running the pattern match, an unknown item was encountered in the compiled pattern. This error could be caused by a bug in PCRE or by overwriting of the compiled pattern.", nil);
		case PCRE_ERROR_NOMEMORY:
			return NSLocalizedString(@"If a pattern contains back references, but the ovector that is passed to pcre_exec() is not big enough to remember the referenced substrings, PCRE gets a block of memory at the start of matching to use for this purpose. If the call via pcre_malloc() fails, this error is given. The memory is automatically freed at the end of matching.", nil);
		case PCRE_ERROR_NOSUBSTRING:
			return NSLocalizedString(@"This error is used by the pcre_copy_substring(), pcre_get_substring(), and pcre_get_substring_list() functions (see below). It is never returned by pcre_exec().", nil);
		case PCRE_ERROR_MATCHLIMIT:
			return NSLocalizedString(@"The backtracking limit, as specified by the match_limit field in a pcre_extra structure (or defaulted) was reached. See the description above.", nil);
		case PCRE_ERROR_CALLOUT:
			return NSLocalizedString(@"This error is never generated by pcre_exec() itself. It is provided for use by callout functions that want to yield a distinctive error code. See the pcrecallout documentation for details.", nil);
		case PCRE_ERROR_BADUTF8:
			return NSLocalizedString(@"A string that contains an invalid UTF-8 byte sequence was passed as a subject.", nil);
		case PCRE_ERROR_BADUTF8_OFFSET:
			return NSLocalizedString(@"The UTF-8 byte sequence that was passed as a subject was valid, but the value of startoffset did not point to the beginning of a UTF-8 character.", nil);
		case PCRE_ERROR_PARTIAL:
			return NSLocalizedString(@"The subject string did not match, but it did match partially. See the pcrepartial documentation for details of partial matching.", nil);
		case PCRE_ERROR_BADPARTIAL:
			return NSLocalizedString(@"The PCRE_PARTIAL option was used with a compiled pattern containing items that are not supported for partial matching. See the pcrepartial documentation for details of partial matching.", nil);
		case PCRE_ERROR_INTERNAL:
			return NSLocalizedString(@"An unexpected internal error has occurred. This error could be caused by a bug in PCRE or by overwriting of the compiled pattern.", nil);
		case PCRE_ERROR_BADCOUNT:
			return NSLocalizedString(@"This error is given if the value of the ovecsize argument is negative.", nil);
		case PCRE_ERROR_RECURSIONLIMIT:
			return NSLocalizedString(@"The internal recursion limit, as specified by the match_limit_recursion field in a pcre_extra structure (or defaulted) was reached. See the description above.", nil);
		case PCRE_ERROR_BADNEWLINE:
			return NSLocalizedString(@"An invalid combination of PCRE_NEWLINE_xxx options was given.", nil);
		default:
			return NSLocalizedString(@"Unknown error code.", nil);
	}
}

@end
