Pod::Spec.new do |s|

s.name = 'SwiftyAds'
s.version = '12.6.1'
s.license = 'MIT'
s.summary = 'A Swift library to display Google AdMob ads. GDPR, COPPA and App Tracking Transparency compliant.'
s.homepage = 'https://github.com/crashoverride777/swifty-ads'
s.authors = { 'Dominik' => 'overrideinteractive@icloud.com' }

s.swift_versions = ['5.1', '5.2', '5.3']
s.ios.deployment_target = '11.4'

s.requires_arc = true
s.static_framework = true

s.source = {
    :git => 'https://github.com/crashoverride777/swifty-ads.git',
    :tag => s.version
}

s.source_files = 'Sources/**/*.{h,m,swift}'

s.dependency 'Google-Mobile-Ads-SDK', '~> 8.4.0'

end
