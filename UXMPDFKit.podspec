#
# Be sure to run `pod lib lint UXMPDFKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "UXMPDFKit"
  s.version          = "0.2.10"
  s.summary          = "A fully functioning PDF reader written completely in Swift"

  s.homepage         = "https://github.com/uxmstudio/UXMPDFKit"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Chris Anderson" => "chris@uxmstudio.com" }
  s.source           = { :git => "https://github.com/uxmstudio/UXMPDFKit.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'UXMPDFKit' => ['Pod/Assets/**/*.{xcassets,png,json}']
  }
end
