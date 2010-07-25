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

#import <Foundation/Foundation.h>

extern NSString * PCRERegexErrorDomain;
extern NSString * PCRERegexErrorOffsetKey;

// Options
extern int PCRERegexCaseless;
extern int PCRERegexMultiline;
extern int PCRERegexDotAll;
extern int PCRERegexExtended;
extern int PCRERegexAnchored;
extern int PCRERegexDollarEndOnly;
extern int PCRERegexExtra;
extern int PCRERegexNotBOL;
extern int PCRERegexNotEOL;
extern int PCRERegexUngreedy;
extern int PCRERegexNotEmpty;
extern int PCRERegexUTF8;
extern int PCRERegexNoAutoCapture;
extern int PCRERegexNoUTF8Check;
extern int PCRERegexAutoCallout;
extern int PCRERegexPartialSoft;
extern int PCRERegexDFAShortest;
extern int PCRERegexDFARestart;
extern int PCRERegexFirstline;
extern int PCRERegexDupNames;
extern int PCRERegexNewlineCR;
extern int PCRERegexNewlineLF;
extern int PCRERegexNewlineCRLF;
extern int PCRERegexNewlineAny;
extern int PCRERegexNewlineAnyCRLF;
extern int PCRERegexBSRAnyCRLF;
extern int PCRERegexBSRUnicode;
extern int PCRERegexJavascriptCompat;
extern int PCRERegexNoStartOptimize;
extern int PCRERegexPartialHard;
extern int PCRERegexNotEmptyAtStart;
extern int PCRERegexUCP;

struct pcre;
struct pcre_extra;

/** PCRERegex is a wrapper around PCRE.  The object is initialized with a pattern with is
 compiled and stored.  This object is meant to be reused each time the pattern is
 needed to make a match    
 */ 
@interface PCRERegex : NSObject {
	struct real_pcre * compiledPattern;
	struct pcre_extra * studyInfo;
}

/** Returns a regex object created by compiling the pattern. This is the same as calling +regexWithPattern:options:error with no options.
 @param pattern The pattern that will be compiled.
 @param error If an error occurs, upon return contains an NSError object that describes the problem. If you are not interested in possible errors, pass in NULL.
 @return A PCRERegex object created by compiling the pattern. If an error occurs during compilation, returns nil.
 */
+ (id) regexWithPattern:(NSString *)pattern error:(NSError **)error;

/** Returns a regex object created by compiling the pattern.
 @param pattern The pattern that will be compiled.
 @param options Additional options to be used in compilation.
 @param error If an error occurs, upon return contains an NSError object that describes the problem. If you are not interested in possible errors, pass in NULL.
 @return A PCRERegex object created by compiling the pattern. If an error occurs during compilation, returns nil.
 */
+ (id) regexWithPattern:(NSString *)pattern options:(int)options error:(NSError **)error;

/** Returns a PCRERegex object initialized by compiling the pattern.
 @param pattern The pattern that will be compiled.
 @param options Additional options to be used in compilation.
 @param error If an error occurs, upon return contains an NSError object that describes the problem. If you are not interested in possible errors, pass in NULL.
 @return A PCRERegex object initialized by compiling the pattern. If an error occurs during compilation, returns nil.
 */
- (id) initWithPattern:(NSString *)pattern options:(int)options error:(NSError **)error;

/** Finds the first match in the string.
 @param string The string the pattern will be matched against.
 @param startOffset The start location from which matching should begin.
 @param error If an error occurs, upon return contains an NSError object that describes the problem. If you are not interested in possible errors, pass in NULL.
 @param block A Block that will be executed if a match is found.\n\n The Block takes two arguments:
              <dl><dt>captureCount</dt>
			  <dd>The number of captures found.</dd>
			  <dt>captureRanges</dt>
			  <dd>The ranges of the captures that were found.</dd></dl>
 @return YES if a match was found, otherwise NO.
 */
- (BOOL) firstMatchInString:(NSString *)string withStartOffset:(NSUInteger)startOffset error:(NSError**)error usingBlock:(void (^)(NSUInteger captureCount, NSRange capturedRanges[captureCount]))block;

/** Finds the first match in the C string.
 @param string The C string the pattern will be matched against.
 @param startOffset The start location from which matching should begin.
 @param error If an error occurs, upon return contains an NSError object that describes the problem. If you are not interested in possible errors, pass in NULL.
 @param block A Block that will be executed if a match is found.\n\n The Block takes two arguments:
			  <dl><dt>captureCount</dt>
			  <dd>The number of captures found.</dd>
			  <dt>captureRanges</dt>
			  <dd>The ranges of the captures that were found.</dd></dl>
 @return YES if a match was found, otherwise NO.
 */
- (BOOL) firstMatchInCString:(const char *)string withLength:(int)length startOffset:(NSUInteger)startOffset error:(NSError**)error usingBlock:(void (^)(NSUInteger captureCount, NSRange capturedRanges[captureCount]))block;

/** Returns a localized string for an error code that results from pcre_exec.
 @param errorCode The error code from pcre_exec.
 @return A localized string for an error code that results from pcre_exec.
 */
+ (NSString *) localizedDescriptionForErrorCode:(int)errorCode;

@end
