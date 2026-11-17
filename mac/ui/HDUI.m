#import "HDUI.h"
#import "HDSymbols.h"
#import <QuartzCore/QuartzCore.h>

static NSColor *HDHex(NSString *hex) {
  unsigned int v = 0;
  NSScanner *scanner = [NSScanner scannerWithString:[hex stringByReplacingOccurrencesOfString:@"#" withString:@""]];
  [scanner scanHexInt:&v];
  return [NSColor colorWithSRGBRed:((v >> 16) & 0xff) / 255.0
                             green:((v >> 8) & 0xff) / 255.0
                              blue:(v & 0xff) / 255.0
                             alpha:1];
}

static BOOL HDDark(NSAppearance *appearance) {
  return [[appearance bestMatchFromAppearancesWithNames:@[NSAppearanceNameDarkAqua, NSAppearanceNameAqua]] isEqualToString:NSAppearanceNameDarkAqua];
}

// Brand tokens: deep violet for actions, soft lavender for selection.
// Content stays neutral so previews and live/error indicators keep their meaning.
static NSColor *HDAccent(void) { return HDHex(@"#7042C1"); }
static NSColor *HDAccentText(void) {
  return [NSColor colorWithName:nil dynamicProvider:^NSColor *(NSAppearance *appearance) {
    return HDDark(appearance) ? HDHex(@"#CCB5FF") : HDHex(@"#6236AD");
  }];
}
static NSColor *HDSelection(void) {
  return [NSColor colorWithName:nil dynamicProvider:^NSColor *(NSAppearance *appearance) {
    return HDDark(appearance) ? HDHex(@"#332448") : HDHex(@"#EEE6FA");
  }];
}

static NSColor *HDInk(void) {
  return [NSColor colorWithName:nil dynamicProvider:^NSColor *(NSAppearance *appearance) {
    return HDDark(appearance) ? HDHex(@"#151318") : HDHex(@"#F7F6FA");
  }];
}

static NSColor *HDSurface(void) {
  return [NSColor colorWithName:nil dynamicProvider:^NSColor *(NSAppearance *appearance) {
    return HDDark(appearance) ? HDHex(@"#201D25") : HDHex(@"#FFFFFF");
  }];
}

static NSColor *HDHairline(void) {
  return [NSColor colorWithName:nil dynamicProvider:^NSColor *(NSAppearance *appearance) {
    return HDDark(appearance) ? HDHex(@"#39333F") : HDHex(@"#E4DFEA");
  }];
}

static NSColor *HDText(void) {
  return [NSColor colorWithName:nil dynamicProvider:^NSColor *(NSAppearance *appearance) {
    return HDDark(appearance) ? HDHex(@"#F4F4F5") : HDHex(@"#111113");
  }];
}

static NSColor *HDMuted(void) {
  return [NSColor colorWithName:nil dynamicProvider:^NSColor *(NSAppearance *appearance) {
    return HDDark(appearance) ? HDHex(@"#B6AFBF") : HDHex(@"#696172");
  }];
}

// Snapshot dynamic colors under the owning view's appearance before AppKit tints icons.
static NSColor *HDResolved(NSColor *color, NSAppearance *appearance) {
  __block NSColor *resolved;
  [appearance performAsCurrentDrawingAppearance:^{ resolved = [NSColor colorWithCGColor:color.CGColor]; }];
  return resolved;
}

static NSColor *HDGood(void) { return HDHex(@"#10B981"); }
static NSColor *HDWarn(void) { return HDHex(@"#F59E0B"); }
static NSColor *HDLive(void) { return HDHex(@"#EF4444"); }

static NSFont *HDMono(CGFloat size) {
  NSFont *font = [NSFont fontWithName:@"JetBrainsMono-Regular" size:size];
  if (!font) font = [NSFont fontWithName:@"GeistMono-Regular" size:size];
  if (!font) font = [NSFont monospacedSystemFontOfSize:size weight:NSFontWeightRegular];
  return font;
}

static NSFont *HDTabular(CGFloat size) {
  NSFont *mono = [NSFont fontWithName:@"JetBrainsMono-Regular" size:size];
  if (mono) return mono;
  return [NSFont monospacedDigitSystemFontOfSize:size weight:NSFontWeightRegular];
}

static NSTextField *HDLabel(NSString *text, CGFloat size, NSFontWeight weight, NSColor *color) {
  NSTextField *field = [NSTextField labelWithString:text ?: @""];
  field.font = [NSFont systemFontOfSize:size weight:weight];
  field.textColor = color ?: NSColor.labelColor;
  field.maximumNumberOfLines = 0;
  field.lineBreakMode = NSLineBreakByWordWrapping;
  return field;
}

static NSTextField *HDCaption(NSString *text) {
  return HDLabel(text, 11, NSFontWeightRegular, NSColor.secondaryLabelColor);
}

