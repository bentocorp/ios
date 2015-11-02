# Uncomment this line to define a global platform for your project
platform :ios, '7.0'

pod 'Stripe'
pod 'Stripe/ApplePay'
pod 'PaymentKit'
pod 'Mixpanel'
pod 'Canvas'
pod 'Adjust', :git => 'git://github.com/adjust/ios_sdk.git', :tag => 'v4.2.7'
pod 'Branch'
pod 'FCUUID'
pod 'PureLayout'
pod 'UIActivityIndicator-for-SDWebImage'
pod 'FDKeychain'
pod 'SIOSocket', '~> 0.2.0'

pod 'Mapbox-iOS-SDK'
# disable bitcode in every sub-target
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'NO'
        end
    end
end
