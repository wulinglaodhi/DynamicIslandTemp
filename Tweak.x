#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>
#import <notify.h>
#import <objc/message.h>
#import <math.h>

static NSString * const kDITDomain = @"com.hello.dynamicislandtemp";

static BOOL ditBool(NSString *key, BOOL fallback) {
    id v = CFBridgingRelease(
        CFPreferencesCopyAppValue(
            (__bridge CFStringRef)key,
            (__bridge CFStringRef)kDITDomain
        )
    );

    return v ? [v boolValue] : fallback;
}

static double ditDouble(NSString *key, double fallback) {
    id v = CFBridgingRelease(
        CFPreferencesCopyAppValue(
            (__bridge CFStringRef)key,
            (__bridge CFStringRef)kDITDomain
        )
    );

    return v ? [v doubleValue] : fallback;
}

static double DITBatteryTemperature(void) {
    io_service_t service = IOServiceGetMatchingService(
        kIOMasterPortDefault,
        IOServiceMatching("AppleSmartBattery")
    );

    if (!service)
        return NAN;

    CFTypeRef value = IORegistryEntryCreateCFProperty(
        service,
        CFSTR("Temperature"),
        kCFAllocatorDefault,
        0
    );

    IOObjectRelease(service);

    if (!value)
        return NAN;

    double result = 0.0;

    if (CFGetTypeID(value) == CFNumberGetTypeID()) {
        CFNumberGetValue(
            (CFNumberRef)value,
            kCFNumberDoubleType,
            &result
        );
    }

    CFRelease(value);

    /*
     AppleSmartBattery 的 Temperature
     通常是摄氏度的 1/100。
    */

    if (fabs(result) > 100.0)
        result /= 100.0;

    return result;
}


@interface DITPassthroughWindow : UIWindow
@end


@implementation DITPassthroughWindow

- (UIView *)hitTest:(CGPoint)point
          withEvent:(UIEvent *)event {
    return nil;
}

@end


@interface DITOverlayView : UIView

@property(nonatomic, strong) UILabel *label;
@property(nonatomic, strong) NSTimer *timer;

@end


@implementation DITOverlayView

