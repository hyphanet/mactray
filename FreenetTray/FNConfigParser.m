/* 
    Copyright (C) 2015 Stephen Oliver <steve@infincia.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

#import "FNConfigParser.h"

#import "RegexKitLite.h"

@interface FNConfigParser ()
+(NSDictionary *)parseKeyValueString:(NSString * _Nonnull)string;
@end

@implementation FNConfigParser

+(NSDictionary * _Nullable)dictionaryFromConfigFile:(NSURL * _Nonnull)configFile {
    NSError *error;
    NSString *configContents = [NSString stringWithContentsOfFile:configFile.path encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        return nil;
    }
    return [FNConfigParser parseKeyValueString:configContents];
}

+(NSDictionary *)parseKeyValueString:(NSString * _Nonnull)string {
    NSMutableDictionary *config = [NSMutableDictionary new];
    NSString *regex = @"\\s*(.+?)\\s*=\\s*(.+)";
    [string enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
        if ([line isMatchedByRegex:@"^\\s*$"]) {
            // whitespace line
        }
        else if ([line isMatchedByRegex:@"^#"]) {
            // comment line
        }
        else if ([line isMatchedByRegex:regex]) {
            NSString *key;
            NSString *value;
            NSArray *captureArray = [line arrayOfCaptureComponentsMatchedByRegex:regex];
            if ([captureArray count] == 1) {
                NSArray *cap = captureArray[0];
                if ([cap count] == 3) {                            
                    key = cap[1];
                    value = cap[2];
                    config[key] = value;
                }
            }
        }
    }];
    return config;
}

@end
