# Premake5 module to generate Android NDK makefiles

This module provides two new actions:

* `ndk-makefile`

	Generate `Android.mk` and `Application.mk` makefiles from a Premake solution/project description. 
	Run `ndk-build` in a generated project directory to build the necessary shared or static libraries.


* `ndk-manifest`

	_(Experimental)_ Generate `AndroidManifest.xml` and Java glue code. The glue code generation assumes you'll 
	be extending an existing Java class, and places a trivial class in the correct output directory for the 
	application's package name. Java source files in the project are copied into the build directory as well,
	so that ant can see them. The manifest generated is simple, but is suitable for e.g. porting games using
	libraries such as SDL2. For more advanced use it would be better to create your own manifest and JNI wrappers.
	
Some Premake configuration options are mapped to suitable NDK options. E.g. `optimize` is mapped to `APP_OPTIM`. 
New configuration options are also available:

* `apilevel`: An integer which specifies the Android API level to target.

* `abis`: A list of strings specifying one or more ABIs to generate code for.

* `stl`: A string specifying the STL support desired. Defaults to `system`, i.e. minimal C runtime with no STL support.

* `packagename`: For `ndk-manifest` only, a string specifiying the package name to use. E.g. `com.mycompany.myapp`

* `basepackagename`: For `ndk-manifest` only, a string specifying the package containing the Activity class to extend.

* `activityname`: For `ndk-manifest` only, a string specifiying the name of your application's activity.

* `baseactivityname`: For `ndk-manifest` only, a string specifying the name of the activity you're extending.

* `packageversion`: For `ndk-manifest` only, an integer specifying the package's revision number.

Notes: 

* To install the module, copy `modules\ndk` to the directory containing your Premake5 binary, or in a suitable `.premake` directory. 
Then add `require 'ndk'` to your Premake script to use it.

* Projects using premake-ndk should use the `android` platform to specify Android-specific options.

* Unlike (for example) Visual Studio projects, the generated makefiles do not support multiple configurations. Instead they are placed under one directory per configuration below the project's location.

* Nothing is generated to represent solutions. The NDK build system is app-centric, so makefiles are generated for 
windowed application projects and static or shared libraries. The NDK generates all objects and binaries per-app,
so you would generally only run `ndk-build` or other build commands in the application directory.

* You will need to run `android update project` in the application directory after generating the manifest before you
can build the application APK with `ant`.

* This module is very much a work-in-progress. Comments welcome!
