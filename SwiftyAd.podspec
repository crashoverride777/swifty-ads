Pod::Spec.new do |s|

s.name = 'SwiftyMusic'
s.version = '8.1.3'
s.license = 'MIT'
s.summary = 'A swift helper to show ads from Google AdMob.'

s.homepage = 'https://github.com/crashoverride777/swifty-ad'
s.social_media_url = 'http://twitter.com/overrideiactive'

s.authors = { 'Dominik' => 'overrideinteractive@icloud.com' }

s.requires_arc = true
s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4' }

s.ios.deployment_target = '9.3'
#s.tvos.deployment_target = '10.2'

s.source = {
    :git => 'https://github.com/crashoverride777/swifty-ad.git',
    :tag => s.version
}

s.source_files = "SwiftyAd/**/*.{swift}"

s.dependency = 'Google-Mobile-Ads-SDK'

end
