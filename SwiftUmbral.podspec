Pod::Spec.new do |s|
s.name             = "SwiftUmbral"
s.version          = "0.1"
s.summary          = "Umbral proxy re-encryption implementation in vanilla Swift for iOS ans macOS"

s.description      = <<-DESC
Umbral proxy re-encryption implementation in vanilla Swift, intended for mobile developers of privacy related apps.
DESC

s.homepage         = "https://github.com/shamatar/SwiftUmbral"
s.license          = 'Apache License 2.0'
s.author           = { "Alex Vlasov" => "alex.m.vlasov@gmail.com" }
s.source           = { :git => 'https://github.com/shamatar/SwiftUmbral.git', :tag => s.version.to_s }
s.social_media_url = 'https://twitter.com/shamatar'

s.swift_version = '4.1'
s.module_name = 'SwiftUmbral'
s.ios.deployment_target = "9.0"
s.osx.deployment_target = "10.11"
s.source_files = "SwiftUmbral/Classes/*.,swift, SwiftUmbral/SwiftUmbral.h",
s.public_header_files = "SwiftUmbral/SwiftUmbral.h"
s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

s.dependency 'BigInt', '~> 3.1'
s.dependency 'EllipticSwift', '~> 2.0'
s.dependency 'CryptoSwift', '~> 0.12'
end
