#import <UIKit/UIKit.h>

UIColor *const KEKikLightColor = [UIColor colorWithRed:0.937 green:0.937 blue:0.957 alpha:1];
static inline UIColor *bubbleColor();

NSString *const kGlobalUser = @"$global";
NSString *const kEnableNightMode = @"$kik8_enable_nightmode";
NSString *const kDisableSmiley = @"$kik8_disable_smiley";
NSString *const kUserDisabled = @"$kik8_user_disabled";
NSString *const kUnlockSmiley = @"$kik8_unlock_smiley";
NSString *const kDeliveredReceipts = @"$kik8_delivered_receipts";
NSString *const kReadReceipts = @"$kik8_read_receipts";
NSString *const kUnlimitedVideo = @"$kik8_unlimited_video";
NSString *const kSquareTheme = @"$kik8_square_theme";
NSString *const kFakeCamera = @"$kik8_fake_camera";
NSString *const kDelete = @"$kik8_delete";
NSString *const kTyping = @"$kik8_typing";

static NSObject *getOptionForKey(NSString *key, NSString *username)
{
  // code from @iMokhles
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, @"com.niro.kik8.plist"];

  NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];

  if (!dict) dict = [NSDictionary dictionary];

  NSDictionary *userP = [dict objectForKey:username];
  if (!userP) userP = [NSDictionary dictionary];

  if ([[userP objectForKey:kUserDisabled] boolValue] && ![key isEqualToString:kUserDisabled])
  {
    username = kGlobalUser;
    userP = [dict objectForKey:username];
    if (!userP) userP = [NSDictionary dictionary];
  }

  return [userP objectForKey:key];
}

static void saveOptionForKey(NSObject *obj, NSString *key, NSString *username)
{
  // code from @iMokhles
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, @"com.niro.kik8.plist"];

  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];

  if (!dict) dict = [NSMutableDictionary dictionary];

  NSMutableDictionary *userP = [dict objectForKey:username];
  if (!userP) userP = [NSMutableDictionary dictionary];

  [userP setObject:obj forKey:key];
  [dict setObject:userP forKey:username];

  [dict writeToFile:filePath atomically:YES];
}

@interface KikFileUtils : NSObject
+ (NSString *)dirPath:(NSString *)dir;
@end

static void copySmileys()
{
  NSString *k8smileypath = [[%c(KikFileUtils) dirPath:@"smiley_storage"] stringByAppendingPathComponent:@"kik8smileys"];
  [[NSFileManager defaultManager] removeItemAtPath:k8smileypath error:nil];
  [[NSFileManager defaultManager] copyItemAtPath:@"/Library/Application Support/kik8/smileys" toPath:k8smileypath error:nil];
}

static UIImage *colorImageWithColor(UIImage *image, UIColor *color)
{

  UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextTranslateCTM(context, 0, image.size.height);
  CGContextScaleCTM(context, 1.0, -1.0);

  CGContextSetBlendMode(context, kCGBlendModeNormal);
  CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
  //CGContextDrawImage(context, rect, img.CGImage);

  // Create gradient
  NSArray *colors = [NSArray arrayWithObjects:(id)color.CGColor, (id)color.CGColor, nil];
  CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
  CGGradientRef gradient = CGGradientCreateWithColors(space, (__bridge CFArrayRef)colors, NULL);

  // Apply gradient
  CGContextClipToMask(context, rect, image.CGImage);
  CGContextDrawLinearGradient(context, gradient, CGPointMake(0,0), CGPointMake(0, image.size.height), 0);
  UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  CGGradientRelease(gradient);
  CGColorSpaceRelease(space);

  return gradientImage;
  //    return image;
}

@interface KikUser : NSObject
- (NSString *)username;
- (NSString *)groupTag;
@end

@interface XMPPJID : NSObject
- (NSString *)user;
@end

