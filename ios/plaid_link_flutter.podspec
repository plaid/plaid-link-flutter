#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint plaid_link_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'plaid_link_flutter'
  s.version          = '1.4.0'
  s.summary          = 'Plaid Link Flutter SDK.'
  s.description      = <<-DESC
Official Flutter plugin for Plaid Link.
                       DESC
  s.homepage         = 'https://github.com/plaid/plaid-link-flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Plaid' => 'support@plaid.com' }
  s.source           = { :path => '.' }
  s.source_files = 'plaid_link_flutter/Sources/plaid_link_flutter/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'
  s.vendored_frameworks = 'plaid_link_flutter/LinkKit.xcframework'
  s.preserve_paths = 'plaid_link_flutter/LinkKit.xcframework'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.9'

  s.resource_bundles = {'plaid_link_flutter_privacy' => ['plaid_link_flutter/Sources/plaid_link_flutter/Resources/PrivacyInfo.xcprivacy']}
end
