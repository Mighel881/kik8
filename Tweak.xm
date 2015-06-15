#define PLIST_PATH @"/var/mobile/Library/Preferences/com.niro.Kik8.plist"
 
inline bool GetPrefBool(NSString *key)
{
return [[[NSDictionary dictionaryWithContentsOfFile:PLIST_PATH] valueForKey:key] boolValue];
}

%hook KikParsedMessage

-(bool)drRequested {
if(GetPrefBool(@"kDeliveredReceipts")) {
return FALSE;
}
return %orig;
}

-(bool)rrRequested {
if(GetPrefBool(@"kReadReceipts")) {
return FALSE;
}
return %orig;
}

%end


%hook KikAPIMessage

-(bool)disableForwarding {
return FALSE;
}

-(void)setAppID:(NSString *)argument {
if(GetPrefBool(@"kFakeCamera")) {
argument = [[NSString alloc] initWithString:@"com.kik.ext.camera"];
}
return %orig;
}

%end


%hook KikMessage

-(bool)isMarkedDeleted {
if(GetPrefBool(@"kDelete")) {
return TRUE;
}
return %orig;
}

%end


%hook KikChat

-(bool)amTyping {
if(GetPrefBool(@"kTyping")) {
return FALSE;
}
return %orig;
}

%end