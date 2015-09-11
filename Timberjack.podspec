Pod::Spec.new do |s|
  s.name = "Timberjack"
  s.version = "0.0.2"
  s.summary = "Automatic network activity logger for iOS and OSX, written in Swift."
  s.homepage = "https://github.com/andysmart/Timberjack"
  s.license = "MIT"
  s.author = { "Andy Smart" => "andy@andysmart.org" }
  s.social_media_url = "http://twitter.com/andyjsmart"
  s.source = { :git => "https://github.com/andysmart/Timberjack.git", :tag => s.version }
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
  s.source_files = 'Source/*.swift'
  s.requires_arc = true
end
