Pod::Spec.new do |s|

s.name = 'SwiftyAds'
s.version = '9.3.3'
s.license = { :type => 'MIT', :file => 'LICENSE' }
s.summary = 'A swift helper to show ads from Google AdMob. GDPR compliant.'
s.homepage = 'https://github.com/crashoverride777/swifty-ad'
s.social_media_url = 'http://twitter.com/overrideiactive'
s.authors = { 'Dominik' => 'overrideinteractive@icloud.com' }

s.swift_version = '5.0'
s.requires_arc = true
s.ios.deployment_target = '11.4'

s.source = {
    :git => 'https://github.com/crashoverride777/swifty-ad.git',
    :tag => s.version
}

s.source_files = "Source/**/*.{swift}"

s.dependency 'Google-Mobile-Ads-SDK'
s.dependency 'PersonalizedAdConsent'

s.static_framework = true

end
