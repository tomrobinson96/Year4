# carp_movisens_package

carp_movisens_package

## Getting Started

This project is a starting point for a Dart
[package](https://flutter.io/developing-packages/),
a library module containing code that can be shared easily across
multiple Flutter or Dart projects.

For help getting started with Flutter, view our 
[online documentation](https://flutter.io/docs), which offers tutorials, 
samples, guidance on mobile development, and a full API reference.


* `Movisens ECG device`

See the [wiki]() for further documentation, particularly on available [measure types](https://github.com/cph-cachet/carp.sensing-flutter/wiki/A.-Measure-Types)
and [sampling schemas](https://github.com/cph-cachet/carp.sensing-flutter/wiki/D.-Sampling-Schemas).


For Flutter plugins for other CARP products, see [CARP Mobile Sensing in Flutter](https://github.com/cph-cachet/carp.sensing-flutter/blob/master/README.md).

If you're interested in writing you own sampling packages for CARP, see the description on
how to [extend](https://github.com/cph-cachet/carp.sensing-flutter/wiki/4.-Extending-CARP-Mobile-Sensing) CARP on the wiki.

## Installing

To use this package, add the following to you `pubspc.yaml` file. Note that
this package only works together with `carp_mobile_sensing`.

`````dart
dependencies:
  flutter:
    sdk: flutter
  carp_mobile_sensing: ^0.5.0
  carp_movisens_package: ^0.0.1
  ...
`````

### Android Integration

Add the following to your app's `manifest.xml` file located in `android/app/src/main`:

````xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="<your_package_name>"
    xmlns:tools="http://schemas.android.com/tools">

   ...
   
   <!-- The following permissions are used for CARP Mobile Sensing -->
   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
   <uses-permission android:name="android.permission.PACKAGE_USAGE_STATS" tools:ignore="ProtectedPermissions"/>
   
   <!--   The following are used for Movisens package  -->
   
   
        <uses-permission android:name="android.permission.INTERNET"/>
        <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
        <uses-permission android:name="android.permission.BLUETOOTH" />
        <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
        <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
        <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    
        <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
        <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
        
     <!--   The following are activity specific to  movisens native Android library  that talks to flutter over platform channel   -->
     
     
     <activity
                     android:name="de.kn.uni.smartact.movisenslibrary.screens.view.Activity_BluetoothUser"
                     android:configChanges="orientation|keyboardHidden|keyboard"
                     android:exported="true"
                     android:label="@string/app_name"
                     android:launchMode="singleTop"
                     android:screenOrientation="portrait">
                 <meta-data
                         android:name="android.support.PARENT_ACTIVITY"
                         android:value="de.kn.uni.smartact.movisenslibrary.screens.view.Activity_BluetoothStart" />
             </activity>
     
             <activity
                     android:name="de.kn.uni.smartact.movisenslibrary.screens.view.Activity_BluetoothDeviceScan"
                     android:configChanges="orientation|keyboardHidden|keyboard"
                     android:exported="true"
                     android:label="@string/app_name"
                     android:launchMode="singleTop"
                     android:screenOrientation="portrait">
                 <meta-data
                         android:name="android.support.PARENT_ACTIVITY"
                         android:value="de.kn.uni.smartact.movisenslibrary.screens.view.Activity_BluetoothStart" />
             </activity>
     
             <activity
                     android:name="de.kn.uni.smartact.movisenslibrary.screens.NoMeasurmentDialog"
                     android:configChanges="orientation|keyboardHidden|keyboard"
                     android:theme="@style/Theme.AppCompat.Light"
                     android:exported="true"
                     android:label="@string/app_name"
                     android:launchMode="singleTop"
                     android:screenOrientation="portrait">
                 <meta-data
                         android:name="android.support.PARENT_ACTIVITY"
                         android:value="de.kn.uni.smartact.movisenslibrary.screens.view.Activity_BluetoothStart" />
             </activity>
     
             <activity
                     android:name="de.kn.uni.smartact.movisenslibrary.screens.view.Activity_BluetoothData"
                     android:configChanges="orientation|keyboardHidden|keyboard"
                     android:exported="true"
                     android:label="@string/app_name"
                     android:launchMode="singleTop"
                     android:screenOrientation="portrait">
                 <meta-data
                         android:name="android.support.PARENT_ACTIVITY"
                         android:value="de.kn.uni.smartact.movisenslibrary.screens.view.Activity_BluetoothStart" />
             </activity>
     
             <activity
                     android:name="de.kn.uni.smartact.movisenslibrary.screens.view.Activity_BluetoothStart"
                     android:configChanges="orientation|keyboardHidden|keyboard"
                     android:exported="true"
                     android:label="@string/app_name"
                     android:launchMode="singleTop"
                     android:screenOrientation="portrait">
             </activity>
     
             <service android:name="de.kn.uni.smartact.movisenslibrary.bluetooth.MovisensService" />
     
             <receiver android:name="de.kn.uni.smartact.movisenslibrary.reboot.RebootReceiver">
                 <intent-filter>
                     <action android:name="android.intent.action.BOOT_COMPLETED" />
                 </intent-filter>
             </receiver>
     
     
        
        
        
   

</manifest>
````

Note that version 0.5.0 is migrated to AndroidX. This shouldn't result in any functional changes, but it requires any Android apps using this plugin to also 
[migrate](https://developer.android.com/jetpack/androidx/migrate) if they're using the original support library. 
See Flutter [AndroidX compatibility](https://flutter.dev/docs/development/packages-and-plugins/androidx-compatibility)



### iOS Integration

iOS is not supported 

`

## Using it

To use this package, import it into your app together with the
[`carp_mobile_sensing`](https://pub.dartlang.org/packages/carp_mobile_sensing) package:

`````dart
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:movisens_package/movisens.dart';
`````

Before creating a study and running it, register this package in the 
[SamplingPackageRegistry](https://pub.dartlang.org/documentation/carp_mobile_sensing/latest/runtime/SamplingPackageRegistry.html).

`````dart
 SamplingPackageRegistry.register(MovisensSamplingPackage());
`````


