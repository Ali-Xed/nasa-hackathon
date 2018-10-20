platform :ios, '9.0'

# ignore all warnings from all pods
inhibit_all_warnings!

use_frameworks!

def nearbyweather_pods
    pod 'PKHUD', '~> 5.0'
    pod 'RainyRefreshControl', '~> 0.4'
    pod 'TextFieldCounter', :git => 'https://github.com/serralvo/TextFieldCounter.git', :branch => 'master', :commit => '4a746ad'
    pod 'Alamofire', '~> 4.6'
    pod 'APTimeZones', :git => 'https://github.com/Alterplay/APTimeZones.git', :branch => 'master', :commit => '9ffd147'
    pod 'FMDB', '~> 2.6'
    pod 'R.swift', '~> 4.0.0'
end

target 'NearbyWeather' do
    nearbyweather_pods
end  

target 'NearbyWeatherTests' do
  nearbyweather_pods
end
