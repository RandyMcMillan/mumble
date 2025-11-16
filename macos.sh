## 🚀 OPTIMIZED SCRIPT FOR MUMBLE BUILD ON MACOS (HOMEBREW) ##

# --- 1. RESOLVE HOMEBREW TAP CONFLICTS & INSTALL DEPENDENCIES ---

echo "--- 1. Resolving Homebrew Tap Conflict (ice) ---"
# Uninstall existing conflicting Ice formula
brew uninstall ice

echo "--- 2. Installing Ice and MySQL Client Libraries ---"
# Install the standard Ice formula
brew install ice
# Install the MySQL client library and headers
brew install mysql-client


# --- 2. GET PATHS AND SET ENVIRONMENT VARIABLES ---

# Get the Homebrew installation prefix for the 'ice' package
ICE_PREFIX=$(brew --prefix ice)
if [ -z "$ICE_PREFIX" ]; then
    echo "ERROR: Could not determine Homebrew prefix for 'ice'. Aborting."
    exit 1
fi

ICE_CMAKE_DIR="${ICE_PREFIX}/share/Ice/cmake"
ICE_SLICE_DIR="${ICE_PREFIX}/share/Ice/slice"
echo "Ice_DIR set to: ${ICE_CMAKE_DIR}"
echo "Ice_SLICE_DIR set to: ${ICE_SLICE_DIR}"

# Set ICE_HOME environment variable
export ICE_HOME="${ICE_PREFIX}"
echo "ICE_HOME set to: ${ICE_HOME}"

# Set CMAKE_PREFIX_PATH for Homebrew
export CMAKE_PREFIX_PATH="/opt/homebrew"
echo "CMAKE_PREFIX_PATH set to: ${CMAKE_PREFIX_PATH}"


# Get the installation prefix for MySQL client
MYSQL_PREFIX=$(brew --prefix mysql-client)
if [ -z "$MYSQL_PREFIX" ]; then
    echo "ERROR: Could not determine Homebrew prefix for 'mysql-client'. Aborting."
    exit 1
fi
echo "MySQL client prefix found at: $MYSQL_PREFIX"


# --- 3. EXECUTE OUT-OF-SOURCE BUILD ---

# Define the source directory (current directory)
SOURCE_DIR=$(pwd)
BUILD_DIR="${SOURCE_DIR}/build"

echo "--- 3. Creating and Entering Build Directory ---"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

echo "--- 4. Running Combined CMake Configuration ---"

# The source directory argument is now '..' (the parent directory)
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    # ICE Path Hints
    -DIce_DIR="${ICE_CMAKE_DIR}" \
    -DIce_SLICE_DIR="${ICE_SLICE_DIR}" \
    -DIce_ADD_SLICE_COMPILER=ON \
    -DICE_INCLUDE_DIR="${ICE_PREFIX}/include" \
    -DICE_LIBRARY="${ICE_PREFIX}/lib" \
    -DICE_UTIL_LIBRARY="${ICE_PREFIX}/lib/libIceUtil.dylib" \
    -DICE_SSL_LIBRARY="${ICE_PREFIX}/lib/libIceSSL.dylib" \
    -DICE_ICE_LIBRARY="${ICE_PREFIX}/lib/libIce.dylib" \
    \
    # MySQL Path Hints (to resolve missing MySQL errors)
    -DMYSQL_INCLUDE_DIR="${MYSQL_PREFIX}/include" \
    -DMYSQL_LIBRARY="${MYSQL_PREFIX}/lib/libmysqlclient.dylib" \
    \
    # Tell CMake where the Mumble source code is (one level up)
    ..

echo "--- CMake Configuration Complete ---"

# 5. Compile the project
echo "--- 5. Starting Build (make) ---"
make -j$(sysctl -n hw.ncpu)

# --- END OF SCRIPT ---
