# Building on macOS

These instructions are for performing a regular build of Mumble that will only run on systems that have the necessary libraries installed on them. For
building a static version, checkout [this file](build_static.md).

## Changelog (Recent macOS Build System Changes)

- **2025-11-17:** The default Xcode build on Apple Silicon (arm64) can produce a non-functional `mumble-server` executable. The build process has been updated to use "Unix Makefiles" to resolve this.
- **2025-11-17:** Added instructions for enabling Objective-C and Objective-C++ in `CMakeLists.txt` which is required for Makefile-based builds on macOS.
- **2025-11-17:** Added a section on configuring and running the server for the first time, including creating a data directory and setting the superuser password.
- **2025-11-17:** Submodules updated to newer commits:
    - `3rdparty/mach-override-src`
    - `3rdparty/rnnoise-src`
    - `3rdparty/soci`
- **2025-05-26:** Updated required Qt version from 5 to 6.

## Dependencies

On macOS, you can use [homebrew](https://brew.sh/) to install the needed packages. If you don't have it installed already, you can follow the
instruction on their official website to install homebrew itself.

Once homebrew is installed, you can run the following command to install all required packages:
```bash
brew update && brew install \
  cmake \
  pkg-config \
  qt6 \
  boost \
  libogg \
  libvorbis \
  flac \
  libsndfile \
  protobuf \
  openssl \
  poco \
  ice
```


## Running cmake

It is recommended to perform a so-called "out-of-source-build". In order to do so, navigate to the root of the Mumble directory and the issue the
following commands:

1.  **Enable Objective-C/C++:** Before running CMake, you must enable Objective-C and Objective-C++ language support for Makefile builds. Open the main `CMakeLists.txt` file in the root of the project and add `enable_language(OBJC OBJCXX)` right after the `project(...)` definition.

2.  **Create Build Directory:**
    ```bash
    mkdir build
    cd build
    ```

3.  **Run CMake with "Unix Makefiles":**
    ```bash
    cmake -G "Unix Makefiles" ..
    ```

This will cause cmake to create the necessary Makefiles for you. If you want to customize your build, you can pass special flags to cmake.
For all available build options, have a look [here](cmake_options.md).

E.g. if you only want to build the server, use `cmake -Dclient=OFF ..`.


## Building

Once cmake has been run, you can issue `make` from the build directory in order to actually start compiling the sources. If you want to
parallelize the build, use `make -j <jobs>` where `<jobs>` is the amount of parallel jobs to be run concurrently (e.g., `make -j8`).


## Running the Server

The compiled `mumble-server` executable requires a configuration file and a data directory.

1.  **Create a data directory:**
    ```bash
    mkdir -p ~/.mumble-server
    ```

2.  **Copy and modify the configuration:**
    ```bash
    cp ../auxiliary_files/mumble-server.ini ~/.mumble-server/
    sed -i '' 's,^database=.*,database=/Users/git/.mumble-server/mumble-server.sqlite,' ~/.mumble-server/mumble-server.ini
    sed -i '' 's,^logfile=.*,logfile=/Users/git/.mumble-server/mumble-server.log,' ~/.mumble-server/mumble-server.ini
    ```
    *(Note: Replace `/Users/git/` with your actual home directory path if it differs)*

3.  **Set the SuperUser password:**
    ```bash
    ./mumble-server -i ~/.mumble-server/mumble-server.ini --set-su-pw YOUR_PASSWORD
    ```
    *(Replace `YOUR_PASSWORD` with a strong password)*

4.  **Run the server:**
    ```bash
    ./mumble-server -i ~/.mumble-server/mumble-server.ini --foreground
    ```

## FAQ

See the general [build-FAQ](faq.md).


### CMake chooses Apple's SSL library

It can happen that cmake will find Apple's own SSL library that comes pre-installed on your system. This is usually incompatible with Mumble though
and you'll usually get errors about undefined OpenSSL symbols during link-time:
```
ld: symbol(s) not found
```

You can circumvent this problem by pointing cmake to the OpenSSL version you installed following the instructions from above. For how to do this,
please refer to [our build-FAQ](faq.md#cmake-selects-wrong-openssl-version).