@interface KikParsedMessage : NSObject
- (KikUser *)userAttachment;
- (NSDictionary *)contentUserInfo;
- (NSString *)_realUsername;
- (XMPPJID *)userJid;
@end
#import <substrate.h>

%hook SmileyStorageNetworkDiskProvider

- (id)loadSmileysFromFileName:(NSString *)fname
{
  if (((NSNumber *)getOptionForKey(kUnlockSmiley, kGlobalUser)).boolValue)
  fname = @"kik8smileys";

  return %orig;
}

- (void)clearStoredSmileyData
{
  if (!((NSNumber *)getOptionForKey(kUnlockSmiley, kGlobalUser)).boolValue)
  %orig;
}

- (void)reset
{
  if (!((NSNumber *)getOptionForKey(kUnlockSmiley, kGlobalUser)).boolValue)
  %orig;
}

- (void)deleteSmileyWithIdentifier:(id)arg1
{
  if (!((NSNumber *)getOptionForKey(kUnlockSmiley, kGlobalUser)).boolValue)
  %orig;
}

- (void)clearSmileysWithFileName:(id)arg1
{
  if (!((NSNumber *)getOptionForKey(kUnlockSmiley, kGlobalUser)).boolValue)
  %orig;
}

- (id)initWithFileName:(id)fname andXDataManager:(id)arg2 andUserDefaults:(id)arg3 andNetwork:(id)arg4 notifications:(id)arg5
{
  if (((NSNumber *)getOptionForKey(kUnlockSmiley, kGlobalUser)).boolValue)
  fname = @"kik8smileys";

  self = %orig;
  return self;
}

%end


%hook KikParsedMessage

- (BOOL)drRequested
{
  if ([((NSNumber *)getOptionForKey(kDeliveredReceipts, self._realUsername ? self._realUsername : kGlobalUser)) boolValue]) return NO;
  return %orig;
}

%new
- (NSString *)_realUsername // this reads the JID like iam.null_568 and parses it to iam.null (the username)
{
  NSString *_jid = self.userJid.user;
  NSArray *_jidSplit = [_jid componentsSeparatedByString:@"_"];
  NSMutableArray *mJids = [NSMutableArray arrayWithArray:_jidSplit];
  [mJids removeLastObject];

  return [mJids componentsJoinedByString:@"_"];
}

- (BOOL)rrRequested
{
  if ([((NSNumber *)getOptionForKey(kReadReceipts, self._realUsername ? self._realUsername : kGlobalUser)) boolValue]) return NO;
  return %orig;
}

%end

%hook PBJVision

- (double)capturedVideoSeconds
{
  if (((NSNumber *)getOptionForKey(kUnlimitedVideo, kGlobalUser)).boolValue) return 0;
  return %orig;
}

%end

%hook UITextInputTraits

- (int)keyboardAppearance
{
  if (((NSNumber *)getOptionForKey(kEnableNightMode, kGlobalUser)).boolValue) return 1;
  return %orig;
}

%end

%hook ProfilePictureImageView

- (BOOL)useRawImage
{
  if (((NSNumber *)getOptionForKey(kSquareTheme, kGlobalUser)).boolValue) return YES;
  return %orig;
}
- (BOOL)useHighResImageWhenAvailable
{
  if (((NSNumber *)getOptionForKey(kSquareTheme, kGlobalUser)).boolValue) return YES;
  return %orig;
}

%end

%hook NetworkNotifier

- (BOOL)isNetworkUnavailable
{
  return NO;
}
- (BOOL)isConnected
{
  return YES;
}

%end

@interface KikAPIMessage : NSObject
@property (nonatomic, retain) NSString *appID;
@property (nonatomic, retain) NSString *appName;
@end

%hook KikAPIMessage

- (BOOL)disableForwarding
{
  return NO;
}