- (instancetype)initWithFrame:(CGRect)frame {

    self = [super initWithFrame:frame];

    if (self) {

        self.backgroundColor =
            [UIColor colorWithWhite:0.0 alpha:0.96];

        self.layer.cornerRadius =
            frame.size.height / 2.0;

        self.layer.masksToBounds = YES;


        _label = [[UILabel alloc] initWithFrame:self.bounds];

        _label.textAlignment =
            NSTextAlignmentCenter;

        _label.textColor =
            UIColor.whiteColor;

        _label.font =
            [UIFont systemFontOfSize:15.0
                              weight:UIFontWeightSemibold];

        _label.adjustsFontSizeToFitWidth = YES;

        _label.minimumScaleFactor = 0.7;

        _label.text = @"--°C";

        [self addSubview:_label];


        [[NSNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(ditPreferencesChanged:)
                   name:@"DynamicIslandTempPreferencesChanged"
                 object:nil];


        [self ditApplyPreferences];

        [self ditUpdateTemperature];


        NSTimeInterval interval =
            MAX(
                1.0,
                MIN(
                    30.0,
                    ditDouble(@"RefreshInterval", 2.0)
                )
            );


        _timer =
            [NSTimer scheduledTimerWithTimeInterval:interval
                                             target:self
                                           selector:@selector(ditUpdateTemperature)
                                           userInfo:nil
                                            repeats:YES];
    }

    return self;
}


- (void)dealloc {

    [_timer invalidate];

    [[NSNotificationCenter defaultCenter]
        removeObserver:self];
}


- (void)ditPreferencesChanged:(NSNotification *)note {

    dispatch_async(
        dispatch_get_main_queue(),
        ^{

            [self ditApplyPreferences];

            [self ditRestartTimer];

            [self ditUpdateTemperature];

        }
    );
}


- (void)ditRestartTimer {

    [_timer invalidate];

    NSTimeInterval interval =
        MAX(
            1.0,
            MIN(
                30.0,
                ditDouble(@"RefreshInterval", 2.0)
            )
        );


    _timer =
        [NSTimer scheduledTimerWithTimeInterval:interval
                                         target:self
                                       selector:@selector(ditUpdateTemperature)
                                       userInfo:nil
                                        repeats:YES];
}


- (void)ditApplyPreferences {

    BOOL enabled =
        ditBool(@"Enabled", YES);

    self.hidden = !enabled;


    CGFloat width =
        (CGFloat)ditDouble(
            @"IslandWidth",
            150.0
        );


    CGFloat fontSize =
        (CGFloat)ditDouble(
            @"FontSize",
            15.0
        );


    CGFloat offsetX =
        (CGFloat)ditDouble(
            @"OffsetX",
            0.0
        );


    CGFloat offsetY =
        (CGFloat)ditDouble(
            @"OffsetY",
            0.0
        );


    width =
        MAX(
            90.0,
            MIN(
                320.0,
                width
            )
        );


    fontSize =
        MAX(
            8.0,
            MIN(
                32.0,
                fontSize
            )
        );


    UIWindow *window = self.window;

    if (!window)
        return;


    CGFloat height = 37.0;


    CGFloat x =
        (window.bounds.size.width - width) / 2.0
        + offsetX;


    CGFloat y =
        11.0 + offsetY;


    x =
        MAX(
            -20.0,
            MIN(
                window.bounds.size.width - width + 20.0,
                x
            )
        );


    y =
        MAX(
            0.0,
            MIN(
                80.0,
                y
            )
        );


    self.frame =
        CGRectMake(
            x,
            y,
            width,
            height
        );


    self.layer.cornerRadius =
        height / 2.0;


    self.label.frame =
        self.bounds;


    self.label.font =
        [UIFont systemFontOfSize:fontSize
                          weight:UIFontWeightSemibold];
}


- (void)ditUpdateTemperature {

    if (!ditBool(@"Enabled", YES)) {

        self.hidden = YES;

        return;
    }


    double temp =
        DITBatteryTemperature();


    if (isnan(temp)
        || temp < -40.0
        || temp > 100.0) {

        self.label.text = @"--°C";

        return;
    }


    self.label.text =
        [NSString stringWithFormat:@"%.1f°C", temp];
}

@end



static DITPassthroughWindow *gDITWindow = nil;

static DITOverlayView *gDITOverlay = nil;



static void DITCreateOverlay(void) {

    if (gDITWindow
        || ![UIApplication sharedApplication]) {

        return;
    }


    UIScreen *screen =
        UIScreen.mainScreen;


    gDITWindow =
        [[DITPassthroughWindow alloc]
            initWithFrame:screen.bounds];


    gDITWindow.backgroundColor =
        UIColor.clearColor;


    gDITWindow.windowLevel =
        UIWindowLevelAlert + 100.0;


    gDITWindow.hidden = NO;


    gDITWindow.userInteractionEnabled = NO;


    UIViewController *vc =
        [UIViewController new];


    vc.view.backgroundColor =
        UIColor.clearColor;


    gDITWindow.rootViewController = vc;


    gDITOverlay =
        [[DITOverlayView alloc]
            initWithFrame:CGRectMake(
                0,
                11,
                150,
                37
            )];


    [vc.view addSubview:gDITOverlay];


    [[NSNotificationCenter defaultCenter]
        addObserverForName:
            @"DynamicIslandTempPreferencesChanged"
        object:nil
        queue:
            [NSOperationQueue mainQueue]
        usingBlock:
            ^(NSNotification *note) {

                [gDITOverlay ditApplyPreferences];

            }];
}



%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {

    %orig;


    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            (int64_t)(1.5 * NSEC_PER_SEC)
        ),
        dispatch_get_main_queue(),
        ^{

            DITCreateOverlay();

        }
    );
}

%end



static void DITNotifyPreferencesChanged(void) {

    [[NSNotificationCenter defaultCenter]
        postNotificationName:
            @"DynamicIslandTempPreferencesChanged"
        object:nil];
}



%ctor {

    int token = 0;


    notify_register_dispatch(
        "com.hello.dynamicislandtemp/preferences.changed",
        &token,
        dispatch_get_main_queue(),
        ^(int unused) {

            DITNotifyPreferencesChanged();

        }
    );
}