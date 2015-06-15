#import <UIKit/UIKit.h>


NSString *const KEPlistPath = @"/var/mobile/Library/Preferences/com.niro.Kik8.plist";

static inline BOOL GetPrefBool(NSString *key)
{
  return [[[NSDictionary dictionaryWithContentsOfFile:KEPlistPath] valueForKey:key] boolValue];
}

%hook KikParsedMessage

- (BOOL)drRequested
{
  if (GetPrefBool(@"kDeliveredReceipts")) return NO;
  return %orig;
}

- (BOOL)rrRequested
{
  if (GetPrefBool(@"kReadReceipts")) return NO;
  return %orig;
}

%end

%hook KikAPIMessage

- (BOOL)disableForwarding
{
  return NO;
}

- (void)setAppID:(NSString *)argument
{
  if (GetPrefBool(@"kFakeCamera")) argument = @"com.kik.ext.camera";
  return %orig;
}

%end

%hook KikMessage

- (BOOL)isMarkedDeleted
{
  if (GetPrefBool(@"kDelete")) return YES;
  return %orig;
}

%end

%hook KikChat

- (BOOL)amTyping
{
  if (GetPrefBool(@"kTyping")) return NO;
  return %orig;
}

%end

@interface MainSettingsPane : UITableViewController
@end

@interface SettingsOptionSubPane : NSObject
- (instancetype)initWithTitle:(NSString *)title iconImage:(UIImage *)image subPaneClass:(Class)cls;
@end

%hook MainSettingsPane

- (void)viewDidLoad
{
  %orig;
}

- (NSArray *)generateSettingsOptions
{
  NSArray *arr = %orig;
  NSMutableArray *newArr = [NSMutableArray arrayWithArray:arr];
  [newArr addObject:[[%c(SettingsOptionSubPane) alloc] initWithTitle:@"Kik8 Cell" iconImage:nil subPaneClass:UIViewController.class]];

  return newArr;
}

%end
