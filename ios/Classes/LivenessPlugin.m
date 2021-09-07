#import "LivenessPlugin.h"
#if __has_include(<liveness/liveness-Swift.h>)
#import <liveness/liveness-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "liveness-Swift.h"
#endif

@implementation LivenessPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftLivenessPlugin registerWithRegistrar:registrar];
}
@end
