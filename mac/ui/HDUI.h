#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, HDSessionState) {
  HDSessionStateReady = 0,
  HDSessionStateLive,
  HDSessionStateReconnecting,
  HDSessionStateStopping,
  HDSessionStateError
};

typedef NS_ENUM(NSInteger, HDLicenseState) {
  HDLicenseStateTrial = 0,
  HDLicenseStateValid,
  HDLicenseStateExpired,
  HDLicenseStateDisabled
};

typedef NS_ENUM(NSInteger, HDPage) {
  HDPageCapture = 0,
  HDPageClips = 1,
  HDPageStorage = 2,
  HDPageLicense = 3,
  HDPageSettings = 4
};

@interface HDUI : NSObject

@property(strong, readonly) NSWindow *window;

@property(strong) NSButton *loginCheckbox;
@property(strong) NSButton *notificationsCheckbox;
@property(strong) NSPopUpButton *onboardingStoragePopup;
@property(strong) NSTextField *onboardingStorageNote;

// Capture
@property(strong) NSTextField *channelField;
@property(strong) NSTextField *statusLabel;
@property(strong) NSTextField *telemetryLabel;
@property(strong) NSButton *toggleButton;
@property(strong) NSButton *saveButton;
@property(strong) NSButton *lastClipButton;

// Capture: VOD mode
@property(strong) NSSegmentedControl *captureModeControl;
@property(strong) NSTextField *vodField;
@property(strong) NSButton *vodButton;
@property(strong) NSStepper *vodTopStepper;
@property(strong) NSTextField *vodTopValue;
@property(strong) NSTextField *vodStartField;
@property(strong) NSTextField *vodEndField;
@property(strong) NSButton *vodCaptionsCheckbox;
@property(strong) NSButton *vodHookCheckbox;
@property(strong) NSTextField *vodHookTextField;
@property(readonly) BOOL vodMode;
@property(nonatomic) BOOL vodRunning;

// Clips
@property(strong) NSSearchField *clipSearchField;
@property(strong) NSSegmentedControl *clipFilterControl;
@property(strong) NSTableView *historyTable;
@property(strong) NSTextField *historyStatus;
@property(strong) NSButton *historyOpenButton;

// Storage
@property(strong) NSPopUpButton *storageModePopup; // hidden model control
@property(strong) NSTextField *storageStatus;
@property(strong) NSTextField *storageFolder;
@property(strong) NSButton *storageConnectButton;
@property(strong) NSButton *storageSaveButton;
@property(strong) NSButton *storageDisconnectButton;
@property(strong) NSButton *storageDeleteCheckbox;
@property(strong) NSButton *storageKeepLocalCheckbox;
@property(strong) NSButton *storageKeepRawCheckbox;

// License
@property(strong) NSTextField *licenseStatusLabel;
@property(strong) NSTextField *licenseTrialLabel;
@property(strong) NSSecureTextField *licenseKeyField;
@property(strong) NSButton *licenseActivateButton;
@property(strong) NSButton *licenseDeactivateButton;
@property(strong) NSButton *licenseCheckButton;
@property(strong) NSButton *licenseBuyButton;

// Onboarding
@property(strong) NSTextField *onboardingChannel;
@property(strong) NSButton *onboardingPermission;

- (instancetype)initWithTarget:(id)target;
- (void)selectPage:(HDPage)page;
- (HDPage)selectedPage;
- (void)presentOnboarding;
- (void)dismissOnboarding;
- (void)syncStorageCards;
- (void)syncStorageVisibility;
- (void)setLibraryEmpty:(BOOL)empty;
- (void)setLocalOutputPath:(NSString *)path;
- (void)refreshRecentPreviews;
- (void)updateRecentClips:(NSArray<NSDictionary *> *)entries;
- (void)updateSummaryWithClips:(NSInteger)clips
                         queue:(NSInteger)queue
                       storage:(NSString *)storage
                         trial:(NSInteger)trial;
- (void)setSessionLive:(BOOL)live status:(NSString *)status;
- (void)setSessionState:(HDSessionState)state status:(NSString *)status;
- (void)setCaptureRunning:(BOOL)running;
- (NSInteger)vodTopCount;
- (void)setLicenseState:(HDLicenseState)state;

@end
