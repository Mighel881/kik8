#import <Preferences/Preferences.h>

@interface Kik8ListController: PSListController {
}
@end

@implementation Kik8ListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Kik8" target:self] retain];
	}
	return _specifiers;
}
- (void)link {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://Kik.me/u/notniro"]];
} 
@end

// vim:ft=objc
