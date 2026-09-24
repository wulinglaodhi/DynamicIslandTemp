#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <notify.h>


@interface DynamicIslandTempPrefsListController : PSListController
@end


@implementation DynamicIslandTempPrefsListController


- (NSArray *)specifiers {

    if (!_specifiers) {

        _specifiers =
            [self loadSpecifiersFromPlistName:@"Root"
                                       target:self];
    }

    return _specifiers;
}


- (void)setPreferenceValue:(id)value
                 specifier:(PSSpecifier *)specifier {

    [super setPreferenceValue:value
                    specifier:specifier];


    CFPreferencesAppSynchronize(
        CFSTR("com.hello.dynamicislandtemp")
    );


    notify_post(
        "com.hello.dynamicislandtemp/preferences.changed"
    );
}

@end