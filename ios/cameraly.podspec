#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint cameraly.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'cameraly'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter camera package that provides an enhanced, easy-to-use interface.'
  s.description      = <<-DESC
A Flutter camera package that provides an enhanced, easy-to-use interface on top of the official camera plugin.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  
  # Make sure the plugin is properly modularized
  s.module_name = 'cameraly'
end 