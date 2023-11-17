#
# Be sure to run `pod lib lint SwiftHooks.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SwiftHooks'
  s.version          = '1.0.0'
  s.summary          = '一个简单易用的状态管理框架'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  类似于 React Hooks,
SwiftHooks是一个简单易用的状态管理框架，它可以帮助你管理应用中的状态，让你的代码更加清晰易懂。
                       DESC

  s.homepage         = 'https://github.com/atlasv-hz-ios/SwiftHooks'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'stephenwzl' => 'zhilong@atlasv.com' }
  s.source           = { :git => 'https://github.com/stephenwzl/SwiftHooks.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '12.0'

  s.source_files = 'SwiftHooks/Classes/**/*'
end
