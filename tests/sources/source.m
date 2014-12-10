// File taken from https://github.com/gradha/seohtracker-ios/blob/396812711d7886294070bc99738893d1d3b50c62/src/EHApp_delegate.m

#import "EHApp_delegate.h"

#import "google_analytics_config.h"

#import "ELHASO.h"
#import "GAI.h"
#import "Harpy.h"
#import "IQKeyBoardManager.h"
#import "NSNotificationCenter+ELHASO.h"
#import "SHNotifications.h"
#import "categories/NSString+seohyun.h"
#import "n_global.h"
#import "user_config.h"


@implementation EHApp_delegate

#pragma mark -
#pragma mark Life

- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    NSString *db_path = get_path(@"", DIR_LIB);
    DLOG(@"Setting database path to %@", db_path);

    [self generate_changelog_timestamp_if_empty:db_path];

    [self setup_google_analytics];

    if (!open_db([db_path cstring]))
        abort();
    DLOG(@"Got %d entries", get_num_weights());

    IQKeyboardManager *keyboard = [IQKeyboardManager sharedManager];
    [keyboard setEnable:YES];
    [keyboard setEnableAutoToolbar:YES];
    [keyboard setShouldResignOnTouchOutside:YES];

    // Customize navigation bar on iOS6.
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7) {
        UIColor *color = [UIColor darkGrayColor];
        [[UINavigationBar appearance] setTintColor:color];
    }

    configure_metric_locale();

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center refresh_observer:self selector:@selector(locale_did_change:)
        name:NSCurrentLocaleDidChangeNotification object:nil];

    Harpy *harpy = [Harpy sharedInstance];
    [harpy setAppID:@"805779021"];
    [harpy setAppName:@"Seohtracker"];
    [harpy setAlertType:HarpyAlertTypeSkip];

    // If the app wasn't launched to open input files, prune the inbox folder.
    if (!launchOptions[UIApplicationLaunchOptionsURLKey])
        dispatch_async_low(^{ [self clean_inbox]; });

    return YES;
}

/// Checks new versions of official app.
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[Harpy sharedInstance] checkVersionDaily];
}

/// Handles opening of CSV files.
- (BOOL)application:(UIApplication*)application openURL:(NSURL*)url
    sourceApplication:(NSString*)sourceApplication annotation:(id)annotation
{
    DLOG(@"Hey, we were asked to open '%@'", url);
    DLOG(@"Source app %@, annotation %@", sourceApplication, annotation);
    return [self can_move_csv_file:[url path]];
}

#pragma mark -
#pragma mark Methods

/** Hook to learn when the user locale changes, so we can detect our stuff.
 *
 * If the user metric were on automatic, the notification
 * user_metric_prefereces_changed is generated for any visible EHSettings_vc to
 * update its view as if the user had changed the setting.
 *
 * This also checks if the locale decimal separator changed, generating the
 * event decimal_separator_changed if needed.
 */
- (void)locale_did_change:(NSNotification*)notification
{
    if (0 == user_metric_preference()) {
        DLOG(@"Weight automatic: rechecking system value");
        set_nimrod_metric_use_based_on_user_preferences();
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center postNotificationName:user_metric_prefereces_changed object:nil];
    }

    NSLocale *locale = [NSLocale autoupdatingCurrentLocale];
    NSString *separator = [locale objectForKey:NSLocaleDecimalSeparator];
    if (set_decimal_separator([separator cstring])) {
        DLOG(@"The decimal separator changed to '%@'", separator);
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center postNotificationName:decimal_separator_changed object:nil];
    }
}

/** Generates user preferences timestamp for changelog version.
 *
 * If the user doesn't have yet a version value for seen changelog file, this
 * function creates it based on a heuristic: if the database file exists, it
 * means the user installed the app in v1 when changelog version wasn't
 * tracked. For this reason, generate the user preference with 1.
 *
 * But if the preference is not there, and the database is not there either, it
 * means a fresh install. For fresh installs we set the version number to the
 * current app number, so as to not nag new users with changes they likely are
 * not interested in.
 */
- (void)generate_changelog_timestamp_if_empty:(NSString*)db_path
{
    if (config_changelog_version() > 0)
        return;

    if (db_exists([db_path cstring])) {
        DLOG(@"DB exists! Setting changelog to 1");
        set_config_changelog_version(1);
    } else {
        DLOG(@"DB doesn't exist, setting changelog version to %0.1f",
            bundle_version());
        set_config_changelog_version(bundle_version());
    }
}

