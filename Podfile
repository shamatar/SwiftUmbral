# Uncomment the next line to define a global platform for your project
def import_pods
  pod 'EllipticSwift', '~> 2.0.7'
  pod 'CryptoSwift', '~> 0.12'
end

target 'SwiftUmbral' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  platform :osx, '10.11'
  use_frameworks!
  import_pods

  target 'SwiftUmbralTests' do
    inherit! :search_paths
    import_pods
    use_frameworks!
  end

end

target 'SwiftUmbral_iOS' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  platform :ios, '9.0'
  use_frameworks!
  import_pods

  target 'SwiftUmbral_iOSTests' do
    inherit! :search_paths
    import_pods
    use_frameworks!
  end

end
