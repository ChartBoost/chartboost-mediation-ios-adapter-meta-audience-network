Pod::Spec.new do |spec|
  spec.name        = 'ChartboostMediationAdapterMetaAudienceNetwork'
  spec.version     = '5.6.22.0.0'
  spec.license     = { :type => 'MIT', :file => 'LICENSE.md' }
  spec.homepage    = 'https://github.com/ChartBoost/chartboost-mediation-ios-adapter-meta-audience-network'
  spec.authors     = { 'Chartboost' => 'https://www.chartboost.com/' }
  spec.summary     = 'Chartboost Mediation iOS SDK Meta Audience Network adapter.'
  spec.description = 'Meta Audience Network Adapters for mediating through Chartboost Mediation. Supported ad formats: Banner, Interstitial, and Rewarded.'

  # Source
  spec.module_name  = 'ChartboostMediationAdapterMetaAudienceNetwork'
  spec.source       = { :git => 'https://github.com/ChartBoost/chartboost-mediation-ios-adapter-meta-audience-network.git', :tag => spec.version }
  spec.source_files = 'Source/**/*.{swift}'
  spec.resource_bundles = { 'ChartboostMediationAdapterMetaAudienceNetwork' => ['PrivacyInfo.xcprivacy'] }

  # Minimum supported versions
  spec.swift_version         = '5.0'
  spec.ios.deployment_target = '15.0'

  # System frameworks used
  spec.ios.frameworks = ['Foundation', 'SafariServices', 'UIKit', 'WebKit']

  # Dependencies
  spec.dependency 'ChartboostMediationSDK', '~> 5.0'
  spec.dependency 'FBAudienceNetwork', '~> 6.22.0'

  spec.static_framework = true
end
