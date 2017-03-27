#
#  Be sure to run `pod spec lint Rapid.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name = 'Rapid'
  s.version = '0.0.3'
  s.license = 'MIT'
  s.summary = 'Rapid.io iOS SDK'
  s.homepage = 'https://github.com/Rapid-SDK/ios'
  s.authors = { 'Jan Schwarz' => 'jan.schwarz@strv.com' }
  s.source = { :git => "https://github.com/Rapid-SDK/ios.git", :tag => s.version }

  s.platform     = :ios, "8.0"

  s.source_files = 'Source/*.swift'
end
