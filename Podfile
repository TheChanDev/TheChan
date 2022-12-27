platform :ios, '14.0'
use_frameworks!
inhibit_all_warnings!

source 'https://cdn.cocoapods.org/'

target 'TheChan' do
    pod 'Alamofire', '~> 4.0'
    pod 'Kingfisher', '~> 7.4.1'
    pod 'Fuzi', '~> 3.1.3'
    pod 'RealmSwift', '~> 10.33.0'
    pod 'IQKeyboardManagerSwift', '~> 6.5.10'
    pod 'CCBottomRefreshControl', '~> 0.5.2'
    pod 'Texture', '~> 3.1.0'
    pod 'TUSafariActivity', '~> 1.0'
    pod 'DZNEmptyDataSet', '~> 1.8.1'
    pod 'EasyTipView', '~> 2.1.0'
    pod 'FDFullscreenPopGesture', '~> 1.1'
    pod 'YYText', '~> 1.0.7'
    pod 'MobileVLCKit', '~> 3.3.0'
    pod 'Reveal-SDK', :configurations => ['Debug']
end

post_install do |installer|
     installer.pods_project.targets.each do |target|
         target.build_configurations.each do |config|
            if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 14.0
              config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
            end
         end
     end
end