@interface HDPrimaryButton : NSButton
- (void)refreshColors;
@end
@implementation HDPrimaryButton {
  BOOL _hover;
  NSTrackingArea *_tracking;
}
- (NSSize)intrinsicContentSize {
  NSSize size = [super intrinsicContentSize];
  size.width += 24; // Custom drawing needs the native control's horizontal breathing room.
  return size;
}
- (void)refreshColors {
  self.wantsLayer = YES;
  self.layer.cornerRadius = 7;
  self.contentTintColor = NSColor.whiteColor;
  self.needsDisplay = YES;
}
- (void)drawRect:(NSRect)dirtyRect {
  NSColor *fill = HDAccent();
  if (!self.enabled) fill = NSColor.quaternaryLabelColor;
  else if (_hover || self.highlighted) fill = [fill blendedColorWithFraction:0.12 ofColor:NSColor.blackColor];
  [fill setFill];
  [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds, 0, 1) xRadius:7 yRadius:7] fill];
  NSDictionary *attributes = @{NSFontAttributeName:self.font, NSForegroundColorAttributeName:self.enabled ? NSColor.whiteColor : NSColor.disabledControlTextColor};
  NSSize size = [self.title sizeWithAttributes:attributes];
  CGFloat iconSize = self.image ? 13 : 0;
  CGFloat gap = self.image ? 7 : 0;
  CGFloat left = round((self.bounds.size.width - size.width - iconSize - gap) / 2);
  if (self.image) {
    NSImage *source = self.image;
    NSImage *icon = [NSImage imageWithSize:NSMakeSize(iconSize, iconSize) flipped:NO drawingHandler:^BOOL(NSRect rect) {
      [source drawInRect:rect];
      [(self.enabled ? NSColor.whiteColor : NSColor.disabledControlTextColor) setFill];
      NSRectFillUsingOperation(rect, NSCompositingOperationSourceIn);
      return YES;
    }];
    [icon drawInRect:NSMakeRect(left, round((self.bounds.size.height-iconSize)/2), iconSize, iconSize)];
  }
  [self.title drawAtPoint:NSMakePoint(left + iconSize + gap, round((self.bounds.size.height-size.height)/2)) withAttributes:attributes];
  if (self.window.firstResponder == self && NSApp.isActive) {
    [NSColor.keyboardFocusIndicatorColor setStroke];
    NSBezierPath *focus = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds, 1, 2) xRadius:6 yRadius:6];
    focus.lineWidth = 2; [focus stroke];
  }
}
- (void)updateTrackingAreas {
  [super updateTrackingAreas];
  if (_tracking) [self removeTrackingArea:_tracking];
  _tracking = [[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect owner:self userInfo:nil];
  [self addTrackingArea:_tracking];
}
- (void)mouseEntered:(NSEvent *)event { _hover = YES; [self refreshColors]; }
- (void)mouseExited:(NSEvent *)event { _hover = NO; [self refreshColors]; }
- (void)setEnabled:(BOOL)enabled { [super setEnabled:enabled]; [self refreshColors]; }
- (void)viewDidChangeEffectiveAppearance { [super viewDidChangeEffectiveAppearance]; [self refreshColors]; }
@end

static NSButton *HDButtonWithSymbol(NSString *title, id target, SEL action, BOOL primary, HDSymbolRole role) {
  NSButton *button = primary ? [HDPrimaryButton buttonWithTitle:title target:target action:action] : [NSButton buttonWithTitle:title target:target action:action];
  button.controlSize = NSControlSizeRegular;
  button.font = [NSFont systemFontOfSize:12.5 weight:NSFontWeightMedium];
  [button.heightAnchor constraintEqualToConstant:32].active = YES;
  if (role != NSNotFound) {
    button.image = HDSymbolImage(role, 12, NSFontWeightMedium, title);
    button.imagePosition = NSImageLeading;
    button.imageHugsTitle = YES;
  }
  if (primary) {
    button.bezelStyle = NSBezelStyleRounded;
    button.bordered = NO;
    button.wantsLayer = YES;
    [(HDPrimaryButton *)button refreshColors];
    button.layer.cornerRadius = 7;
  } else {
    button.bezelStyle = NSBezelStyleRounded;
    button.bordered = YES;
    button.contentTintColor = NSColor.secondaryLabelColor;
  }
  return button;
}

static NSButton *HDButton(NSString *title, id target, SEL action, BOOL primary) {
  return HDButtonWithSymbol(title, target, action, primary, NSNotFound);
}

@interface HDCanvasView : NSView
@end
@implementation HDCanvasView
- (BOOL)wantsUpdateLayer { return YES; }
- (void)updateLayer {
  [self.effectiveAppearance performAsCurrentDrawingAppearance:^{
    self.layer.backgroundColor = HDInk().CGColor;
  }];
}
- (void)viewDidChangeEffectiveAppearance { [super viewDidChangeEffectiveAppearance]; self.needsDisplay = YES; }
@end

@interface HDSurfaceView : NSView
@end
@implementation HDSurfaceView
- (BOOL)wantsUpdateLayer { return YES; }
- (void)updateLayer {
  [self.effectiveAppearance performAsCurrentDrawingAppearance:^{
    self.layer.backgroundColor = HDSurface().CGColor;
  }];
}
- (void)viewDidChangeEffectiveAppearance { [super viewDidChangeEffectiveAppearance]; self.needsDisplay = YES; }
@end

@interface HDRuleView : NSView
@end
@implementation HDRuleView
- (BOOL)wantsUpdateLayer { return YES; }
- (void)updateLayer {
  [self.effectiveAppearance performAsCurrentDrawingAppearance:^{
    self.layer.backgroundColor = HDHairline().CGColor;
  }];
}
- (void)viewDidChangeEffectiveAppearance { [super viewDidChangeEffectiveAppearance]; self.needsDisplay = YES; }
@end

@interface HDEventLabel : NSTextField
@end
@implementation HDEventLabel
- (void)setStringValue:(NSString *)value { [super setStringValue:value ?: @""]; self.hidden = !value.length; }
@end

@interface HDDocumentView : NSView
@end
@implementation HDDocumentView
- (BOOL)isFlipped { return YES; }
@end

@interface HDCardView : NSView
@property BOOL destinationSelected;
@end

@implementation HDCardView {
  NSTrackingArea *_tracking;
}
- (instancetype)initWithFrame:(NSRect)frameRect {
  self = [super initWithFrame:frameRect];
  if (self) {
    self.wantsLayer = YES;
    self.layer.cornerRadius = 10;
    self.layer.borderWidth = 1;
    [self updateLayerColors];
  }
  return self;
}
- (void)viewDidChangeEffectiveAppearance {
  [super viewDidChangeEffectiveAppearance];
  [self updateLayerColors];
}
- (void)updateLayerColors {
  [self.effectiveAppearance performAsCurrentDrawingAppearance:^{
    self.layer.backgroundColor = (self.destinationSelected ? HDSelection() : HDSurface()).CGColor;
    self.layer.borderColor = (self.destinationSelected ? HDAccentText() : HDHairline()).CGColor;
    self.layer.borderWidth = self.destinationSelected ? 2 : 1;
  }];
}
@end

@interface HDNavButton : NSButton
@end

@implementation HDNavButton {
  BOOL _selected;
  HDSymbolRole _role;
}
- (instancetype)initWithTitle:(NSString *)title role:(HDSymbolRole)role target:(id)target action:(SEL)action {
  self = [super initWithFrame:NSZeroRect];
  if (self) {
    _role = role;
    self.title = title;
    self.image = HDSymbolImage(role, 13, NSFontWeightMedium, title);
    self.imagePosition = NSImageLeading;
    self.imageScaling = NSImageScaleProportionallyDown;
    self.alignment = NSTextAlignmentLeft;
    self.bordered = NO;
    self.bezelStyle = NSBezelStyleInline;
    self.font = [NSFont systemFontOfSize:12.5 weight:NSFontWeightMedium];
    self.contentTintColor = NSColor.secondaryLabelColor;
    self.target = target;
    self.action = action;
    self.wantsLayer = YES;
    self.layer.cornerRadius = 7;
    [self.heightAnchor constraintEqualToConstant:36].active = YES;
  }
  return self;
}
- (void)setSelectedAppearance:(BOOL)selected {
  _selected = selected;
  self.layer.backgroundColor = NSColor.clearColor.CGColor;
  self.contentTintColor = HDResolved(selected ? HDAccentText() : HDMuted(), self.effectiveAppearance);
  self.needsDisplay = YES;
  self.font = [NSFont systemFontOfSize:12.5 weight:selected ? NSFontWeightSemibold : NSFontWeightMedium];
  self.image = selected ? HDSymbolSelectedImage(_role, 13, NSFontWeightSemibold, self.title)
                        : HDSymbolImage(_role, 13, NSFontWeightMedium, self.title);
}
- (void)drawRect:(NSRect)dirtyRect {
  if (_selected) {
    [HDSelection() setFill];
    [[NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:7 yRadius:7] fill];
  }
  [super drawRect:dirtyRect];
}
- (void)viewDidChangeEffectiveAppearance {
  [super viewDidChangeEffectiveAppearance];
  [self setSelectedAppearance:_selected];
}
@end

@interface HDUI ()
@property(strong) NSWindow *window;
@property(strong) NSStackView *recentRows;
@property(strong) NSView *libraryEmptyView;
@property(strong) NSScrollView *libraryScroll;
@property(strong) NSTextField *libraryEmptyTitle;
@property(strong) NSTextField *libraryEmptyBody;
@property(strong) NSButton *libraryEmptyAction;
@property(strong) NSStackView *storageAdvancedOptions;
@property(strong) NSStackView *advancedOptions;
@property(strong) NSArray<NSDictionary *> *recentEntries;
@property(strong) NSTextField *sessionSummary;
@property(strong) NSTextField *licenseTerms;
@property(strong) NSStackView *licenseEntry;
@property(strong) NSStackView *licenseActions;
@property(strong) NSStackView *storageFolderRow;
@property(strong) NSButton *localFolderButton;
@property(strong) NSTextField *localOutputPathLabel;
@property(strong) NSStackView *localOutputBox;
@property(strong) NSStackView *onboardingStorageRow;
@property(weak) id target;
@property(strong) NSView *sidebar;
@property(strong) NSView *pageHost;
@property(strong) NSView *capturePage;
@property(strong) NSView *clipsPage;
@property(strong) NSView *storagePage;
@property(strong) NSView *licensePage;
@property(strong) NSView *settingsPage;
@property(strong) NSMutableArray<HDNavButton *> *navButtons;
@property(strong) NSStackView *sidebarStatusStack;
@property(strong) NSTextField *sidebarStatusText;
@property(strong) NSImageView *sidebarStatusIcon;
@property(strong) NSImageView *licenseStatusIcon;
@property(strong) NSWindow *onboardingWindow;
@property(strong) NSTextField *captureHeroTitle;
@property(strong) NSTextField *captureHeroSubtitle;
@property(strong) NSTextField *clipMetric;
@property(strong) NSTextField *queueMetric;
@property(strong) NSTextField *storageMetric;
@property(strong) NSTextField *trialMetric;
@property(strong) NSTextField *clipsMetricCaption;
@property(strong) NSTextField *queueMetricCaption;
@property(strong) NSTextField *storageMetricCaption;
@property(strong) NSTextField *trialMetricCaption;
@property(strong) NSImageView *recentEmptyIcon;
@property(strong) HDCardView *selectedStorageCard;
@property(strong) NSMutableArray<NSButton *> *storageCardButtons;
@property(strong) NSMutableArray<NSImageView *> *storageSelectionBadges;
@property(strong) NSTextField *onboardingTitle;
@property(strong) NSTextField *onboardingBody;
@property(strong) NSButton *onboardingContinue;
@property(strong) NSButton *onboardingBack;
@property NSInteger onboardingStep;
@property(strong) NSStackView *liveBox;
@property(strong) NSStackView *vodBox;
@property(strong) NSStackView *vodOptionsBox;
@property(strong) NSButton *vodOptionsDisclosure;
@property BOOL liveRunning;
@end


@implementation HDUI

- (instancetype)initWithTarget:(id)target {
  self = [super init];
  if (!self) return nil;
  _target = target;
  _navButtons = [NSMutableArray array];
  _storageCardButtons = [NSMutableArray array];
  _storageSelectionBadges = [NSMutableArray array];
  [self buildWindow];
  [self buildSidebar];
  [self buildCapturePage];
  [self buildClipsPage];
  [self buildStoragePage];
  [self buildLicensePage];
  [self buildSettingsPage];
  for (NSView *page in @[self.capturePage, self.storagePage, self.licensePage, self.settingsPage]) {
    NSScrollView *scroll = page.subviews.firstObject;
    NSStackView *stack = (NSStackView *)scroll.documentView.subviews.firstObject;
    if ([stack isKindOfClass:NSStackView.class] && stack.arrangedSubviews.count) [stack setCustomSpacing:4 afterView:stack.arrangedSubviews.firstObject];
  }
  [self selectPage:HDPageCapture];
  [self.window makeFirstResponder:nil];
  return self;
}

- (void)buildWindow {
  NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 1080, 720)
                                                 styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable | NSWindowStyleMaskFullSizeContentView
                                                   backing:NSBackingStoreBuffered
                                                     defer:NO];
  window.title = @"Highlight Desk";
  window.titleVisibility = NSWindowTitleHidden;
  window.titlebarAppearsTransparent = YES;
  window.movableByWindowBackground = NO;
  window.minSize = NSMakeSize(960, 640);
  window.releasedWhenClosed = NO;
  [window setFrameAutosaveName:@"HDMainWindow"];
  if (window.frame.size.width < 960 || window.frame.size.height < 640) {
    [window setContentSize:NSMakeSize(1080, 720)];
  }
  self.window = window;

  NSView *contentRoot = window.contentView;
  contentRoot.wantsLayer = YES;
  contentRoot.layer.backgroundColor = HDInk().CGColor;
  NSView *root = [[HDCanvasView alloc] initWithFrame:contentRoot.bounds];
  root.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  root.wantsLayer = YES;
  root.layer.backgroundColor = HDInk().CGColor;
  [contentRoot addSubview:root];

  HDSurfaceView *sidebar = [[HDSurfaceView alloc] initWithFrame:NSZeroRect];
  sidebar.wantsLayer = YES;
  sidebar.translatesAutoresizingMaskIntoConstraints = NO;
  [root addSubview:sidebar];
  self.sidebar = sidebar;

  NSView *content = [[HDCanvasView alloc] initWithFrame:NSZeroRect];
  content.translatesAutoresizingMaskIntoConstraints = NO;
  content.wantsLayer = YES;
  content.layer.backgroundColor = HDInk().CGColor;
  [root addSubview:content];

  HDRuleView *divider = [[HDRuleView alloc] initWithFrame:NSZeroRect];
  divider.translatesAutoresizingMaskIntoConstraints = NO;
  divider.wantsLayer = YES;
  [root addSubview:divider];

  [NSLayoutConstraint activateConstraints:@[
    [sidebar.leadingAnchor constraintEqualToAnchor:root.leadingAnchor],
    [sidebar.topAnchor constraintEqualToAnchor:root.topAnchor],
    [sidebar.bottomAnchor constraintEqualToAnchor:root.bottomAnchor],
    [sidebar.widthAnchor constraintEqualToConstant:204],
    [content.leadingAnchor constraintEqualToAnchor:sidebar.trailingAnchor],
    [divider.leadingAnchor constraintEqualToAnchor:sidebar.trailingAnchor],
    [divider.topAnchor constraintEqualToAnchor:root.topAnchor],
    [divider.bottomAnchor constraintEqualToAnchor:root.bottomAnchor],
    [divider.widthAnchor constraintEqualToConstant:1],
    [content.trailingAnchor constraintEqualToAnchor:root.trailingAnchor],
    [content.topAnchor constraintEqualToAnchor:root.topAnchor],
    [content.bottomAnchor constraintEqualToAnchor:root.bottomAnchor]
  ]];

  NSView *pageHost = [[NSView alloc] initWithFrame:NSZeroRect];
  pageHost.translatesAutoresizingMaskIntoConstraints = NO;
  [content addSubview:pageHost];
  self.pageHost = pageHost;
  [NSLayoutConstraint activateConstraints:@[
    [pageHost.leadingAnchor constraintEqualToAnchor:content.leadingAnchor],
    [pageHost.trailingAnchor constraintEqualToAnchor:content.trailingAnchor],
    [pageHost.topAnchor constraintEqualToAnchor:content.topAnchor],
    [pageHost.bottomAnchor constraintEqualToAnchor:content.bottomAnchor]
  ]];
}

