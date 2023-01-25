Pod::Spec.new do |spec|
  spec.name        = 'ChartboostMediationAdapterMetaAudienceNetwork'
  spec.version     = '4.6.12.0.0'
  spec.license     = { :type => 'MIT', :file => 'LICENSE.md' }
  spec.homepage    = 'https://github.com/ChartBoost/chartboost-mediation-ios-adapter-meta-audience-network'
  spec.authors     = { 'Chartboost' => 'https://www.chartboost.com/' }
  spec.summary     = 'Chartboost Mediation iOS SDK Meta Audience Network adapter.'
  spec.description = 'Meta Audience Network Adapters for mediating through Chartboost Mediation. Supported ad formats: Banner, Interstitial, and Rewarded.'

  # Source
  spec.module_name  = 'ChartboostMediationAdapterMetaAudienceNetwork'
  spec.source       = { :git => 'https://github.com/ChartBoost/chartboost-mediation-ios-adapter-meta-audience-network.git', :tag => spec.version }
  spec.source_files = 'Source/**/*.{swift}'

  # Minimum supported versions
  spec.swift_version         = '5.0'
  spec.ios.deployment_target = '10.0'

  # System frameworks used
  spec.ios.frameworks = ['Foundation', 'SafariServices', 'UIKit', 'WebKit']
  
  # This adapter is compatible with all Chartboost Mediation 4.X versions of the SDK.
  spec.dependency 'ChartboostMediationSDK', '~> 4.0'

  # Partner network SDK and version that this adapter is certified to work with.
  spec.dependency 'FBAudienceNetwork', '6.12.0'
  # The partner network SDK is a static framework which requires the static_framework option.
  spec.static_framework = true
end
