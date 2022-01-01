#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint fluetooth.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'fluetooth'
  s.version          = '0.0.1'
  s.summary          = 'Flutter library for sending bytes to Bluetooth devices.'
  s.description      = <<-DESC
Flutter library for sending bytes to Bluetooth devices.
                       DESC
  s.homepage         = 'https://iandis.web.app'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Iandi Santulus' => 'iandi.santulusn@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '10.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