- (void)setAppID:(NSString *)argument
{
  if (((NSNumber *)getOptionForKey(kFakeCamera, kGlobalUser)).boolValue)
  {
    if ([argument isEqualToString:@"com.kik.ext.gallery"]) argument = @"com.kik.ext.camera";
    if ([argument isEqualToString:@"com.kik.ext.video-gallery"])
    {
      argument = @"com.kik.ext.video-camera";
      self.appName = @"Video";
    }
  }

  %orig;
}

- (void)setAppName:(NSString *)name
{

  if (((NSNumber *)getOptionForKey(kFakeCamera, kGlobalUser)).boolValue)
  {
    if ([self.appID isEqualToString:@"com.kik.ext.video-camera"] || [self.appID isEqualToString:@"com.kik.ext.video-gallery"])
    name = @"Video";
  }

  %orig;
}

%end

@interface MediaBarViewController : UIViewController
@property(retain, nonatomic) UIView *mediaBar;
@property(retain, nonatomic) UISwitch *_toggle;
@end

%hook MediaBarViewController

- (void)viewDidLayoutSubviews
{
  %orig;

  if (!self._toggle)
  {
    // fake camera switch
    self._toggle = [[UISwitch alloc] initWithFrame:CGRectMake((self.mediaBar.frame.size.width-51)-50, 5, 51, 31)];
    [self._toggle addTarget:self action:@selector(camToggleValueChanged:) forControlEvents:UIControlEventTouchUpInside];
    self._toggle.onTintColor = bubbleColor();
    [self._toggle setOn:((NSNumber *)getOptionForKey(kFakeCamera, kGlobalUser)).boolValue animated:NO];
  }

  //hide ugly border abox text box
  if (((NSNumber *)getOptionForKey(kEnableNightMode, kGlobalUser)).boolValue)
    if (self.mediaBar.layer.sublayers[0]) ((CALayer *)self.mediaBar.layer.sublayers[0]).hidden = YES;
}

%new
- (void)camToggleValueChanged:(UISwitch *)sender
{
  saveOptionForKey(@(sender.isOn), kFakeCamera, kGlobalUser);
}

- (void)mediaContentSizeButtonTapped:(id)arg1
{
  %orig;
  // full screen statusbar paddding
  if (self._toggle.frame.origin.y == 5)
    self._toggle.frame = CGRectMake((self.mediaBar.frame.size.width-51)-50, 25, 51, 31);
  else
    self._toggle.frame = CGRectMake((self.mediaBar.frame.size.width-51)-50, 5, 51, 31);
}

- (void)openMediaBarTabContent:(id)arg1
{
  %orig;
  if (!self._toggle.superview)
  [self.mediaBar addSubview:self._toggle];

  self._toggle.frame = CGRectMake((self.mediaBar.frame.size.width-51)-50, 5, 51, 31);
}

- (void)openMediaBarTabContent:(id)arg1 withCompletionCallback:(void *)arg2
{
  %orig;
  if (!self._toggle.superview)
  [self.mediaBar addSubview:self._toggle];

  self._toggle.frame = CGRectMake((self.mediaBar.frame.size.width-51)-50, 5, 51, 31);
}

- (void)closeMediaBarTabContentWithMode:(int)arg1 animated:(_Bool)arg2
{
  if (self._toggle)
  [self._toggle removeFromSuperview];
  %orig;
}

- (void)closeMediaBarTabContentWithMode:(int)arg1 animated:(_Bool)arg2 withCompletionCallback:(void *)arg3
{
  if (self._toggle)
  [self._toggle removeFromSuperview];
  %orig;
}

- (void)animateWithContent:(id)arg1
{
  if (self._toggle)
  [self._toggle removeFromSuperview];
  %orig;
}

%new
- (UISwitch *)_toggle
{
  return objc_getAssociatedObject(self, @selector(_toggle));
}