- (void)buildSidebar {
  NSStackView *stack = [NSStackView new];
  stack.orientation = NSUserInterfaceLayoutOrientationVertical;
  stack.alignment = NSLayoutAttributeLeading;
  stack.spacing = 5;
  stack.translatesAutoresizingMaskIntoConstraints = NO;
  [self.sidebar addSubview:stack];
  [NSLayoutConstraint activateConstraints:@[
    [stack.leadingAnchor constraintEqualToAnchor:self.sidebar.leadingAnchor constant:14],
    [stack.trailingAnchor constraintEqualToAnchor:self.sidebar.trailingAnchor constant:-14],
    [stack.topAnchor constraintEqualToAnchor:self.sidebar.topAnchor constant:52],
    [stack.bottomAnchor constraintEqualToAnchor:self.sidebar.bottomAnchor constant:-18]
  ]];
  NSStackView *brand = [NSStackView new];
  brand.orientation = NSUserInterfaceLayoutOrientationHorizontal;
  brand.alignment = NSLayoutAttributeCenterY; brand.spacing = 8;
  NSImageView *icon = [NSImageView new]; icon.image = NSApp.applicationIconImage;
  [icon.widthAnchor constraintEqualToConstant:28].active = YES;
  [icon.heightAnchor constraintEqualToConstant:28].active = YES;
  [brand addArrangedSubview:icon];
  [brand addArrangedSubview:HDLabel(@"Highlight Desk", 13, NSFontWeightSemibold, NSColor.labelColor)];
  [stack addArrangedSubview:brand]; [stack setCustomSpacing:24 afterView:brand];
  NSArray *items = @[
    @[@"Capture", @(HDSymbolRoleCapture), @(HDPageCapture)],
    @[@"Clips", @(HDSymbolRoleClips), @(HDPageClips)],
    @[@"Storage", @(HDSymbolRoleStorage), @(HDPageStorage)]
  ];
  for (NSArray *item in items) {
    HDNavButton *button = [[HDNavButton alloc] initWithTitle:item[0] role:[item[1] integerValue] target:self action:@selector(navClicked:)];
    button.tag = [item[2] integerValue]; [self.navButtons addObject:button];
    [stack addArrangedSubview:button];
    [button.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active = YES;
  }
  [stack addArrangedSubview:[self flexSpacer]];
  NSBox *footerRule = [NSBox new];
  footerRule.boxType = NSBoxSeparator;
  [stack addArrangedSubview:footerRule];
  [footerRule.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active = YES;
  [stack setCustomSpacing:10 afterView:footerRule];
  NSStackView *status = [NSStackView new]; status.spacing = 7;
  status.orientation = NSUserInterfaceLayoutOrientationHorizontal;
  status.alignment = NSLayoutAttributeCenterY;
  self.sidebarStatusIcon = HDSymbolImageView(HDSymbolRoleStatusReady, 11, NSColor.secondaryLabelColor, @"Capture status");
  self.sidebarStatusText = HDLabel(@"Idle", 11, NSFontWeightRegular, NSColor.secondaryLabelColor);
  [status addArrangedSubview:self.sidebarStatusIcon]; [status addArrangedSubview:self.sidebarStatusText];
  [stack addArrangedSubview:status]; [stack setCustomSpacing:12 afterView:status];
  HDNavButton *settings = [[HDNavButton alloc] initWithTitle:@"Settings" role:HDSymbolRoleSettings target:self action:@selector(settingsClicked:)];
  settings.tag = HDPageSettings; [self.navButtons addObject:settings];
  [stack addArrangedSubview:settings]; [settings.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active = YES;
}

- (void)navClicked:(HDNavButton *)sender {
  [self selectPage:(HDPage)sender.tag];
}

- (void)settingsClicked:(id)sender {
  [self selectPage:HDPageSettings];
}

- (void)selectPage:(HDPage)page {
  NSArray *pages = @[self.capturePage, self.clipsPage, self.storagePage, self.licensePage, self.settingsPage];
  for (NSInteger i = 0; i < pages.count; i++) {
    NSView *view = pages[i];
    if (!view) continue;
    view.hidden = (i != (NSInteger)page);
  }
  for (HDNavButton *button in self.navButtons) {
    [button setSelectedAppearance:button.tag == (NSInteger)page || (page == HDPageLicense && button.tag == HDPageSettings)];
  }
  if (page == HDPageClips && [self.target respondsToSelector:@selector(reloadHistoryFromDisk)]) {
    [self.target performSelector:@selector(reloadHistoryFromDisk)];
  } else if (page == HDPageStorage && [self.target respondsToSelector:@selector(reloadStorageSettings)]) {
    [self.target performSelector:@selector(reloadStorageSettings)];
  } else if (page == HDPageLicense && [self.target respondsToSelector:@selector(updateLicenseUI)]) {
    [self.target performSelector:@selector(updateLicenseUI)];
  }
  if ([self.target respondsToSelector:@selector(uiPageSelected:)]) {
    [self.target performSelector:@selector(uiPageSelected:) withObject:@(page)];
  }
  self.window.title = @[@"Capture", @"Clips", @"Storage", @"License", @"Settings"][page];
}

- (HDPage)selectedPage {
  for (NSInteger i = 0; i < 5; i++) {
    NSArray *pages = @[self.capturePage, self.clipsPage, self.storagePage, self.licensePage, self.settingsPage];
    if (![pages[i] isHidden]) return (HDPage)i;
  }
  return HDPageCapture;
}

- (HDCardView *)card {
  HDCardView *card = [[HDCardView alloc] initWithFrame:NSZeroRect];
  card.translatesAutoresizingMaskIntoConstraints = NO;
  return card;
}

- (NSStackView *)titleRowWithRole:(HDSymbolRole)role title:(NSString *)title {
  (void)role;
  NSStackView *row = [[NSStackView alloc] init];
  row.orientation = NSUserInterfaceLayoutOrientationHorizontal;
  row.alignment = NSLayoutAttributeCenterY;
  [row addArrangedSubview:HDLabel(title, 24, NSFontWeightSemibold, NSColor.labelColor)];
  return row;
}

- (NSStackView *)formPage:(NSView **)outPage compact:(BOOL)compact {
  NSView *page = [NSView new]; page.translatesAutoresizingMaskIntoConstraints = NO;
  [self.pageHost addSubview:page];
  [NSLayoutConstraint activateConstraints:@[
    [page.leadingAnchor constraintEqualToAnchor:self.pageHost.leadingAnchor],
    [page.trailingAnchor constraintEqualToAnchor:self.pageHost.trailingAnchor],
    [page.topAnchor constraintEqualToAnchor:self.pageHost.topAnchor],
    [page.bottomAnchor constraintEqualToAnchor:self.pageHost.bottomAnchor]
  ]];
  *outPage = page;
  NSScrollView *scroll = [NSScrollView new]; scroll.translatesAutoresizingMaskIntoConstraints = NO;
  scroll.drawsBackground = NO; scroll.hasVerticalScroller = YES; scroll.autohidesScrollers = YES;
  scroll.automaticallyAdjustsContentInsets = NO;
  [page addSubview:scroll];
  [NSLayoutConstraint activateConstraints:@[
    [scroll.leadingAnchor constraintEqualToAnchor:page.leadingAnchor],
    [scroll.trailingAnchor constraintEqualToAnchor:page.trailingAnchor],
    [scroll.topAnchor constraintEqualToAnchor:page.topAnchor constant:24],
    [scroll.bottomAnchor constraintEqualToAnchor:page.bottomAnchor]
  ]];
  HDDocumentView *doc = [HDDocumentView new]; doc.translatesAutoresizingMaskIntoConstraints = NO;
  scroll.documentView = doc;
  [doc.widthAnchor constraintEqualToAnchor:scroll.contentView.widthAnchor].active = YES;
  NSStackView *stack = [NSStackView new];
  stack.orientation = NSUserInterfaceLayoutOrientationVertical; stack.alignment = NSLayoutAttributeLeading;
  stack.spacing = 20; stack.translatesAutoresizingMaskIntoConstraints = NO; [doc addSubview:stack];
  [NSLayoutConstraint activateConstraints:@[
    [stack.leadingAnchor constraintEqualToAnchor:doc.leadingAnchor constant:28],
    [stack.trailingAnchor constraintLessThanOrEqualToAnchor:doc.trailingAnchor constant:-28],
    [stack.topAnchor constraintEqualToAnchor:doc.topAnchor constant:20],
    [stack.bottomAnchor constraintEqualToAnchor:doc.bottomAnchor constant:-28]
  ]];
  if (compact) {
    NSLayoutConstraint *width = [stack.widthAnchor constraintEqualToConstant:660]; width.priority = 750; width.active = YES;
  } else [stack.trailingAnchor constraintEqualToAnchor:doc.trailingAnchor constant:-28].active = YES;
  return stack;
}

- (NSStackView *)insetStack:(NSView *)container {
  NSStackView *stack = [NSStackView new];
  stack.orientation = NSUserInterfaceLayoutOrientationVertical; stack.alignment = NSLayoutAttributeLeading;
  stack.spacing = 12; stack.translatesAutoresizingMaskIntoConstraints = NO; [container addSubview:stack];
  [NSLayoutConstraint activateConstraints:@[
    [stack.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:18],
    [stack.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-18],
    [stack.topAnchor constraintEqualToAnchor:container.topAnchor constant:18],
    [stack.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-18]
  ]];
  return stack;
}

- (void)buildCapturePage {
  NSView *page; NSStackView *stack = [self formPage:&page compact:NO]; self.capturePage = page;
  [stack addArrangedSubview:[self titleRowWithRole:HDSymbolRoleCapture title:@"Capture"]];
  [stack addArrangedSubview:HDLabel(@"Turn live reactions into clips worth sharing.", 12, NSFontWeightRegular, NSColor.secondaryLabelColor)];

  NSStackView *channelBox = [NSStackView new];
  channelBox.orientation = NSUserInterfaceLayoutOrientationVertical;
  channelBox.alignment = NSLayoutAttributeLeading;
  channelBox.spacing = 8;
  [channelBox addArrangedSubview:HDLabel(@"Live channel", 11, NSFontWeightSemibold, NSColor.secondaryLabelColor)];
  NSStackView *input = [NSStackView new];
  input.orientation = NSUserInterfaceLayoutOrientationHorizontal;
  input.alignment = NSLayoutAttributeCenterY;
  input.spacing = 8;
  self.channelField = [NSTextField textFieldWithString:[[NSUserDefaults standardUserDefaults] stringForKey:@"channel"] ?: @""];
  self.channelField.placeholderString = @"Twitch username or Kick channel URL";
  self.channelField.font = [NSFont systemFontOfSize:14];
  self.channelField.bezelStyle = NSTextFieldRoundedBezel;
  self.channelField.accessibilityLabel = @"Live channel username or URL";
  self.channelField.target = self;
  self.channelField.action = @selector(channelChanged:);
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(channelChanged:) name:NSControlTextDidChangeNotification object:self.channelField];
  [self.channelField.heightAnchor constraintEqualToConstant:36].active = YES;
  self.toggleButton = HDButtonWithSymbol(@"Start Capture", self.target, @selector(toggleCapture:), YES, HDSymbolRoleRecord);
  [self.toggleButton.widthAnchor constraintEqualToConstant:144].active = YES;
  [input addArrangedSubview:self.channelField];
  [input addArrangedSubview:self.toggleButton];
  [channelBox addArrangedSubview:input];
  [input.widthAnchor constraintEqualToAnchor:channelBox.widthAnchor].active = YES;
  [channelBox addArrangedSubview:HDCaption(@"Twitch: enter a username. Kick: paste the channel URL (requires a paired relay).")];

  self.captureModeControl = [NSSegmentedControl segmentedControlWithLabels:@[@"Live Stream", @"Past Broadcast"] trackingMode:NSSegmentSwitchTrackingSelectOne target:self action:@selector(captureModeChanged:)];
  self.captureModeControl.controlSize = NSControlSizeRegular;
  self.captureModeControl.selectedSegmentBezelColor = HDAccent();
  self.captureModeControl.accessibilityLabel = @"Capture source";
  self.captureModeControl.font = [NSFont systemFontOfSize:13 weight:NSFontWeightMedium];
  self.captureModeControl.selectedSegment = [[NSUserDefaults standardUserDefaults] integerForKey:@"captureMode"] == 1 ? 1 : 0;
  [stack addArrangedSubview:self.captureModeControl];

  self.liveBox = channelBox;
  [stack addArrangedSubview:channelBox];
  [channelBox.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active = YES;

  // VOD mode: one link, one button; everything else sits behind Options.
  NSStackView *vodBox = [NSStackView new];
  vodBox.orientation = NSUserInterfaceLayoutOrientationVertical;
  vodBox.alignment = NSLayoutAttributeLeading;
  vodBox.spacing = 7;
  [vodBox addArrangedSubview:HDLabel(@"Twitch VOD", 11, NSFontWeightSemibold, NSColor.secondaryLabelColor)];
  NSStackView *vodInput = [NSStackView new];
  vodInput.orientation = NSUserInterfaceLayoutOrientationHorizontal;
  vodInput.alignment = NSLayoutAttributeCenterY;
  vodInput.spacing = 10;
  self.vodField = [NSTextField textFieldWithString:@""];
  self.vodField.placeholderString = @"Paste a Twitch VOD link";
  self.vodField.font = [NSFont systemFontOfSize:14];
  self.vodField.bezelStyle = NSTextFieldRoundedBezel;
  self.vodField.accessibilityLabel = @"Twitch VOD URL";
  [self.vodField.heightAnchor constraintEqualToConstant:36].active = YES;
  self.vodButton = HDButtonWithSymbol(@"Find Highlights", self.target, @selector(findHighlights:), YES, HDSymbolRoleRecord);
  [self.vodButton.widthAnchor constraintEqualToConstant:152].active = YES;
  [vodInput addArrangedSubview:self.vodField];
  [vodInput addArrangedSubview:self.vodButton];
  [vodBox addArrangedSubview:vodInput];
  [vodInput.widthAnchor constraintEqualToAnchor:vodBox.widthAnchor].active = YES;

  NSStackView *disclosureRow = [NSStackView new];
  disclosureRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
  disclosureRow.alignment = NSLayoutAttributeCenterY;
  disclosureRow.spacing = 2;
  self.vodOptionsDisclosure = [NSButton buttonWithTitle:@"" target:self action:@selector(vodOptionsToggled:)];
  self.vodOptionsDisclosure.bezelStyle = NSBezelStyleDisclosure;
  [self.vodOptionsDisclosure setButtonType:NSButtonTypePushOnPushOff];
  self.vodOptionsDisclosure.state = NSControlStateValueOff;
  NSButton *optionsTitle = [NSButton buttonWithTitle:@"Options" target:self action:@selector(vodOptionsTitleClicked:)];
  optionsTitle.bordered = NO;
  optionsTitle.font = [NSFont systemFontOfSize:12];
  [disclosureRow addArrangedSubview:self.vodOptionsDisclosure];
  [disclosureRow addArrangedSubview:optionsTitle];
  [vodBox addArrangedSubview:disclosureRow];

  self.vodOptionsBox = [NSStackView new];
  self.vodOptionsBox.orientation = NSUserInterfaceLayoutOrientationVertical;
  self.vodOptionsBox.alignment = NSLayoutAttributeLeading;
  self.vodOptionsBox.spacing = 8;
  NSStackView *topRow = [NSStackView new];
  topRow.alignment = NSLayoutAttributeCenterY;
  topRow.spacing = 6;
  NSTextField *topLabel = HDLabel(@"Top moments", 12, NSFontWeightRegular, NSColor.labelColor);
  [topLabel.widthAnchor constraintEqualToConstant:90].active = YES;
  self.vodTopValue = [NSTextField textFieldWithString:@"15"];
  self.vodTopValue.font = [NSFont monospacedDigitSystemFontOfSize:12 weight:NSFontWeightRegular];
  self.vodTopValue.alignment = NSTextAlignmentRight;
  self.vodTopValue.target = self;
  self.vodTopValue.action = @selector(vodTopTyped:);
  [self.vodTopValue.widthAnchor constraintEqualToConstant:44].active = YES;
  self.vodTopStepper = [NSStepper new];
  self.vodTopStepper.minValue = 1;
  self.vodTopStepper.maxValue = 50;
  self.vodTopStepper.increment = 1;
  self.vodTopStepper.integerValue = 15;
  self.vodTopStepper.valueWraps = NO;
  self.vodTopStepper.target = self;
  self.vodTopStepper.action = @selector(vodTopStepped:);
  [topRow addArrangedSubview:topLabel];
  [topRow addArrangedSubview:self.vodTopValue];
  [topRow addArrangedSubview:self.vodTopStepper];
  [self.vodOptionsBox addArrangedSubview:topRow];
  NSStackView *rangeRow = [NSStackView new];
  rangeRow.alignment = NSLayoutAttributeCenterY;
  rangeRow.spacing = 6;
  NSTextField *startLabel = HDLabel(@"Start", 12, NSFontWeightRegular, NSColor.labelColor);
  [startLabel.widthAnchor constraintEqualToConstant:90].active = YES;
  self.vodStartField = [NSTextField textFieldWithString:@""];
  self.vodStartField.placeholderString = @"h:mm:ss";
  self.vodStartField.font = [NSFont monospacedDigitSystemFontOfSize:12 weight:NSFontWeightRegular];
  [self.vodStartField.widthAnchor constraintEqualToConstant:84].active = YES;
  NSTextField *endLabel = HDLabel(@"End", 12, NSFontWeightRegular, NSColor.labelColor);
  self.vodEndField = [NSTextField textFieldWithString:@""];
  self.vodEndField.placeholderString = @"h:mm:ss";
  self.vodEndField.font = [NSFont monospacedDigitSystemFontOfSize:12 weight:NSFontWeightRegular];
  [self.vodEndField.widthAnchor constraintEqualToConstant:84].active = YES;
  [rangeRow addArrangedSubview:startLabel];
  [rangeRow addArrangedSubview:self.vodStartField];
  [rangeRow addArrangedSubview:endLabel];
  [rangeRow addArrangedSubview:self.vodEndField];
  [self.vodOptionsBox addArrangedSubview:rangeRow];
  [self.vodOptionsBox addArrangedSubview:HDCaption(@"Leave Start and End empty to scan the whole VOD.")];
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  self.vodCaptionsCheckbox = [NSButton checkboxWithTitle:@"Burn in captions" target:self action:@selector(vodOverlayChanged:)];
  self.vodCaptionsCheckbox.state = [defaults boolForKey:@"vodCaptions"] ? NSControlStateValueOn : NSControlStateValueOff;
  [self.vodOptionsBox addArrangedSubview:self.vodCaptionsCheckbox];
  NSStackView *hookRow = [NSStackView new];
  hookRow.alignment = NSLayoutAttributeCenterY;
  hookRow.spacing = 8;
  self.vodHookCheckbox = [NSButton checkboxWithTitle:@"Add hook line" target:self action:@selector(vodOverlayChanged:)];
  self.vodHookCheckbox.state = [defaults boolForKey:@"vodHook"] ? NSControlStateValueOn : NSControlStateValueOff;
  self.vodHookTextField = [NSTextField textFieldWithString:@""];
  self.vodHookTextField.placeholderString = @"Auto from chat";
  self.vodHookTextField.font = [NSFont systemFontOfSize:12];
  [self.vodHookTextField.widthAnchor constraintEqualToConstant:240].active = YES;
  [hookRow addArrangedSubview:self.vodHookCheckbox];
  [hookRow addArrangedSubview:self.vodHookTextField];
  [self.vodOptionsBox addArrangedSubview:hookRow];
  self.vodHookTextField.hidden = self.vodHookCheckbox.state != NSControlStateValueOn;
  self.vodOptionsBox.hidden = YES;
  [vodBox addArrangedSubview:self.vodOptionsBox];

  self.vodBox = vodBox;
  [stack addArrangedSubview:vodBox];
  [vodBox.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active = YES;
  [self syncCaptureMode];

  HDCardView *sessionCard = [self card];
  [stack addArrangedSubview:sessionCard];
  [sessionCard.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active = YES;
  NSStackView *sessionContent = [self insetStack:sessionCard];
  sessionContent.spacing = 12;

  NSStackView *sessionRow = [NSStackView new];
  sessionRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
  sessionRow.alignment = NSLayoutAttributeCenterY;
  sessionRow.spacing = 16;
  NSStackView *sessionText = [NSStackView new];
  sessionText.orientation = NSUserInterfaceLayoutOrientationVertical;
  sessionText.alignment = NSLayoutAttributeLeading;
  sessionText.spacing = 4;
  self.captureHeroTitle = HDLabel(@"Ready to start", 16, NSFontWeightSemibold, NSColor.labelColor);
  self.captureHeroSubtitle = HDLabel(@"Start capture and keep Highlight Desk running while the stream is live.", 12, NSFontWeightRegular, NSColor.secondaryLabelColor);
  [sessionText addArrangedSubview:self.captureHeroTitle];
  [sessionText addArrangedSubview:self.captureHeroSubtitle];
  [self.captureHeroSubtitle.widthAnchor constraintEqualToAnchor:sessionText.widthAnchor].active = YES;
  self.statusLabel = [HDEventLabel labelWithString:@""];
  self.statusLabel.font = [NSFont systemFontOfSize:11];
  self.statusLabel.textColor = NSColor.secondaryLabelColor;
  [sessionText addArrangedSubview:self.statusLabel];
  self.telemetryLabel = [HDEventLabel labelWithString:@""];
  self.telemetryLabel.font = HDMono(11);
  self.telemetryLabel.textColor = NSColor.secondaryLabelColor;
  [sessionText addArrangedSubview:self.telemetryLabel];
  [sessionRow addArrangedSubview:sessionText];
  [sessionText.widthAnchor constraintEqualToAnchor:sessionRow.widthAnchor].active = YES;
  for (NSTextField *label in @[self.captureHeroTitle, self.statusLabel, self.telemetryLabel]) {
    label.maximumNumberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    [label.widthAnchor constraintEqualToAnchor:sessionText.widthAnchor].active = YES;
    [label setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
  }
  NSStackView *actions = [NSStackView new];
  actions.spacing = 6;
  self.saveButton = HDButtonWithSymbol(@"Save Highlight", self.target, @selector(saveHighlight:), NO, HDSymbolRoleSave);
  self.saveButton.toolTip = @"Save a highlight during capture (⌘S).";
  self.lastClipButton = HDButtonWithSymbol(@"Open Last Clip", self.target, @selector(openLastClip:), NO, HDSymbolRoleOpenClip);
  self.lastClipButton.toolTip = @"Available after a clip has finished.";
  self.saveButton.enabled = NO;
  self.lastClipButton.enabled = NO;
  [actions addArrangedSubview:self.saveButton];
  [actions addArrangedSubview:self.lastClipButton];
  NSButton *monitorButton = HDButton(@"Capture Health…", self.target, @selector(showMonitoring:), NO);
  monitorButton.toolTip = @"Capture health, clip feedback and per-channel learning";
  [actions addArrangedSubview:monitorButton];
  [sessionContent addArrangedSubview:sessionRow];
  [sessionContent addArrangedSubview:actions];
  [sessionRow.widthAnchor constraintEqualToAnchor:sessionContent.widthAnchor].active = YES;
  self.sessionSummary = HDCaption(@"0 clips saved · No pending uploads");
  self.sessionSummary.font = HDTabular(11);
  [sessionContent addArrangedSubview:self.sessionSummary];
  [self.sessionSummary.widthAnchor constraintEqualToAnchor:sessionContent.widthAnchor].active = YES;

  NSStackView *recentHeader = [NSStackView new];
  recentHeader.alignment = NSLayoutAttributeCenterY;
  [recentHeader addArrangedSubview:HDLabel(@"Recent clips", 13, NSFontWeightSemibold, NSColor.labelColor)];
  [recentHeader addArrangedSubview:[NSView new]];
  [recentHeader addArrangedSubview:HDButtonWithSymbol(@"View Library", self, @selector(openClipsPage:), NO, HDSymbolRoleArrowRight)];
  [stack addArrangedSubview:recentHeader];
  [recentHeader.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active = YES;
  self.recentRows = [NSStackView new];
  self.recentRows.orientation = NSUserInterfaceLayoutOrientationVertical;
  self.recentRows.alignment = NSLayoutAttributeLeading;
  self.recentRows.spacing = 12;
  [stack addArrangedSubview:self.recentRows];
  [self.recentRows.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active = YES;
  [self updateRecentClips:@[]];
  [self syncCaptureMode];
  [self setSessionState:HDSessionStateReady status:@""];
}
- (void)channelChanged:(id)sender {
  if (self.channelField.enabled) [self setSessionState:HDSessionStateReady status:@""];
}

- (BOOL)vodMode { return self.captureModeControl.selectedSegment == 1; }

- (void)captureModeChanged:(id)sender {
  [[NSUserDefaults standardUserDefaults] setInteger:self.captureModeControl.selectedSegment forKey:@"captureMode"];
  [self syncCaptureMode];
  if (!self.liveRunning && !self.vodRunning) [self setSessionState:HDSessionStateReady status:@""];
}

- (void)syncCaptureMode {
  BOOL vod = self.vodMode;
  self.liveBox.hidden = vod;
  self.vodBox.hidden = !vod;
  self.saveButton.hidden = vod;
  // Source changes are user initiated; initial construction must not steal focus.
  if (self.window.isVisible && self.selectedPage == HDPageCapture)
    [self.window makeFirstResponder:vod ? self.vodField : self.channelField];
}

- (void)vodOptionsToggled:(id)sender {
  self.vodOptionsBox.hidden = self.vodOptionsDisclosure.state != NSControlStateValueOn;
}

- (void)vodOptionsTitleClicked:(id)sender {
  self.vodOptionsDisclosure.state = self.vodOptionsDisclosure.state == NSControlStateValueOn ? NSControlStateValueOff : NSControlStateValueOn;
  [self vodOptionsToggled:nil];
}

- (void)vodOverlayChanged:(id)sender {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setBool:self.vodCaptionsCheckbox.state == NSControlStateValueOn forKey:@"vodCaptions"];
  [defaults setBool:self.vodHookCheckbox.state == NSControlStateValueOn forKey:@"vodHook"];
  self.vodHookTextField.hidden = self.vodHookCheckbox.state != NSControlStateValueOn;
}

- (void)vodTopStepped:(id)sender { self.vodTopValue.integerValue = self.vodTopStepper.integerValue; }

- (void)vodTopTyped:(id)sender {
  NSInteger value = MAX(1, MIN(50, self.vodTopValue.integerValue));
  self.vodTopStepper.integerValue = value;
  self.vodTopValue.integerValue = value;
}

- (NSInteger)vodTopCount {
  [self vodTopTyped:nil];
  return self.vodTopStepper.integerValue;
}

- (void)setVodRunning:(BOOL)running {
  _vodRunning = running;
  self.vodField.enabled = !running;
  self.vodStartField.enabled = !running;
  self.vodEndField.enabled = !running;
  self.vodTopValue.enabled = !running;
  self.vodTopStepper.enabled = !running;
  self.vodCaptionsCheckbox.enabled = !running;
  self.vodHookCheckbox.enabled = !running;
  self.vodHookTextField.enabled = !running;
  self.vodButton.title = running ? @"Cancel" : @"Find Highlights";
  self.vodButton.image = HDSymbolImage(running ? HDSymbolRoleStop : HDSymbolRoleRecord, 13, NSFontWeightSemibold, running ? @"Cancel" : @"Find highlights");
  self.vodButton.imagePosition = NSImageLeading;
  self.vodButton.imageHugsTitle = YES;
  self.toggleButton.enabled = !running;
  self.toggleButton.toolTip = running ? @"Finish or cancel the VOD scan first." : nil;
}

- (void)refreshRecentPreviews { [self updateRecentClips:self.recentEntries ?: @[]]; }

- (void)updateRecentClips:(NSArray<NSDictionary *> *)entries {
  self.recentEntries = entries;
  for (NSView *view in self.recentRows.arrangedSubviews.copy) { [self.recentRows removeArrangedSubview:view]; [view removeFromSuperview]; }
  if (!entries.count) {
    [self.recentRows addArrangedSubview:HDLabel(@"No clips yet", 13, NSFontWeightMedium, NSColor.labelColor)];
    [self.recentRows addArrangedSubview:HDCaption(@"Highlights appear automatically when chat reacts. You can also save one with ⌘S during capture.")];
    return;
  }
  for (NSDictionary *entry in [entries subarrayWithRange:NSMakeRange(0, MIN(3, entries.count))]) {
    NSStackView *row = [NSStackView new]; row.spacing = 10; row.alignment = NSLayoutAttributeCenterY;
    NSImageView *preview = HDSymbolImageView(HDSymbolRoleClips, 18, NSColor.secondaryLabelColor, @"Clip preview");
    for (NSLayoutConstraint *constraint in preview.constraints) if (constraint.firstAttribute == NSLayoutAttributeWidth || constraint.firstAttribute == NSLayoutAttributeHeight) constraint.active = NO;
    [preview.widthAnchor constraintEqualToConstant:44].active = YES;
    [preview.heightAnchor constraintEqualToConstant:34].active = YES;
    preview.imageScaling = NSImageScaleProportionallyUpOrDown;
    NSString *path = [entry[@"localPath"] isKindOfClass:NSString.class] ? entry[@"localPath"] : @"";
    BOOL hasPreview = NO;
    if ([self.target respondsToSelector:@selector(cachedClipPreview:)]) {
      NSImage *image = [self.target performSelector:@selector(cachedClipPreview:) withObject:path];
      if (image) { preview.image = image; preview.contentTintColor = nil; hasPreview = YES; }
    }
    preview.hidden = NO;
    preview.wantsLayer = YES;
    preview.layer.cornerRadius = 5;
    preview.layer.masksToBounds = YES;
    if (!hasPreview) preview.contentTintColor = NSColor.secondaryLabelColor;
    [row addArrangedSubview:preview];
    NSString *reason = [entry[@"reason"] isKindOfClass:NSString.class] ? entry[@"reason"] : @"Highlight";
    NSTextField *title = HDLabel(reason, 13, NSFontWeightMedium, NSColor.labelColor);
    title.maximumNumberOfLines = 1;
    title.lineBreakMode = NSLineBreakByTruncatingTail;
    title.toolTip = reason;
    [title setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    [row addArrangedSubview:title];
    [row addArrangedSubview:[NSView new]];
    [row addArrangedSubview:HDCaption([entry[@"status"] description].capitalizedString ?: @"Saved")];
    NSButton *open = HDButton(@"Open", self, @selector(openRecentClip:), NO);
    open.tag = [entries indexOfObject:entry];
    [row addArrangedSubview:open]; [self.recentRows addArrangedSubview:row];
    [row.widthAnchor constraintEqualToAnchor:self.recentRows.widthAnchor].active = YES;
  }
}

- (void)openRecentClip:(NSButton *)sender {
  if (sender.tag < 0 || sender.tag >= self.recentEntries.count) return;
  NSDictionary *entry = self.recentEntries[sender.tag];
  if ([self.target respondsToSelector:@selector(recentClipOpened:)]) [self.target performSelector:@selector(recentClipOpened:) withObject:entry];
  NSString *path = [entry[@"localPath"] isKindOfClass:NSString.class] ? entry[@"localPath"] : @"";
  NSString *link = [entry[@"webLink"] isKindOfClass:NSString.class] ? entry[@"webLink"] : @"";
  if (path.length && [[NSFileManager defaultManager] fileExistsAtPath:path])
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:path]];
  else if (link.length) [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:link]];
  else [self selectPage:HDPageClips];
}

- (void)openClipsPage:(id)sender {
  [self selectPage:HDPageClips];
}

- (void)buildClipsPage {
  NSView *page = [[NSView alloc] initWithFrame:NSZeroRect];
  page.translatesAutoresizingMaskIntoConstraints = NO;
  page.hidden = YES;
  [self.pageHost addSubview:page];
  [NSLayoutConstraint activateConstraints:@[
    [page.leadingAnchor constraintEqualToAnchor:self.pageHost.leadingAnchor],
    [page.trailingAnchor constraintEqualToAnchor:self.pageHost.trailingAnchor],
    [page.topAnchor constraintEqualToAnchor:self.pageHost.topAnchor],
    [page.bottomAnchor constraintEqualToAnchor:self.pageHost.bottomAnchor]
  ]];
  self.clipsPage = page;

  NSStackView *stack = [[NSStackView alloc] init];
  stack.orientation = NSUserInterfaceLayoutOrientationVertical;
  stack.alignment = NSLayoutAttributeLeading;
  stack.spacing = 14;
  stack.translatesAutoresizingMaskIntoConstraints = NO;
  [page addSubview:stack];
  [NSLayoutConstraint activateConstraints:@[
    [stack.leadingAnchor constraintEqualToAnchor:page.leadingAnchor constant:28],
    [stack.trailingAnchor constraintEqualToAnchor:page.trailingAnchor constant:-28],
    [stack.topAnchor constraintEqualToAnchor:page.topAnchor constant:44],
    [stack.bottomAnchor constraintEqualToAnchor:page.bottomAnchor constant:-24]
  ]];

  NSStackView *header = [[NSStackView alloc] init];
  header.orientation = NSUserInterfaceLayoutOrientationHorizontal;
  header.alignment = NSLayoutAttributeCenterY;
  NSStackView *titleBox = [[NSStackView alloc] init];
  titleBox.orientation = NSUserInterfaceLayoutOrientationVertical;
  titleBox.alignment = NSLayoutAttributeLeading;
  titleBox.spacing = 3;
  [titleBox addArrangedSubview:[self titleRowWithRole:HDSymbolRoleClips title:@"Clips"]];
  [titleBox addArrangedSubview:HDLabel(@"Every highlight, local and in the cloud.", 13, NSFontWeightRegular, NSColor.secondaryLabelColor)];
  [header addArrangedSubview:titleBox];
  [header addArrangedSubview:[[NSView alloc] initWithFrame:NSZeroRect]];
  NSButton *openFolder = HDButtonWithSymbol(@"Open Clips Folder", self.target, @selector(folder:), NO, HDSymbolRoleFolder);
  [header addArrangedSubview:openFolder];
  [stack addArrangedSubview:header];
  [header.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active = YES;

  NSStackView *tools = [[NSStackView alloc] init];
  tools.orientation = NSUserInterfaceLayoutOrientationHorizontal;
  tools.spacing = 8;
  self.clipSearchField = [[NSSearchField alloc] initWithFrame:NSZeroRect];
  self.clipSearchField.placeholderString = @"Search clips";
  self.clipSearchField.target = self.target;
  self.clipSearchField.action = @selector(clipSearchChanged:);
  self.clipSearchField.translatesAutoresizingMaskIntoConstraints = NO;
  self.clipSearchField.accessibilityLabel = @"Search clips";
  [self.clipSearchField.widthAnchor constraintGreaterThanOrEqualToConstant:180].active = YES;
  [tools addArrangedSubview:self.clipSearchField];

  self.clipFilterControl = [NSSegmentedControl segmentedControlWithLabels:@[@"All", @"Local Only", @"Cloud", @"Queued"]
                                                            trackingMode:NSSegmentSwitchTrackingSelectOne
                                                                  target:self.target
                                                                  action:@selector(clipFilterChanged:)];
  self.clipFilterControl.selectedSegment = 0;
  [tools addArrangedSubview:self.clipFilterControl];
  self.clipFilterControl.selectedSegmentBezelColor = HDAccent();
  [stack addArrangedSubview:tools];
  [tools.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active = YES;

  self.historyStatus = HDLabel(@"", 11, NSFontWeightRegular, NSColor.secondaryLabelColor);
  self.historyStatus.font = HDTabular(11);
  [stack addArrangedSubview:self.historyStatus];

  NSTableView *table = [[NSTableView alloc] initWithFrame:NSZeroRect];
  table.rowHeight = 48;
  table.usesAlternatingRowBackgroundColors = NO;
  table.backgroundColor = HDInk();
  table.gridColor = HDHairline();
  table.gridStyleMask = NSTableViewSolidHorizontalGridLineMask;
  table.intercellSpacing = NSMakeSize(0, 0);
  if (@available(macOS 11.0, *)) table.style = NSTableViewStylePlain;
  table.columnAutoresizingStyle = NSTableViewUniformColumnAutoresizingStyle;
  table.selectionHighlightStyle = NSTableViewSelectionHighlightStyleRegular;
  table.doubleAction = @selector(openSelectedHistory:);
  table.target = self.target;
  table.translatesAutoresizingMaskIntoConstraints = NO;
  NSArray *columns = @[
    @[@"preview", @"", @64.0],
    @[@"when", @"Created", @128.0],
    @[@"chatrate", @"Peak", @56.0],
    @[@"size", @"Size", @60.0],
    @[@"provider", @"Destination", @124.0],
    @[@"local", @"Local", @104.0],
    @[@"rating", @"", @64.0]
  ];
  for (NSArray *spec in columns) {
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:spec[0]];
    column.title = spec[1];
    column.width = [spec[2] doubleValue];
    column.minWidth = [spec[0] isEqualToString:@"when"] ? 112 : ([spec[0] isEqualToString:@"provider"] ? 124 : ([spec[0] isEqualToString:@"local"] ? 100 : ([spec[0] isEqualToString:@"preview"] ? 64 : 56)));
    if ([spec[0] isEqualToString:@"rating"]) {
      column.maxWidth = 72;
      column.headerToolTip = @"Optional: rate clips to help tune highlight picking. Stays on this Mac.";
      [table addTableColumn:column];
      continue;
    }
    if ([spec[0] isEqualToString:@"when"] || [spec[0] isEqualToString:@"provider"]) {
      NSString *key = [spec[0] isEqualToString:@"when"] ? @"createdAt" : spec[0];
      column.sortDescriptorPrototype = [NSSortDescriptor sortDescriptorWithKey:key ascending:![key isEqualToString:@"createdAt"] selector:@selector(localizedStandardCompare:)];
    }
    [table addTableColumn:column];
  }
  table.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]];
  NSMenu *context = [NSMenu new];
  NSArray *actions = @[@[@"Open Clip", @"openSelectedHistory:"], @[@"Show in Finder", @"revealSelectedClip:"], @[@"Copy Cloud Link", @"copySelectedClipLink:"], @[@"Clip Details…", @"showSelectedClipDetails:"]];
  for (NSArray *spec in actions) { NSMenuItem *item = [context addItemWithTitle:spec[0] action:NSSelectorFromString(spec[1]) keyEquivalent:@""]; item.target = self.target; }
  [context addItem:[NSMenuItem separatorItem]];
  for (NSArray *spec in @[@[@"Duplicate", @"markDuplicate:"], @[@"Started Late", @"markStartedLate:"], @[@"Ended Early", @"markEndedEarly:"]]) {
    NSMenuItem *item = [context addItemWithTitle:spec[0] action:NSSelectorFromString(spec[1]) keyEquivalent:@""];
    item.target = self.target;
  }
  table.menu = context;
  self.historyTable = table;
  NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSZeroRect];
  scroll.documentView = table;
  scroll.hasVerticalScroller = YES;
  scroll.autohidesScrollers = YES;
  scroll.borderType = NSNoBorder;
  scroll.translatesAutoresizingMaskIntoConstraints = NO;
  [stack addArrangedSubview:scroll];
  [scroll.heightAnchor constraintGreaterThanOrEqualToConstant:240].active = YES;
  [scroll.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active = YES;
  self.libraryScroll = scroll;
  // Replace the empty table with one useful next step, in the same available space.
  HDCardView *empty = [self card];
  [empty.heightAnchor constraintGreaterThanOrEqualToConstant:240].active = YES;
  NSStackView *message = [NSStackView new];
  message.orientation = NSUserInterfaceLayoutOrientationVertical;
  message.alignment = NSLayoutAttributeCenterX;
  message.spacing = 12;
  message.translatesAutoresizingMaskIntoConstraints = NO;
  [empty addSubview:message];
  [message addArrangedSubview:HDSymbolImageView(HDSymbolRoleClips, 28, HDAccentText(), @"Clip library")];
  self.libraryEmptyTitle = HDLabel(@"Your highlights start here", 16, NSFontWeightSemibold, NSColor.labelColor);
  self.libraryEmptyBody = HDLabel(@"Capture a live stream or find moments in a past broadcast.", 13, NSFontWeightRegular, NSColor.secondaryLabelColor);
  self.libraryEmptyBody.alignment = NSTextAlignmentCenter;
  self.libraryEmptyAction = HDButton(@"Go to Capture", self, @selector(libraryEmptyClicked:), YES);
  [message addArrangedSubview:self.libraryEmptyTitle];
  [message addArrangedSubview:self.libraryEmptyBody];
  [message addArrangedSubview:self.libraryEmptyAction];
  [NSLayoutConstraint activateConstraints:@[
    [message.centerXAnchor constraintEqualToAnchor:empty.centerXAnchor],
    [message.centerYAnchor constraintEqualToAnchor:empty.centerYAnchor],
    [message.widthAnchor constraintLessThanOrEqualToAnchor:empty.widthAnchor constant:-40],
    [self.libraryEmptyBody.widthAnchor constraintEqualToAnchor:message.widthAnchor]
  ]];
  [stack insertArrangedSubview:empty atIndex:[stack.arrangedSubviews indexOfObject:scroll]];
  [empty.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active = YES;
  self.libraryEmptyView = empty;

  NSStackView *footer = [[NSStackView alloc] init];
  footer.orientation = NSUserInterfaceLayoutOrientationHorizontal;
  footer.spacing = 10;
  self.historyOpenButton = HDButtonWithSymbol(@"Open Selected", self.target, @selector(openSelectedHistory:), NO, HDSymbolRoleOpenSelected);
  self.historyOpenButton.enabled = NO;
  [footer addArrangedSubview:self.historyOpenButton];
  NSButton *refresh = HDButtonWithSymbol(@"Refresh", self.target, @selector(refreshHistory:), NO, HDSymbolRoleRefresh);
  [footer addArrangedSubview:refresh];
  NSButton *state = HDButtonWithSymbol(@"Open State Folder", self.target, @selector(openStateFolder:), NO, HDSymbolRoleStateFolder);
  state.hidden = YES;
  [stack addArrangedSubview:footer];
}

- (NSView *)flexSpacer {
  NSView *spacer = [[NSView alloc] initWithFrame:NSZeroRect];
  spacer.translatesAutoresizingMaskIntoConstraints = NO;
  [spacer setContentHuggingPriority:1 forOrientation:NSLayoutConstraintOrientationVertical];
  [spacer.heightAnchor constraintGreaterThanOrEqualToConstant:0].active = YES;
  return spacer;
}

- (void)buildStoragePage {
  NSView *page; NSStackView *stack = [self formPage:&page compact:YES]; self.storagePage = page;
  [stack addArrangedSubview:[self titleRowWithRole:HDSymbolRoleStorage title:@"Storage"]];
  [stack addArrangedSubview:HDLabel(@"Choose where finished 9:16 clips go.", 13, NSFontWeightRegular, NSColor.secondaryLabelColor)];

  NSPopUpButton *hidden = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
  [hidden addItemsWithTitles:@[@"Local only", @"Dropbox", @"Google Drive"]];
  hidden.hidden = YES;
  [stack addArrangedSubview:hidden];
  self.storageModePopup = hidden;

  NSStackView *cards = [[NSStackView alloc] init];
  cards.orientation = NSUserInterfaceLayoutOrientationHorizontal;
  cards.distribution = NSStackViewDistributionFillEqually;
  cards.spacing = 12;
  [stack addArrangedSubview:cards];
  [cards.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active = YES;
  NSArray *titles = @[@"Local only", @"Dropbox", @"Google Drive"];
  NSArray *roles = @[@(HDSymbolRoleStorageLocal), @(HDSymbolRoleStorageDropbox), @(HDSymbolRoleStorageGoogle)];
  for (NSInteger i = 0; i < 3; i++) {
    NSButton *button = [NSButton buttonWithTitle:@"" target:self action:@selector(storageCardClicked:)];
    button.tag = i;
    button.accessibilityLabel = titles[i];
    button.toolTip = [NSString stringWithFormat:@"Save finished clips to %@", titles[i]];
    button.bordered = NO;
    button.wantsLayer = YES;
    button.layer.cornerRadius = 0;
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button.heightAnchor constraintEqualToConstant:86].active = YES;
    HDCardView *card = [self card];
    [cards addArrangedSubview:card];
    [card.widthAnchor constraintEqualToAnchor:cards.widthAnchor multiplier:1.0/3.0 constant:-8].active = YES;
    [card addSubview:button];
    [NSLayoutConstraint activateConstraints:@[
      [button.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
      [button.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
      [button.topAnchor constraintEqualToAnchor:card.topAnchor],
      [button.bottomAnchor constraintEqualToAnchor:card.bottomAnchor]
    ]];
    [self.storageCardButtons addObject:button];
    NSStackView *box = [[NSStackView alloc] init];
    box.orientation = NSUserInterfaceLayoutOrientationVertical;
    box.alignment = NSLayoutAttributeLeading;
    box.spacing = 4;
    box.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:box];
    [NSLayoutConstraint activateConstraints:@[
      [box.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
      [box.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
      [box.centerYAnchor constraintEqualToAnchor:card.centerYAnchor]
    ]];
    NSImageView *icon = HDSymbolImageView([roles[i] integerValue], 16, HDMuted(), titles[i]);
    [box addArrangedSubview:icon];
    [box addArrangedSubview:HDLabel(titles[i], 14, NSFontWeightSemibold, NSColor.labelColor)];
    NSTextField *detail = HDLabel(i == 0 ? @"No account needed" : @"Browser sign-in", 11, NSFontWeightRegular, NSColor.secondaryLabelColor);
    [box addArrangedSubview:detail];
    NSImageView *badge = HDSymbolImageView(HDSymbolRoleStorageSelected, 14, HDAccentText(), @"Selected destination");
    badge.hidden = YES;
    [card addSubview:badge];
    [NSLayoutConstraint activateConstraints:@[
      [badge.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-12],
      [badge.topAnchor constraintEqualToAnchor:card.topAnchor constant:12]
    ]];
    [self.storageSelectionBadges addObject:badge];
  }

  HDCardView *form = [self card];
  [stack addArrangedSubview:form];
  [form.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active = YES;
  NSStackView *formStack = [[NSStackView alloc] init];
  formStack.orientation = NSUserInterfaceLayoutOrientationVertical;
  formStack.alignment = NSLayoutAttributeLeading;
  formStack.spacing = 10;
  formStack.translatesAutoresizingMaskIntoConstraints = NO;
  [form addSubview:formStack];
  [NSLayoutConstraint activateConstraints:@[
    [formStack.leadingAnchor constraintEqualToAnchor:form.leadingAnchor constant:18],
    [formStack.trailingAnchor constraintEqualToAnchor:form.trailingAnchor constant:-18],
    [formStack.topAnchor constraintEqualToAnchor:form.topAnchor constant:16],
    [formStack.bottomAnchor constraintEqualToAnchor:form.bottomAnchor constant:-16]
  ]];
  self.storageStatus = HDLabel(@"", 11, NSFontWeightRegular, NSColor.secondaryLabelColor);
  [formStack addArrangedSubview:self.storageStatus];
  NSStackView *folderRow = [[NSStackView alloc] init];
  self.storageFolderRow = folderRow;
  folderRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
  folderRow.spacing = 10;
  [folderRow addArrangedSubview:HDSymbolImageView(HDSymbolRoleFolder, 12, NSColor.secondaryLabelColor, @"Remote folder")];
  [folderRow addArrangedSubview:HDLabel(@"Remote folder", 12, NSFontWeightSemibold, NSColor.secondaryLabelColor)];
  self.storageFolder = [NSTextField textFieldWithString:@"/Highlight Desk"];
  self.storageFolder.font = HDMono(12);
  self.storageFolder.translatesAutoresizingMaskIntoConstraints = NO;
  [self.storageFolder.widthAnchor constraintGreaterThanOrEqualToConstant:260].active = YES;
  [folderRow addArrangedSubview:self.storageFolder];
  [formStack addArrangedSubview:folderRow];
  self.storageDeleteCheckbox = [NSButton checkboxWithTitle:@"Delete local videos after confirmed upload" target:nil action:nil];
  self.storageKeepLocalCheckbox = [NSButton checkboxWithTitle:@"Keep a local copy after uploading" target:nil action:nil];
  self.storageKeepRawCheckbox = [NSButton checkboxWithTitle:@"Keep original landscape files" target:nil action:nil];
  self.storageDeleteCheckbox.hidden = YES;
  [formStack addArrangedSubview:self.storageKeepLocalCheckbox];
  NSButton *advanced = [NSButton checkboxWithTitle:@"Show advanced file options" target:self action:@selector(storageAdvancedChanged:)];
  [formStack addArrangedSubview:advanced];
  self.storageAdvancedOptions = [NSStackView new]; self.storageAdvancedOptions.orientation = NSUserInterfaceLayoutOrientationVertical;
  self.storageAdvancedOptions.alignment = NSLayoutAttributeLeading; self.storageAdvancedOptions.spacing = 5;
  [self.storageAdvancedOptions addArrangedSubview:self.storageKeepRawCheckbox];
  [self.storageAdvancedOptions addArrangedSubview:HDCaption(@"Retains the landscape source in addition to the vertical clip. Uses more disk space.")];
  [formStack addArrangedSubview:self.storageAdvancedOptions]; self.storageAdvancedOptions.hidden = YES;
  self.storageKeepRawCheckbox.toolTip = @"Keeps the landscape source as well as the finished vertical clip. Uses additional disk space.";
  self.localFolderButton = HDButtonWithSymbol(@"Open Save Folder", self.target, @selector(folder:), NO, HDSymbolRoleFolder);
  self.localOutputBox = [NSStackView new];
  self.localOutputBox.orientation = NSUserInterfaceLayoutOrientationVertical;
  self.localOutputBox.alignment = NSLayoutAttributeLeading; self.localOutputBox.spacing = 8;
  [self.localOutputBox addArrangedSubview:HDLabel(@"Save folder", 12, NSFontWeightMedium, NSColor.labelColor)];
  self.localOutputPathLabel = HDCaption(@"");
  self.localOutputPathLabel.font = HDMono(11);
  [self setLocalOutputPath:[[NSUserDefaults standardUserDefaults] stringForKey:@"HDOutputRoot"] ?: [NSHomeDirectory() stringByAppendingPathComponent:@"Movies/Highlight Desk"]];
  [self.localOutputBox addArrangedSubview:self.localOutputPathLabel];
  self.localOutputPathLabel.maximumNumberOfLines = 1;
  self.localOutputPathLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
  [self.localOutputPathLabel.widthAnchor constraintEqualToAnchor:self.localOutputBox.widthAnchor].active = YES;
  NSStackView *folderActions = [NSStackView new]; folderActions.spacing = 8;
  [folderActions addArrangedSubview:HDButton(@"Choose Folder…", self.target, @selector(chooseOutputFolder:), NO)];
  [folderActions addArrangedSubview:self.localFolderButton];
  [self.localOutputBox addArrangedSubview:folderActions];
  [formStack insertArrangedSubview:self.localOutputBox atIndex:1];
  [self.localOutputBox.widthAnchor constraintEqualToAnchor:formStack.widthAnchor].active = YES;
  NSStackView *actions = [[NSStackView alloc] init];
  actions.orientation = NSUserInterfaceLayoutOrientationHorizontal;
  actions.spacing = 8;
  self.storageConnectButton = HDButtonWithSymbol(@"Connect", self.target, @selector(connectStorage:), YES, HDSymbolRoleConnect);
  self.storageDisconnectButton = HDButtonWithSymbol(@"Disconnect", self.target, @selector(disconnectStorage:), NO, HDSymbolRoleDisconnect);
  NSButton *save = HDButtonWithSymbol(@"Save Changes", self.target, @selector(saveStorageSettings:), NO, HDSymbolRoleSaveChanges);
  [actions addArrangedSubview:self.storageConnectButton];
  [actions addArrangedSubview:self.storageDisconnectButton];
  self.storageSaveButton = save; save.enabled = NO;
  self.storageKeepLocalCheckbox.target = self.target; self.storageKeepLocalCheckbox.action = @selector(storagePreferencesChanged:);
  self.storageKeepRawCheckbox.target = self.target; self.storageKeepRawCheckbox.action = @selector(storagePreferencesChanged:);
  [[NSNotificationCenter defaultCenter] addObserver:self.target selector:@selector(storagePreferencesChanged:) name:NSControlTextDidChangeNotification object:self.storageFolder];
  [actions addArrangedSubview:save];
  [formStack addArrangedSubview:actions];
}

- (void)storageCardClicked:(NSButton *)sender {
  [self.storageModePopup selectItemAtIndex:sender.tag];
  [self syncStorageCards];
  if ([self.target respondsToSelector:@selector(storageModeChanged:)]) {
    [self.target performSelector:@selector(storageModeChanged:) withObject:sender];
  }
}

- (void)syncStorageCards {
  NSInteger index = self.storageModePopup.indexOfSelectedItem;
  for (NSButton *button in self.storageCardButtons) {
    HDCardView *card = (HDCardView *)button.superview;
    card.destinationSelected = button.tag == index;
    [card updateLayerColors];
  }
  for (NSInteger i = 0; i < self.storageSelectionBadges.count; i++) {
    self.storageSelectionBadges[i].hidden = i != index;
  }
}

- (void)buildLicensePage {
  NSView *page; NSStackView *stack = [self formPage:&page compact:YES]; self.licensePage = page;
  [stack addArrangedSubview:[self titleRowWithRole:HDSymbolRoleLicense title:@"License"]];
  [stack addArrangedSubview:HDLabel(@"Your trial, license, and activation.", 13, NSFontWeightRegular, NSColor.secondaryLabelColor)];
  HDCardView *card = [self card];
  [stack addArrangedSubview:card];
  [card.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active = YES;
  NSStackView *box = [[NSStackView alloc] init];
  box.orientation = NSUserInterfaceLayoutOrientationVertical;
  box.alignment = NSLayoutAttributeLeading;
  box.spacing = 8;
  box.translatesAutoresizingMaskIntoConstraints = NO;
  [card addSubview:box];
  [NSLayoutConstraint activateConstraints:@[
    [box.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
    [box.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
    [box.topAnchor constraintEqualToAnchor:card.topAnchor constant:18],
    [box.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-18]
  ]];
  NSStackView *statusRow = [[NSStackView alloc] init];
  statusRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
  statusRow.alignment = NSLayoutAttributeCenterY;
  statusRow.spacing = 10;
  self.licenseStatusIcon = HDSymbolImageView(HDSymbolRoleLicenseTrial, 22, NSColor.secondaryLabelColor, @"License status");
  [statusRow addArrangedSubview:self.licenseStatusIcon];
  NSStackView *statusText = [[NSStackView alloc] init];
  statusText.orientation = NSUserInterfaceLayoutOrientationVertical;
  statusText.alignment = NSLayoutAttributeLeading;
  statusText.spacing = 2;
  self.licenseTrialLabel = HDLabel(@"", 12, NSFontWeightRegular, NSColor.secondaryLabelColor);
  [statusText addArrangedSubview:self.licenseTrialLabel];
  self.licenseStatusLabel = HDLabel(@"", 15, NSFontWeightSemibold, NSColor.labelColor);
  [statusText addArrangedSubview:self.licenseStatusLabel];
  [statusRow addArrangedSubview:statusText];
  [box addArrangedSubview:statusRow];
  NSStackView *row = [[NSStackView alloc] init];
  row.orientation = NSUserInterfaceLayoutOrientationHorizontal;
  row.spacing = 10;
  self.licenseKeyField = [NSSecureTextField textFieldWithString:@""];
  self.licenseKeyField.placeholderString = @"Paste license key";
  self.licenseKeyField.translatesAutoresizingMaskIntoConstraints = NO;
  [self.licenseKeyField.widthAnchor constraintGreaterThanOrEqualToConstant:300].active = YES;
  [row addArrangedSubview:self.licenseKeyField];
  self.licenseActivateButton = HDButtonWithSymbol(@"Activate", self.target, @selector(activateLicense:), YES, HDSymbolRoleActivate);
  [self.licenseActivateButton.widthAnchor constraintEqualToConstant:96].active = YES;
  [self.licenseActivateButton.heightAnchor constraintEqualToConstant:30].active = YES;
  [row addArrangedSubview:self.licenseActivateButton];
  self.licenseEntry = row;
  [box addArrangedSubview:row];
  NSStackView *actions = [[NSStackView alloc] init];
  actions.orientation = NSUserInterfaceLayoutOrientationHorizontal;
  actions.spacing = 8;
  self.licenseCheckButton = HDButtonWithSymbol(@"Check License", self.target, @selector(checkLicense:), NO, HDSymbolRoleCheck);
  self.licenseDeactivateButton = HDButtonWithSymbol(@"Deactivate", self.target, @selector(deactivateLicense:), NO, HDSymbolRoleDeactivate);
  self.licenseBuyButton = HDButtonWithSymbol(@"Buy a License", self.target, @selector(buyLicense:), NO, HDSymbolRoleBuy);
  [actions addArrangedSubview:self.licenseCheckButton];
  [actions addArrangedSubview:self.licenseDeactivateButton];
  [actions addArrangedSubview:self.licenseBuyButton];
  self.licenseActions = actions;
  [box addArrangedSubview:actions];
  self.licenseTerms = HDLabel(@"A license works on up to two Macs. An internet connection is needed for validation every 14 days.", 11, NSFontWeightRegular, NSColor.secondaryLabelColor);
  [box addArrangedSubview:self.licenseTerms];
  [self.licenseTerms.widthAnchor constraintEqualToAnchor:box.widthAnchor].active = YES;
}

- (void)buildSettingsPage {
  NSView *page; NSStackView *stack = [self formPage:&page compact:YES]; self.settingsPage = page;
  [stack addArrangedSubview:[self titleRowWithRole:HDSymbolRoleSettings title:@"Settings"]];
  [stack addArrangedSubview:HDLabel(@"Preferences and support.", 13, NSFontWeightRegular, NSColor.secondaryLabelColor)];
  HDCardView *general = [self card]; [stack addArrangedSubview:general];
  [general.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active = YES;
  NSStackView *box = [self insetStack:general];
  [box addArrangedSubview:HDLabel(@"General", 14, NSFontWeightSemibold, NSColor.labelColor)];
  self.loginCheckbox = [NSButton checkboxWithTitle:@"Launch at login" target:self.target action:@selector(toggleLaunchAtLogin:)];
  self.notificationsCheckbox = [NSButton checkboxWithTitle:@"Notify when clips finish" target:self.target action:@selector(toggleNotifications:)];
  [box addArrangedSubview:self.loginCheckbox]; [box addArrangedSubview:self.notificationsCheckbox];
  [box addArrangedSubview:HDButton(@"Storage Settings…", self.target, @selector(showStorageSettings:), NO)];
  [box addArrangedSubview:HDButton(@"License…", self.target, @selector(showLicense:), NO)];
  HDCardView *support = [self card];
  [stack addArrangedSubview:support];
  [support.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active = YES;
  NSStackView *supportBox = [self insetStack:support];
  [supportBox addArrangedSubview:HDLabel(@"Support", 14, NSFontWeightSemibold, NSColor.labelColor)];
  NSStackView *supportActions = [NSStackView new]; supportActions.spacing = 8;
  [supportActions addArrangedSubview:HDButtonWithSymbol(@"Check for Updates…", self.target, @selector(checkForUpdates:), NO, HDSymbolRoleSettingsUpdates)];
  [supportActions addArrangedSubview:HDButtonWithSymbol(@"Export Diagnostics…", self.target, @selector(exportDiagnostics:), NO, HDSymbolRoleSettingsDiagnostics)];
  [supportBox addArrangedSubview:supportActions];
  NSTextField *supportNote = HDCaption(@"Export a diagnostic report when you need help with a capture or upload.");
  [supportBox addArrangedSubview:supportNote];
  [supportNote.widthAnchor constraintEqualToAnchor:supportBox.widthAnchor].active = YES;
  [stack addArrangedSubview:HDCaption(@"⌘1 Capture   ·   ⌘2 Clips   ·   ⌘3 Storage   ·   ⌘S Save Highlight")];
  NSButton *advanced = [NSButton checkboxWithTitle:@"Show advanced options" target:self action:@selector(advancedChanged:)];
  [stack addArrangedSubview:advanced];
  self.advancedOptions = [NSStackView new]; self.advancedOptions.orientation = NSUserInterfaceLayoutOrientationVertical;
  self.advancedOptions.alignment = NSLayoutAttributeLeading; self.advancedOptions.spacing = 8;
  [self.advancedOptions addArrangedSubview:HDButton(@"Open Configuration File", self.target, @selector(openConfig:), NO)];
  [self.advancedOptions addArrangedSubview:HDButton(@"Open App Data Folder", self.target, @selector(openStateFolder:), NO)];
  [self.advancedOptions addArrangedSubview:HDButton(@"Open Web Dashboard", self.target, @selector(site:), NO)];
  [stack addArrangedSubview:self.advancedOptions]; self.advancedOptions.hidden = YES;
  [stack addArrangedSubview:HDCaption([NSString stringWithFormat:@"Highlight Desk %@", NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"] ?: @"3.0.0"])];
}

- (void)advancedChanged:(NSButton *)sender { self.advancedOptions.hidden = sender.state != NSControlStateValueOn; }

- (void)storageAdvancedChanged:(NSButton *)sender { self.storageAdvancedOptions.hidden = sender.state != NSControlStateValueOn; }

- (void)setLocalOutputPath:(NSString *)path {
  self.localOutputPathLabel.stringValue = path.stringByAbbreviatingWithTildeInPath;
  self.localOutputPathLabel.toolTip = path;
}

- (void)setLibraryEmpty:(BOOL)empty {
  self.libraryEmptyView.hidden = !empty;
  self.libraryScroll.hidden = empty;
  BOOL filtered = self.clipSearchField.stringValue.length || self.clipFilterControl.selectedSegment != 0;
  self.libraryEmptyTitle.stringValue = filtered ? @"No matching clips" : @"Your highlights start here";
  self.libraryEmptyBody.stringValue = filtered ? @"Try another search or show all clips in your library." : @"Capture a live stream or find moments in a past broadcast.";
  self.libraryEmptyAction.title = filtered ? @"Clear Search & Filters" : @"Go to Capture";
}

- (void)libraryEmptyClicked:(id)sender {
  if (self.clipSearchField.stringValue.length || self.clipFilterControl.selectedSegment != 0) {
    self.clipSearchField.stringValue = @"";
    self.clipFilterControl.selectedSegment = 0;
    if ([self.target respondsToSelector:@selector(reloadHistoryFromDisk)])
      [self.target performSelector:@selector(reloadHistoryFromDisk)];
  } else [self selectPage:HDPageCapture];
}

- (void)syncStorageVisibility {
  BOOL local = self.storageModePopup.indexOfSelectedItem == 0;
  self.storageFolderRow.hidden = local;
  self.storageKeepLocalCheckbox.hidden = local;
  self.storageDeleteCheckbox.hidden = YES;
  self.localOutputBox.hidden = !local;
}


- (void)updateSummaryWithClips:(NSInteger)clips queue:(NSInteger)queue storage:(NSString *)storage trial:(NSInteger)trial {
  self.sessionSummary.stringValue = [NSString stringWithFormat:@"%ld clip%@ this session · %ld pending upload%@ · %@", (long)clips, clips == 1 ? @"" : @"s", (long)queue, queue == 1 ? @"" : @"s", storage.length ? storage : @"This Mac"];
}

- (void)setSessionLive:(BOOL)live status:(NSString *)status {
  [self setSessionState:live ? HDSessionStateLive : HDSessionStateReady status:status];
}

- (void)setSessionState:(HDSessionState)state status:(NSString *)status {
  HDSymbolRole role = HDSymbolRoleStatusReady;
  NSColor *color = NSColor.secondaryLabelColor;
  NSString *label = @"Idle";
  NSString *heroTitle = self.channelField.stringValue.length ? [NSString stringWithFormat:@"Ready to capture %@", self.channelField.stringValue] : @"Enter a channel to begin";
  NSString *heroSubtitle = @"Start capture and keep Highlight Desk running while the stream is live.";
  switch (state) {
    case HDSessionStateLive:
      role = HDSymbolRoleStatusLive; color = HDLive(); label = @"Capturing";
      heroTitle = @"Capturing highlights";
      heroSubtitle = status.length ? status : @"Chat connected. Highlights are being captured.";
      break;
    case HDSessionStateReconnecting:
      role = HDSymbolRoleStatusReconnecting; color = HDWarn(); label = @"Reconnecting";
      heroTitle = @"Reconnecting to chat…";
      heroSubtitle = status.length ? status : @"The recorder is reconnecting to the stream.";
      break;
    case HDSessionStateStopping:
      role = HDSymbolRoleStatusStopping; color = NSColor.secondaryLabelColor; label = @"Stopping";
      heroTitle = @"Stopping capture…";
      heroSubtitle = status.length ? status : @"Finishing the current clip and closing the recorder.";
      break;
    case HDSessionStateError:
      role = HDSymbolRoleStatusError; color = HDWarn(); label = @"Needs attention";
      heroTitle = @"Capture interrupted.";
      heroSubtitle = status.length ? status : @"Check the recorder status and try again.";
      break;
    case HDSessionStateReady:
    default:
      break;
  }
  if (self.vodMode && !self.liveRunning) {
    if (state == HDSessionStateReady) {
      heroTitle = self.vodRunning ? @"Finding highlights" : @"Find highlights in a VOD";
      heroSubtitle = status.length ? status : @"Paste a past broadcast link. Highlight Desk reads the chat replay and saves the moments chat reacted to.";
    } else if (state == HDSessionStateLive) {
      label = @"Scanning VOD";
      heroTitle = @"Finding highlights";
    } else if (state == HDSessionStateStopping) {
      label = @"Cancelling";
      heroTitle = @"Cancelling…";
    } else if (state == HDSessionStateError) {
      heroTitle = @"VOD scan stopped.";
    }
  }
  self.sidebarStatusText.stringValue = label;
  self.sidebarStatusText.textColor = state == HDSessionStateLive ? HDLive() : HDText();
  self.sidebarStatusIcon.image = HDSymbolImage(role, 11, NSFontWeightSemibold, @"Session status");
  self.sidebarStatusIcon.contentTintColor = color;
  self.captureHeroTitle.stringValue = heroTitle;
  self.captureHeroSubtitle.stringValue = heroSubtitle;
  self.statusLabel.hidden = !self.statusLabel.stringValue.length || [self.statusLabel.stringValue isEqualToString:heroSubtitle];
}

- (void)setCaptureRunning:(BOOL)running {
  self.liveRunning = running;
  self.vodButton.enabled = !running;
  self.vodButton.toolTip = running ? @"Stop the live capture first." : nil;
  self.channelField.enabled = !running;
  self.toggleButton.image = HDSymbolImage(running ? HDSymbolRoleStop : HDSymbolRoleRecord, 13, NSFontWeightSemibold, running ? @"Stop capture" : @"Start capture");
  self.toggleButton.imagePosition = NSImageLeading;
  self.toggleButton.imageHugsTitle = YES;
}

- (void)setLicenseState:(HDLicenseState)state {
  BOOL disabled = state == HDLicenseStateDisabled;
  BOOL active = state == HDLicenseStateValid;
  self.licenseEntry.hidden = disabled || active;
  self.licenseActions.hidden = disabled;
  self.licenseTerms.hidden = disabled;
  self.licenseBuyButton.hidden = disabled || active;
  self.licenseCheckButton.hidden = !active && !self.licenseCheckButton.enabled;
  self.licenseDeactivateButton.hidden = !active && !self.licenseDeactivateButton.enabled;
  if (active) self.licenseTrialLabel.stringValue = @"License active";
  HDSymbolRole role = HDSymbolRoleLicenseTrial;
  NSColor *color = NSColor.secondaryLabelColor;
  switch (state) {
    case HDLicenseStateValid: role = HDSymbolRoleLicenseValid; color = HDGood(); break;
    case HDLicenseStateExpired: role = HDSymbolRoleLicenseExpired; color = HDWarn(); break;
    case HDLicenseStateDisabled: role = HDSymbolRoleLicenseDisabled; color = HDMuted(); break;
    case HDLicenseStateTrial: role = HDSymbolRoleLicenseTrial; color = HDWarn(); break;
  }
  self.licenseStatusIcon.image = HDSymbolImage(role, 22, NSFontWeightSemibold, @"License status");
  self.licenseStatusIcon.contentTintColor = color;
}

- (void)presentOnboarding {
  if (self.onboardingWindow) return;
  NSWindow *sheet = [[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,520,370) styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
  sheet.title = @"Set Up Capture";
  sheet.contentView.wantsLayer = YES;
  [sheet.effectiveAppearance performAsCurrentDrawingAppearance:^{ sheet.contentView.layer.backgroundColor = NSColor.windowBackgroundColor.CGColor; }];
  NSStackView *stack = [self insetStack:sheet.contentView]; stack.spacing = 14;
  [stack addArrangedSubview:HDLabel(@"Your first highlight", 22, NSFontWeightSemibold, NSColor.labelColor)];
  [stack addArrangedSubview:HDLabel(@"Choose a channel and save location to get started.", 13, NSFontWeightRegular, NSColor.secondaryLabelColor)];
  [stack addArrangedSubview:HDLabel(@"Twitch channel", 12, NSFontWeightMedium, NSColor.labelColor)];
  self.onboardingChannel = [NSTextField textFieldWithString:self.channelField.stringValue ?: @""];
  self.onboardingChannel.placeholderString = @"Enter a username";
  [stack addArrangedSubview:self.onboardingChannel];
  [self.onboardingChannel.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active = YES;
  [self.onboardingChannel.heightAnchor constraintEqualToConstant:28].active = YES;
  self.onboardingStoragePopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
  [self.onboardingStoragePopup addItemsWithTitles:@[@"This Mac", @"Dropbox", @"Google Drive"]];
  [self.onboardingStoragePopup selectItemAtIndex:self.storageModePopup.indexOfSelectedItem];
  self.onboardingStoragePopup.target = self; self.onboardingStoragePopup.action = @selector(onboardingDestinationChanged:);
  NSStackView *destination = [NSStackView new]; destination.spacing = 12;
  [destination addArrangedSubview:HDLabel(@"Save clips to", 12, NSFontWeightMedium, NSColor.labelColor)];
  [destination addArrangedSubview:self.onboardingStoragePopup]; [stack addArrangedSubview:destination];
  self.onboardingStorageNote = HDCaption(@"");
  [stack addArrangedSubview:self.onboardingStorageNote];
  [self.onboardingStorageNote.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active = YES;
  [self onboardingDestinationChanged:nil];
  self.onboardingPermission = [NSButton checkboxWithTitle:@"I have permission to record this channel." target:self action:@selector(onboardingInputChanged:)];
  [stack addArrangedSubview:self.onboardingPermission];
  NSStackView *actions = [NSStackView new]; actions.spacing = 8;
  NSButton *later = HDButton(@"Set Up Later", self.target, @selector(onboardingSkip:), NO);
  self.onboardingContinue = HDButton(@"Start Capture", self.target, @selector(onboardingStart:), YES);
  self.onboardingContinue.keyEquivalent = @"\r";
  [actions addArrangedSubview:later]; [actions addArrangedSubview:self.onboardingContinue]; [stack addArrangedSubview:actions];
  [stack addArrangedSubview:HDCaption(@"Keep the app running while the stream is live. Output is vertical (9:16).")];
  self.onboardingWindow = sheet;
  [self onboardingDestinationChanged:nil];
  [self onboardingInputChanged:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onboardingInputChanged:) name:NSControlTextDidChangeNotification object:self.onboardingChannel];
  [self.window beginSheet:sheet completionHandler:nil];
  [sheet makeFirstResponder:nil];
}

- (void)onboardingDestinationChanged:(id)sender {
  BOOL local = self.onboardingStoragePopup.indexOfSelectedItem == 0;
  self.onboardingStorageNote.stringValue = local ? @"Clips are saved on this Mac. You can change the folder in Storage." : @"Connect this account in Storage before starting cloud capture.";
  if (self.onboardingContinue) self.onboardingContinue.title = local ? @"Start Capture" : @"Continue to Storage";
}

- (void)onboardingInputChanged:(id)sender {
  NSString *name = [self.onboardingChannel.stringValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
  self.onboardingContinue.enabled = self.onboardingPermission.state == NSControlStateValueOn && [[NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"[A-Za-z0-9_]{1,25}"] evaluateWithObject:name];
}


- (void)dismissOnboarding {
  if (!self.onboardingWindow) return;
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSControlTextDidChangeNotification object:self.onboardingChannel];
  [self.window endSheet:self.onboardingWindow];
  self.onboardingWindow = nil;
}

@end
