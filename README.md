
# How to build a custom opencv 3.4.0 for Android

OpenCV is an awesome library with an enumerous built-in modules which support us a lot in image processing. But sometimes, we don't need to import all of these modules to archive what we want. This could make the application size is pretty big. We just need some very specific modules such as `core lib` and `imgproc`. And in this tutorial, I'm gonna show you how to custom the opencv build for Android step-by-step.

## Environments

- [Docker latest](https://docs.docker.com/get-docker/)


## Setup Build Environment Steps
**Step 1**. Clone the repository and build the opencv_env image.

```
cd ~
git clone git@github.com:hzung/custom-build-opencv-android.git
cd ~/custom-build-opencv-android
docker image build -t hungtv/opencv_env:v01 .
```

**Step 2**. Clone opencv into `custom-build-opencv-android/opencv` and check out to the version `3.4.1`.

```
cd ~/custom-build-opencv-android && git clone git@github.com:opencv/opencv.git
cd ~/custom-build-opencv-android/opencv && git checkout 3.4.0
```

**Step 3**. Download and unzip [android-ndk-r14b](https://dl.google.com/android/repository/android-ndk-r14b-linux-x86_64.zip) into `custom-build-opencv-android/android-ndk-r14b`
After unzipping the android-ndk-r14b, 

**3.1.** Open the file `~/custom-build-opencv-android/android-ndk-r14b/build/tools/make_standalone_toolchain.py`

**3.2.** Goto the line 402 and edit the line to fix the issue for creating the toolchain for the chip `x86` and `x86_64`.

```
assert len(dirs) == 1
```

to 

```
assert len(dirs) >= 1
```

**Step 4**. Download and unzip [android-sdk-linux](https://dl.google.com/android/android-sdk_r24.4.1-linux.tgz) into `custom-build-opencv-android/android-sdk-linux`


**Step 5**. Start the container using the image `opencv_env:v01`

```
cd ~/custom-build-opencv-android
docker container run \
-v $(pwd)/android-sdk-linux:/android-sdk-linux \
-v $(pwd)/android-ndk-r14b:/android-ndk-r14b \
-v $(pwd)/opencv:/opencv \
-v $(pwd)/toolchains:/toolchains \
-v $(pwd)/builds:/builds \
--name opencv_env \
-td hungtv/opencv_env:v01
```

**Step 6**. Install `platform-tools,build-tools-23.0.3,android-25`

```
docker exec -it opencv_env /bin/bash
android update sdk --licenses --no-ui --all --filter platform-tools,build-tools-23.0.3,android-25
```
**Note:** You can list for other packages using this command: `android list sdk --all --extended`

Here is the result directory structure. Make sure that the structure is correct.

```
├── Dockerfile
├── README.md
├── android-ndk-r14b
│   ├── CHANGELOG.md
│   ├── build
│   ├── ndk-build
│   ├── ndk-depends
│   ├── ...
├── android-sdk-linux
│   ├── add-ons
│   ├── build-tools
│   ├── ...
├── builds
├── env_var_setup
├── opencv
│   ├── 3rdparty
│   ├── CMakeLists.txt
│   ├── CONTRIBUTING.md
│   ├── ...
└── toolchains
```

## Build Steps For armeabi-v7a/arm64-v8a

**Step 1**. Access to the `bash` shell of the `opencv_env` container and export one of the environment variables.

* arm

```
docker exec -it opencv_env /bin/bash
export ANDROID_STANDALONE_TOOLCHAIN=/toolchains/arm-toolchain
export TOOLCHAIN_ARCH=arm
export BUILD_OUTPUT_ARCH=armeabi-v7a
export BUILD_OUTPUT_DIR=/builds/${BUILD_OUTPUT_ARCH}
```

* arm64

```
docker exec -it opencv_env /bin/bash
export ANDROID_STANDALONE_TOOLCHAIN=/toolchains/arm64-toolchain
export TOOLCHAIN_ARCH=arm64
export BUILD_OUTPUT_ARCH=arm64-v8a
export BUILD_OUTPUT_DIR=/builds/${BUILD_OUTPUT_ARCH}
```

* x86

```
docker exec -it opencv_env /bin/bash
export ANDROID_STANDALONE_TOOLCHAIN=/toolchains/x86-toolchain
export TOOLCHAIN_ARCH=x86
export BUILD_OUTPUT_ARCH=x86
export BUILD_OUTPUT_DIR=/builds/${BUILD_OUTPUT_ARCH}
```

* x86_64

```
docker exec -it opencv_env /bin/bash
export ANDROID_STANDALONE_TOOLCHAIN=/toolchains/x86_64-toolchain
export TOOLCHAIN_ARCH=x86_64
export BUILD_OUTPUT_ARCH=x86_64
export BUILD_OUTPUT_DIR=/builds/${BUILD_OUTPUT_ARCH}
```

**Step 2**. Create the toolchain.

```
/android-ndk-r14b/build/tools/make_standalone_toolchain.py --arch ${TOOLCHAIN_ARCH} --api 23 --install-dir ${ANDROID_STANDALONE_TOOLCHAIN}
```

**Extra step** for `x86_64` only.

```
cp ${ANDROID_STANDALONE_TOOLCHAIN}/x86_64-linux-android/lib64/{*++.a,libgnustl_shared.so} ${ANDROID_STANDALONE_TOOLCHAIN}/x86_64-linux-android/lib/
```


**Step 4**. Create a build directory for arm64-v8

```
mkdir ${BUILD_OUTPUT_DIR}
```

**Step 5**. Start configurations for compiling.

```
cd ${BUILD_OUTPUT_DIR}
cmake \
  -DCMAKE_TOOLCHAIN_FILE=/opencv/platforms/android/android.toolchain.cmake \
  -DWITH_CAROTENE=OFF \
  -DANDROID_STL=gnustl_static \
  -DANDROID_NATIVE_API_LEVEL=23 \
  -DWITH_OPENCL=OFF \
  -DWITH_CUDA=OFF \
  -DWITH_IPP=OFF \
  -DBUILD_EXAMPLES=OFF \
  -DBUILD_TESTS=OFF \
  -DBUILD_PERF_TESTS=OFF \
  -DBUILD_ANDROID_EXAMPLES=OFF \
  -DINSTALL_ANDROID_EXAMPLES=OFF \
  -DANDROID_ABI=${BUILD_OUTPUT_ARCH} \
  -DWITH_TBB=ON \
  -DWITH_ITT=OFF \
  /opencv
```

Wait until the configuration steps is completed.
Using a text editor to open the file `${BUILD_OUTPUT_DIR}/modules/java/CMakeFiles/opencv_java.dir/cmake_clean.cmake` and remove these lines.

```
"CMakeFiles/opencv_java.dir/generator/src/cpp/Mat.cpp.o"
"CMakeFiles/opencv_java.dir/generator/src/cpp/converters.cpp.o"
"CMakeFiles/opencv_java.dir/generator/src/cpp/jni_part.cpp.o"
"CMakeFiles/opencv_java.dir/generator/src/cpp/listconverters.cpp.o"
"CMakeFiles/opencv_java.dir/generator/src/cpp/utils.cpp.o"
"CMakeFiles/opencv_java.dir/__/core/misc/java/src/cpp/core_manual.cpp.o"
"CMakeFiles/opencv_java.dir/__/dnn/misc/java/src/cpp/dnn_converters.cpp.o"
"CMakeFiles/opencv_java.dir/__/features2d/misc/java/src/cpp/features2d_converters.cpp.o"
"CMakeFiles/opencv_java.dir/gen/core.cpp.o"
"CMakeFiles/opencv_java.dir/gen/imgproc.cpp.o"
"CMakeFiles/opencv_java.dir/gen/ml.cpp.o"
"CMakeFiles/opencv_java.dir/gen/objdetect.cpp.o"
"CMakeFiles/opencv_java.dir/gen/photo.cpp.o"
"CMakeFiles/opencv_java.dir/gen/video.cpp.o"
"CMakeFiles/opencv_java.dir/gen/dnn.cpp.o"
"CMakeFiles/opencv_java.dir/gen/imgcodecs.cpp.o"
"CMakeFiles/opencv_java.dir/gen/videoio.cpp.o"
"CMakeFiles/opencv_java.dir/gen/features2d.cpp.o"
"CMakeFiles/opencv_java.dir/gen/calib3d.cpp.o"
```

This configuration prevent the compiling process removing these files. We're gonna need these files when linking library (**step 9**).

**Step 6**. Start compiling with 4 compiling jobs. Pick the greater number for faster compiling if your computer is trong.

```
cd ${BUILD_OUTPUT_DIR} && make -j 4
```

After this step, you can import the `libopencv_java3.so` into the Android project. It should work fine. But this is not what we want. We want to make the size of `libopencv_java3.so` smaller. The current size is pretty big for us.

**Step 7**. Let's custom the build contains only `libopencv_core.a` and `libopencv_imgproc.a`.

```
cd ${BUILD_OUTPUT_DIR}/lib/${BUILD_OUTPUT_ARCH}
${ANDROID_STANDALONE_TOOLCHAIN}/bin/*android*-g++ \
-shared -o libopencv_output.so \
--sysroot=${ANDROID_STANDALONE_TOOLCHAIN}/sysroot/ \
-Wl,--whole-archive \
libopencv_core.a \
libopencv_imgproc.a \
-Wl,--no-whole-archive
```

**Step 8**. Use this command to stripe the output library for smaller size.

```
${ANDROID_STANDALONE_TOOLCHAIN}/bin/*android*strip --strip-unneeded libopencv_output.so
```

**Step 9**. Linking other dependencies of the library. After this step, the build's output is ready for using.

```
cd ${BUILD_OUTPUT_DIR}/lib/${BUILD_OUTPUT_ARCH}
${ANDROID_STANDALONE_TOOLCHAIN}/bin/*android*-g++ \
-L ${BUILD_OUTPUT_DIR}/3rdparty/lib/${BUILD_OUTPUT_ARCH} \
-ldl \
-lm \
-llog \
-ljnigraphics \
-lz \
-lcpufeatures \
-fexceptions \
-frtti \
-fsigned-char \
-shared -Wl,-soname,libopencv_output.so \
-o libopencv_output.so \
../../modules/java/CMakeFiles/opencv_java.dir/generator/src/cpp/Mat.cpp.o \
../../modules/java/CMakeFiles/opencv_java.dir/generator/src/cpp/converters.cpp.o \
../../modules/java/CMakeFiles/opencv_java.dir/generator/src/cpp/jni_part.cpp.o \
../../modules/java/CMakeFiles/opencv_java.dir/generator/src/cpp/listconverters.cpp.o \
../../modules/java/CMakeFiles/opencv_java.dir/generator/src/cpp/utils.cpp.o \
../../modules/java/CMakeFiles/opencv_java.dir/__/core/misc/java/src/cpp/core_manual.cpp.o \
../../modules/java/CMakeFiles/opencv_java.dir/__/dnn/misc/java/src/cpp/dnn_converters.cpp.o \
../../modules/java/CMakeFiles/opencv_java.dir/__/features2d/misc/java/src/cpp/features2d_converters.cpp.o \
../../3rdparty/cpufeatures/CMakeFiles/libcpufeatures.dir/cpu-features.c.o \
../../modules/java/CMakeFiles/opencv_java.dir/gen/core.cpp.o \
../../modules/java/CMakeFiles/opencv_java.dir/gen/imgproc.cpp.o \
--sysroot=${ANDROID_STANDALONE_TOOLCHAIN}/sysroot \
-Wl,--whole-archive \
libopencv_core.a \
libopencv_imgproc.a \
-Wl,--no-whole-archive
```

**Step 10**. After the above step, the size of `libopencv_output.so` is increased a little bit. In this final step, let's stripe the file `libopencv_output.so` for smaller size. 

```
${ANDROID_STANDALONE_TOOLCHAIN}/bin/*android*strip --strip-unneeded libopencv_output.so
```

We're ready to intergrate this file `${BUILD_OUTPUT_DIR}/lib/${BUILD_OUTPUT_ARCH}/libopencv_output.so` the Android project now.

In Java, loading library by the code:

```
System.loadLibrary("opencv_output");
```

Done!



