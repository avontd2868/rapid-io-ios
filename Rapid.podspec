#
#  Be sure to run `pod spec lint Rapid.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name = 'Rapid'
  s.version = '1.1.0'
  s.license = 'MIT'
  s.summary = 'iOS, macOS and tvOS client for rapid.io realtime database'
  s.homepage = 'https://www.rapid.io'
  s.authors = { 'Jan Schwarz' => 'jan.schwarz@strv.com' }
  s.source = { :git => "https://github.com/rapid-io/rapid-io-ios.git", :tag => s.version }

  s.platforms = { :ios => "8.0", :osx => "10.10", :tvos => "9.0" }

  s.source_files = 'Source/*.swift', 'Source/**/*.swift'
end
