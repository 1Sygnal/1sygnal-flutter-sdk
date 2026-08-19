#
# Production podspec for the public 1sygnal-flutter-sdk repo. Unlike ../onesygnal.podspec (used
# for monorepo local dev, which compiles apps/ios-sdk's source directly into this pod target — see
# its own comment for why), this depends on the published OneSygnalSDK pod. The sync workflow
# (.github/workflows/sync-flutter-sdk.yml) copies this over onesygnal.podspec and substitutes the
# placeholders below.
#
Pod::Spec.new do |s|
  s.name             = 'onesygnal'
  s.version          = '1.0.0'
  s.summary          = 'Flutter bindings for the OneSygnal native iOS SDK.'
  s.description      = <<-DESC
                      Official Flutter plugin bridging to the native OneSygnal iOS SDK.
                       DESC
  s.homepage         = 'https://1sygnal.app/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { '1Sygnal' => 'support@1sygnal.app' }
  s.source           = { :path => '.' }

  s.source_files     = 'onesygnal/Sources/onesygnal/**/*'
  s.dependency 'Flutter'
  s.dependency 'OneSygnalSDK', '~> 1.0.0'

  s.platform         = :ios, '15.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.9'
end