%new
- (void)set_toggle:(UISwitch *)value
{
  objc_setAssociatedObject(self, @selector(_toggle), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)dealloc
{
  [self._toggle release];
  %orig;
}

%end

@interface KikMessage : NSObject
@property(nonatomic) BOOL needsCellHeightRecalc;
@property(nonatomic) BOOL hasContent;
@property(nonatomic, retain) NSString *body;
@end

@interface MessageCellDel : NSObject
- (void)deleteCell:(id)cell;
@end

@interface MessageCell : UITableViewCell
@property(retain, nonatomic) KikMessage *message; // @synthesize message=_message;
@property (nonatomic, assign) UIImageView *bubbleMask;
@property (nonatomic, retain) MessageCellDel *delegate;
@end

@interface MessageCellRenderer : NSObject
@property (nonatomic, retain) MessageCell *cell;
@end

@interface InOutMessageRenderer : MessageCellRenderer
@end

%hook InOutMessageRenderer

- (_Bool)shouldDisplayMessage:(id)arg1 // anti lag
{
  if (self.cell.message.body.length >= 2048) return NO;
  else return %orig;
}

%end

%hook KikMessage

- (BOOL)isMarkedDeleted
{
  if (((NSNumber *)getOptionForKey(kDelete, kGlobalUser)).boolValue) return YES;
  return %orig;
}

%end

%hook SmileyTranslator

- (BOOL)excludeSmiley:(id)arg1 withPrefix:(id)arg2 withSuffix:(id)arg3
{
  if (((NSNumber *)getOptionForKey(kDisableSmiley, kGlobalUser)).boolValue) return YES;
  return %orig;
}

%end

@interface KikChat : UIViewController
- (KikUser *)user;
@end

%hook KikChat

- (BOOL)amTyping
{
  if ([((NSNumber *)getOptionForKey(kTyping, self.user.username ? self.user.username : kGlobalUser)) boolValue]) return NO;
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
  UIImage *icon = [UIImage imageWithContentsOfFile:@"/Library/Application Support/kik8/kik8.png"];
  [newArr addObject:[[%c(SettingsOptionSubPane) alloc] initWithTitle:@"Kik8 Global Options" iconImage:icon subPaneClass:%c(KESettingsViewController)]];

  return newArr;
}

%end

@interface ProfileChatInfoViewController : UIViewController
- (KikUser *)user;
@end

%hook ProfileChatInfoViewController

- (NSArray *)generateSettingsOptions
{
  NSArray *arr = %orig;
  NSMutableArray *newArr = [NSMutableArray arrayWithArray:arr];

  if (self.user.username)
  [newArr addObject:[[%c(SettingsOptionSubPane) alloc] initWithTitle:[NSString stringWithFormat:@"Kik8 (%@) Options", self.user.username] iconImage:nil subPaneClass:%c(KESettingsViewController)]];

  return newArr;
}

%end

// Nightmode Color Stuff ^-^
%group NightMode
UIColor *const kDarkColor = [UIColor colorWithRed:0.157  green:0.157  blue:0.157 alpha:1];
UIColor *const kLightColor = [UIColor colorWithRed:0.945  green:0.945  blue:0.945 alpha:1];
UIColor *const kMidColor = [UIColor colorWithRed:0.283  green:0.283  blue:0.283 alpha:1];

@interface UIColor (Helpers)
+ (id)borderGreyColor;
+ (id)iOS7GreySelectionColor;
+ (id)iOS7BlueColor;
+ (id)colorFromHexString:(id)arg1;
+ (id)colorWithHexValue:(unsigned int)arg1;
@end

@interface BubbleColors : NSObject
+ (NSString *)colorHexFromColorEnum:(long long)enumv;
@end

@interface ConversationListCell : UITableViewCell
@property(retain, nonatomic) UILabel *message; // @synthesize message=_message;
@property(retain, nonatomic) UILabel *date; // @synthesize date=_date;
@property(retain, nonatomic) UILabel *title; // @synthesize title=_title;
@property(retain, nonatomic) UIImageView *status;
@end

static inline UIColor *bubbleColor()
{
  return [UIColor colorFromHexString:[%c(BubbleColors) colorHexFromColorEnum:[[NSUserDefaults standardUserDefaults] doubleForKey:@"bubbleColorEnum"]]];
}

%hook ConversationListCell

- (void)setBackgroundColor:(UIColor *)color
{
  color = kDarkColor;
  %orig;
}

- (void)updateMessageIcon
{
  %orig;
}

- (void)updateMessageStatus
{
  %orig;
  self.status.image = colorImageWithColor(self.status.image, bubbleColor());
}

- (void)updateMessageLabel
{
  %orig;
  self.title.textColor = kLightColor;
  self.date.textColor = kLightColor;
  self.message.textColor = kLightColor;
}

- (void)layoutSubviews
{
  %orig;

  self.title.textColor = kLightColor;
  self.date.textColor = kLightColor;
  self.message.textColor = kLightColor;

  self.status.image = colorImageWithColor(self.status.image, bubbleColor());
}

- (void)setSeparatorLine:(UIView *)view
{
  view.layer.backgroundColor = kMidColor.CGColor;
  %orig;
}

- (UIView *)separatorLine
{
  UIView *view = (UIView *)%orig;
  view.layer.backgroundColor = kMidColor.CGColor;
  return view;
}

- (void)setTopSeparatorLine:(UIView *)view
{
  view.layer.backgroundColor = kMidColor.CGColor;
  %orig;
}

- (UIView *)topSeparatorLine
{
  UIView *view = (UIView *)%orig;
  view.layer.backgroundColor = kMidColor.CGColor;
  return view;
}

%end

@interface MessageListTableviewController : UITableViewController
@end

%hook MessageListTableviewController

- (void)viewDidLoad
{
  %orig;
  self.tableView.backgroundColor = kDarkColor;
}

%end

%hook MessageCell

- (UIImageView *)bubbleMask
{
  UIImageView *o = (UIImageView *)%orig;
  // o.image = colorImageWithColor(o.image, kDarkColor);

  UIImage *theImage = o.image;
  UIEdgeInsets caps = [theImage capInsets];
  o.image = [[[colorImageWithColor(o.image, kDarkColor) imageWithAlignmentRectInsets:[theImage alignmentRectInsets]] imageWithRenderingMode:[theImage renderingMode]] resizableImageWithCapInsets:caps];

  return o;
}

- (UIImageView *)stateIcon
{
  UIImageView *o = (UIImageView *)%orig;

  o.image = colorImageWithColor(o.image, bubbleColor());

  return o;
}

%end

%hook MediaBarViewController

- (UIView *)mediaBar
{
  UIView *_mediaBar = (UIView *)%orig;
  _mediaBar.backgroundColor = kDarkColor;

  return _mediaBar;
}

%end

%hook UIView

- (id)addOnePxLeftBorder
{
  UIView *original = (UIView *)%orig;
  original.backgroundColor = kMidColor;
  return original;
}
- (id)addOnePxRightBorder
{
  UIView *original = (UIView *)%orig;
  original.backgroundColor = kMidColor;
  return original;
}
- (id)addOnePxBottomBorder
{
  UIView *original = (UIView *)%orig;
  original.backgroundColor = kMidColor;
  return original;
}
- (id)addOnePxTopBorder
{
  UIView *original = (UIView *)%orig;
  original.backgroundColor = kMidColor;
  return original;
}

%end

@interface TalkedToConversationListViewController : UITableViewController
@end

%hook TalkedToConversationListViewController

- (void)viewDidLoad
{
  %orig;
  self.tableView.separatorColor = kMidColor;
  self.tableView.backgroundColor = kDarkColor;
}

%end

%hook UINavigationBar

- (void)layoutSubviews
{
  %orig;
  self.barTintColor = kDarkColor;
  self.tintColor = bubbleColor();
  self.titleTextAttributes = @{ NSForegroundColorAttributeName : kLightColor};
}

%end

@interface NewPeopleFooterButton : UIButton
@end

%hook NewPeopleFooterButton

- (void)layoutSubviews
{
  %orig;
  self.backgroundColor = kDarkColor;
}

- (UIColor *)backgroundColor
{
  return kDarkColor;
}

- (void)setBackgroundColor:(UIColor *)color
{
  color = kDarkColor;
  %orig;
}

%end

@interface HPGrowingTextView : UITextView
@end

%hook HPGrowingTextView

- (void)setTextColor:(UIColor *)textColor
{
  textColor = [UIColor whiteColor];
  %orig;
}

- (UIColor *)textColor
{
  return [UIColor whiteColor];
}

- (void)textViewDidBeginEditing:(id)arg1
{
  %orig;
  [self setTextColor:[UIColor whiteColor]];
}

- (void)layoutSubviews
{
  %orig;
  [self setTextColor:[UIColor whiteColor]];
}

%end

@interface TwoLayerButton : UIButton
@property (nonatomic, retain) UIImageView *topImageView;
@end

@interface MediaContentTabs : UIView
@property (nonatomic, retain) UIButton *mediaButton;
@end

%hook MediaContentTabs

- (UIButton *)mediaButton
{
  TwoLayerButton *original = (TwoLayerButton *)%orig;
  original.imageView.image = colorImageWithColor(original.imageView.image, bubbleColor());
  return original;
}

- (void)showButton:(UIButton *)button withAnimation:(_Bool)arg2 andDelay:(double)arg3
{
  [button setImage:colorImageWithColor([button imageForState:UIControlStateNormal], bubbleColor()) forState:UIControlStateNormal];
  [button setImage:colorImageWithColor([button imageForState:UIControlStateHighlighted], bubbleColor()) forState:UIControlStateHighlighted];
  [button setImage:colorImageWithColor([button imageForState:UIControlStateSelected], bubbleColor()) forState:UIControlStateSelected];
  [button setImage:colorImageWithColor([button imageForState:UIControlStateDisabled], bubbleColor()) forState:UIControlStateDisabled];
  %orig;
}

%end

@interface MediaContentSendMessage
@property(readonly, nonatomic) UIButton *sendButton; // @synthesize sendButton=_sendButton;
@property(readonly, nonatomic) UIButton *smileyButton; // @synthesize smileyButton=_smileyButton;
@end

%hook MediaContentSendMessage

- (UIButton *)smileyButton
{
  UIButton *smileyButton = (UIButton *)%orig;
  [smileyButton setImage:colorImageWithColor([smileyButton imageForState:UIControlStateNormal], bubbleColor()) forState:UIControlStateNormal];
  [smileyButton setImage:colorImageWithColor([smileyButton imageForState:UIControlStateHighlighted], bubbleColor()) forState:UIControlStateHighlighted];
  [smileyButton setImage:colorImageWithColor([smileyButton imageForState:UIControlStateDisabled], bubbleColor()) forState:UIControlStateDisabled];
  return smileyButton;
}

- (UIButton *)sendButton
{
  UIButton *sendButton = (UIButton *)%orig;
  [sendButton setImage:colorImageWithColor([sendButton imageForState:UIControlStateNormal], bubbleColor()) forState:UIControlStateNormal];
  [sendButton setImage:colorImageWithColor([sendButton imageForState:UIControlStateHighlighted], bubbleColor()) forState:UIControlStateHighlighted];
  [sendButton setImage:colorImageWithColor([sendButton imageForState:UIControlStateDisabled], bubbleColor()) forState:UIControlStateDisabled];
  return sendButton;
}

%end

@interface HighlightedUIButton : UIButton
- (UIImage *)image;
@end

%hook HighlightedUIButton

- (void)didMoveToSuperview
{
  %orig;
  [self setImage:colorImageWithColor([self imageForState:UIControlStateNormal], bubbleColor()) forState:UIControlStateNormal];
}

%end

%hook UIStatusBarNewUIStyleAttributes

- (id)initWithRequest:(id)style backgroundColor:(id)backgroundColor foregroundColor:(id)foregroundColor
{
  //  arg3 = newForegroundColor;


  foregroundColor = bubbleColor();

  self = %orig;
  return self;
}

%end

%hook UIColor

+ (UIColor *)iOS7BlueColor
{
  return bubbleColor();
}

%end

%end

// Settings

@interface SettingsOptionBase : NSObject
@property(nonatomic, retain) NSString *optionKey;
@property(nonatomic, retain) KESettingsViewController *KEManager;
@end

@interface SettingsOptionToggle : SettingsOptionBase
{
  UIImage *_iconImage;
  NSString *_title;
  UISwitch *_toggle;
}

@property(retain, nonatomic) UISwitch *toggle; // @synthesize toggle=_toggle;
@property(copy, nonatomic) NSString *title; // @synthesize title=_title;
@property(retain, nonatomic) UIImage *iconImage; // @synthesize iconImage=_iconImage;

- (void)toggleValueChanged:(id)arg1;
- (void)configureCell:(id)arg1 forSettingsPane:(id)arg2;
- (id)initWithTitle:(id)arg1 iconImage:(id)arg2 on:(_Bool)arg3 executeOnToggle:(void *)arg4;
+ (id)optionWithTitle:(id)arg1 iconImage:(id)arg2 optionKey:(NSString *)key KEManager:(KESettingsViewController *)KEManager;

@end

@interface UINavigationController()
- (UIViewController *)previousViewController;
@end

@interface SettingsPane : UIViewController
- (NSMutableArray *)generateSettingsOptions;
@end

@interface KESettingsViewController : SettingsPane /*<UITableViewDataSource, UITableViewDelegate>*/
// @property (nonatomic, retain) UITableView *tableView;
// - (void)setup;
@property (nonatomic, retain) NSString *username;

- (void)saveOption:(NSObject *)obj forKey:(NSString *)key;
- (NSObject *)getOptionForKey:(NSString *)key;
@end

%hook SettingsOptionBase

%new
- (NSString *)optionKey
{
  return objc_getAssociatedObject(self, @selector(optionKey));
}

%new
- (void)setOptionKey:(NSString *)value
{
  objc_setAssociatedObject(self, @selector(optionKey), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new
- (KESettingsViewController *)KEManager
{
  return objc_getAssociatedObject(self, @selector(KEManager));
}

%new
- (void)setKEManager:(KESettingsViewController *)value
{
  objc_setAssociatedObject(self, @selector(KEManager), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%end

%hook SettingsOptionToggle

- (void)toggleValueChanged:(id)arg1
{
  if (self.optionKey && self.KEManager)
  {
    BOOL saveVal = self.toggle.isOn;
    [self.KEManager saveOption:@(saveVal) forKey:self.optionKey];
    return;
  }
  %orig;
}

%new
+ (id)optionWithTitle:(id)arg1 iconImage:(id)arg2 optionKey:(NSString *)key KEManager:(KESettingsViewController *)KEManager
{
  NSNumber *obj = (NSNumber *)[KEManager getOptionForKey:key];
  if (!obj) obj = @NO;
  SettingsOptionToggle *s = [[[%c(SettingsOptionToggle) alloc] initWithTitle:arg1 iconImage:arg2 on:[obj boolValue] executeOnToggle:NULL] autorelease];
  s.KEManager = KEManager;
  s.optionKey = key;

  return s;
}

%end

@interface SettingsOptionButton : SettingsOptionBase
- (id)initWithTitle:(NSString *)arg1 iconImage:(UIImage *)arg2 executeOnTap:(void *)arg3;
@end


%subclass KESettingsViewController : SettingsPane

- (void)loadView
{
  %orig;
  UIViewController *con = self.navigationController.previousViewController;

  if ([con isKindOfClass:%c(ProfileChatInfoViewController)])
  {
    ProfileChatInfoViewController *profVC = (ProfileChatInfoViewController *)con;
    self.username = profVC.user.username;
  }
}

- (void)viewDidLoad
{
  %orig;
  self.title = @"Kik8";
}

%new
- (NSString *)username
{
  return objc_getAssociatedObject(self, @selector(username));
}

%new
- (void)setUsername:(NSString *)value
{
  objc_setAssociatedObject(self, @selector(username), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new
- (void)saveOption:(NSObject *)obj forKey:(NSString *)key
{
  saveOptionForKey(obj, key, self.username);
}

%new
- (NSObject *)getOptionForKey:(NSString *)key
{
  return getOptionForKey(key, self.username);
}

- (id)initWithCore:(id)core
{
  self = %orig;
  self.username = kGlobalUser;
  // [self setup];
  return self;
}

%new
- (NSArray *)generateSettingsOptions
{
  NSArray *newArr =
  @[
  [%c(SettingsOptionToggle) optionWithTitle:@"Disable Deliver Receipts" iconImage:nil optionKey:kDeliveredReceipts KEManager:self],
  [%c(SettingsOptionToggle) optionWithTitle:@"Disable Read Receipts" iconImage:nil optionKey:kReadReceipts KEManager:self],
  [%c(SettingsOptionToggle) optionWithTitle:@"Disable is typing..." iconImage:nil optionKey:kTyping KEManager:self]
  ];

  NSMutableArray *mutableNewArr = [NSMutableArray arrayWithArray:newArr];

  if (![self.username isEqualToString:kGlobalUser]) // not global
  [mutableNewArr insertObject:[%c(SettingsOptionToggle) optionWithTitle:@"Disable Custom Settings For This User" iconImage:nil optionKey:kUserDisabled KEManager:self] atIndex:0];

  if ([self.username isEqualToString:kGlobalUser]) // global only
  {
    [mutableNewArr addObject:[%c(SettingsOptionToggle) optionWithTitle:@"Night/Dark Mode" iconImage:nil optionKey:kEnableNightMode KEManager:self]];
    [mutableNewArr addObject:[%c(SettingsOptionToggle) optionWithTitle:@"Enable Unlimited Video Recording Time" iconImage:nil optionKey:kUnlimitedVideo KEManager:self]];
    [mutableNewArr addObject:[%c(SettingsOptionToggle) optionWithTitle:@"Enable Square Theme" iconImage:nil optionKey:kSquareTheme KEManager:self]];
    [mutableNewArr addObject:[%c(SettingsOptionToggle) optionWithTitle:@"Disable Smiley Icons" iconImage:nil optionKey:kDisableSmiley KEManager:self]];
    [mutableNewArr addObject:[%c(SettingsOptionToggle) optionWithTitle:@"Unlock All Smileys" iconImage:nil optionKey:kUnlockSmiley KEManager:self]];

    // Kill Kik
    [mutableNewArr addObject:[[%c(SettingsOptionButton) alloc] initWithTitle:@"QUIT KIK" iconImage:nil executeOnTap:^(void){
      system("killall -9 Kik");
    }]];
  }

  // [newArr addObject:[[%c(SettingsOptionSubPane) alloc] initWithTitle:@"Kik8 Options" iconImage:nil subPaneClass:%c(KESettingsViewController)]];

  return (NSArray *)mutableNewArr;
}

%new
- (void)dealloc
{
  // [self.tableView release];
  [self.username release];

  // [super dealloc];
}

%end

%ctor {
  if (((NSNumber *)getOptionForKey(kEnableNightMode, kGlobalUser)).boolValue)
  %init(NightMode);

  %init(_ungrouped)
  copySmileys();
}
