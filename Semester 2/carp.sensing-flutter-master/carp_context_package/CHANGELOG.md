## 0.5.0 BREAKING
* Upgraded to use [`carp_mobile_sensing`](https://pub.dartlang.org/packages/carp_mobile_sensing) version 0.5.0 
   * **Breaking change.** This version has been migrated from the deprecated Android Support Library to *AndroidX*. 
This should not result in any functional changes, but it requires any Android app using this plugin to also 
[migrate](https://developer.android.com/jetpack/androidx/migrate) if using the original support library. 
   * See Flutter [AndroidX compatibility](https://flutter.dev/docs/development/packages-and-plugins/androidx-compatibility)

## 0.3.6
* small update to domain model

## 0.3.5
* update to json_serialization v.2
* added support for `geofence` measure

## 0.3.4
* update to `carp_mobile_sensing` version 0.3.10

## 0.3.3
* Documentation

## 0.3.2
* Update to `carp_mobile_sensing` v. 0.3.7
* Using the data types in the package (`activity`, `weather`, `location`)

## 0.3.1
* Documentation

## 0.3.0
* Initial release compatible with `carp_mobile_sensing` version `0.3.*`
