#import "BelnetLibPlugin.h"
#if __has_include(<belnet_lib/belnet_lib-Swift.h>)
#import <belnet_lib/belnet_lib-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "belnet_lib-Swift.h"
#endif

@implementation BelnetLibPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftBelnetLibPlugin registerWithRegistrar:registrar];
}
@end
