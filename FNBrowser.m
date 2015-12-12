/* 
    Copyright (C) 2015 Stephen Oliver <steve@infincia.com>

    This code is distributed under the GNU General Public License, version 2 
    (or at your option any later version).
    
    3rd party libraries may be distributed under an alternate Open Source license.
    
    See the Acknowledgements file included with this code for details.
    
*/

#import "FNBrowser.h"

@implementation FNBrowser


+(instancetype)browserWithFileURL:(NSURL *)url {
    FNBrowser *browser = [[FNBrowser alloc] initWithApplication:url];
    return browser;
}

-(instancetype)initWithApplication:(NSURL *)url {
    self = [super init];
    if (self) {
        self.url = url;
        NSBundle *bundle = [NSBundle bundleWithURL:self.url];
        self.executablePath = bundle.executablePath;
		self.name = [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
        self.icon = [[NSWorkspace sharedWorkspace] iconForFile:self.url.path];
    }
    return self;
}

-(NSString *)description {
    return self.name;
}

-(NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@>: %@", self.name, self.executablePath];
}

@end