/** Checks and moves the requested input file into our sandbox.
 *
 * This method is invoked when the user wants to open a CSV file. The method
 * will attempt to move the file to the user's document directory, so that it
 * is visible by the import vc. The move has to be non destructive: if a target
 * destination exists with the same name, the method will find out a different
 * numbered name.
 *
 * Returns YES if the move was done successfully.
 */
- (BOOL)can_move_csv_file:(NSString*)path
{
    DLOG(@"Can move '%@'?", path);

    NSFileManager *m = [NSFileManager defaultManager];
    NSString *file = [path lastPathComponent];
    NSString *target = get_path(file, DIR_DOCS);
    NSString *ext = [[file pathExtension] lowercaseString];
    NSString *base = [file stringByDeletingPathExtension];
    const BOOL valid = [ext isEqualToString:@"csv"];
    int counter = 0;
    // Iterate different names until we find one.
    while (valid && [m fileExistsAtPath:target]) {
        counter += 1;
        target = get_path([NSString stringWithFormat:@"%@-%d.%@",
            base, counter, ext], DIR_DOCS);
    }
    if (!valid)
        target = nil;

    // Ok, found name, trying to move.
    DLOG(@"Moving '%@' to '%@'", path, target);
    NSError *error = nil;
    const BOOL ret = [m moveItemAtPath:path toPath:target error:&error];
    if (!ret && error)
        LOG(@"Could not move inbox file: %@", [error localizedDescription]);

    // Tells the application a file was added.
    if (ret) {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center postNotificationName:did_accept_file object:nil
            userInfo:@{did_accept_file_path:target}];
    }

    // Schedule removal of inbox files.
    dispatch_async_low(^{ [self clean_inbox]; });
    return ret;
}

/// Removes all files from the inbox folder.
- (void)clean_inbox
{
    NSFileManager *m = [NSFileManager defaultManager];
    NSString *path = get_path(@"Inbox", DIR_DOCS);
    NSError *error = nil;
    for (NSString *entry in [m contentsOfDirectoryAtPath:path error:NULL]) {
        NSString *file = [path stringByAppendingPathComponent:entry];
        DLOG(@"Removing %@", file);
        const BOOL ret = [m removeItemAtPath:file error:&error];
        if (!ret && error)
            LOG(@"Could not remove file '%@': %@", file,
                [error localizedDescription]);
    }
}

/// Configures the tracking of google analytics.
- (void)setup_google_analytics
{
#ifdef GOOGLE_ANALYTICS
#ifdef DEBUG
    //[[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
    [[GAI sharedInstance] setDispatchInterval:3];
#endif

    // Initialize tracker.
    [[GAI sharedInstance] trackerWithTrackingId:GOOGLE_ANALYTICS];
#else
    DLOG(@"Not activating Google Analytics, missing configuration.");
#ifdef APPSTORE
#error Can't build appstore release without google defines!
#endif
#endif
}

@end

#pragma mark -
#pragma mark Global functions

/// Builds an alert view for an invalid user entered weight.
UIAlertView *alert_for_invalid_weight(NSString *bad_weight)
{
    NSString *title = @"Weights";
    NSString *message = [NSString stringWithFormat:@"The weight %@ is "
        @"invalid, try another one", bad_weight];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
        message:message delegate:nil cancelButtonTitle:@"OK"
        otherButtonTitles:nil];
    return alert;
}

/** Ugly hack to reposition a view despite iAds
 *
 * By default iAds pushes the content up, but that messes the layout. This
 * function modifies a fake *movable* view to come down 88 pixels only on the
 * iPhone5, ignoring resize requests by iAds.
 *
 * I guess there is a better way to do it, but this seems easy…
 */
void patch_movable_view(UIView *movable_view)
{
    // iphone5 screen detection from http://stackoverflow.com/a/12535566/172690.
    const bool isiPhone5 = CGSizeEqualToSize(
        [[UIScreen mainScreen] preferredMode].size, CGSizeMake(640, 1136));
    if (isiPhone5) {
        CGRect r = movable_view.frame;
        r.origin.y = 88;
        movable_view.frame = r;
    }
}
