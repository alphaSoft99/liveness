#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint liveness.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'liveness'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter project.'
  s.description      = <<-DESC
A new Flutter project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'

  s.preserve_paths = 'AAILivenessSDK.framework'
  s.xcconfig = { 'OTHER_LDFLAGS' => '-framework AAILivenessSDK' }
  s.vendored_frameworks = 'AAILivenessSDK.framework'
  s.public_header_files = 'Classes/**/*.h'
end
