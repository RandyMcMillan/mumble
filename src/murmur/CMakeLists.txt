# Copyright The Mumble Developers. All rights reserved.
# Use of this source code is governed by a BSD-style license
# that can be found in the LICENSE file at the root of the
# Mumble source tree or at <https://www.mumble.info/LICENSE>.

set(MURMUR_RC "${CMAKE_CURRENT_BINARY_DIR}/murmur.rc")
set(MURMUR_ICON "${CMAKE_SOURCE_DIR}/icons/murmur.ico")
set(MURMUR_PLIST "${CMAKE_CURRENT_BINARY_DIR}/murmur.plist")

configure_file("${CMAKE_CURRENT_SOURCE_DIR}/murmur.plist.in" "${MURMUR_PLIST}")
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/murmur.rc.in" "${MURMUR_RC}")



include(qt-utils)



find_pkg(Qt6 COMPONENTS Sql REQUIRED)

add_library(mumble_server_object_lib OBJECT
	"AudioReceiverBuffer.cpp"
	"AudioReceiverBuffer.h"
	"Cert.cpp"
	"LegacyPasswordHash.cpp"
	"Messages.cpp"
	"Meta.cpp"
	"Meta.h"
	"PBKDF2.cpp"
	"PBKDF2.h"
	"Register.cpp"
	"RPC.cpp"
	"Server.cpp"
	"Server.h"
	"ServerUser.cpp"
	"ServerUser.h"
	"Globals.cpp"
	"ServerApplication.cpp"
	"DBWrapper.cpp"

	"${SHARED_SOURCE_DIR}/ACL.cpp"
	"${SHARED_SOURCE_DIR}/ACL.h"
	"${SHARED_SOURCE_DIR}/Channel.cpp"
	"${SHARED_SOURCE_DIR}/Channel.h"
	"${SHARED_SOURCE_DIR}/ChannelListenerManager.cpp"
	"${SHARED_SOURCE_DIR}/ChannelListenerManager.h"
	"${SHARED_SOURCE_DIR}/Connection.cpp"
	"${SHARED_SOURCE_DIR}/Connection.h"
	"${SHARED_SOURCE_DIR}/Group.cpp"
	"${SHARED_SOURCE_DIR}/Group.h"
	"${SHARED_SOURCE_DIR}/User.cpp"
	"${SHARED_SOURCE_DIR}/User.h"
)

if(WIN32)
	add_executable(mumble-server WIN32 "main.cpp")
else()
	add_executable(mumble-server "main.cpp")
endif()

find_package(Ice REQUIRED)

target_link_libraries(mumble-server PUBLIC mumble_server_object_lib CLI11::CLI11 Ice::Ice)

target_include_directories(mumble_server_object_lib
	PUBLIC
		${CMAKE_CURRENT_SOURCE_DIR}
		${SHARED_SOURCE_DIR}
)



if (SOCI_MYSQL)
    target_link_libraries(mumble-server PUBLIC ${CMAKE_BINARY_DIR}/lib/libsoci_mysql.dylib)
endif()

set_property(TARGET mumble-server PROPERTY INTERPROCEDURAL_OPTIMIZATION ${lto})
set_property(TARGET mumble_server_object_lib PROPERTY INTERPROCEDURAL_OPTIMIZATION ${lto})

set_target_properties(mumble_server_object_lib
	PROPERTIES
		AUTOMOC ON
)

set_target_properties(mumble-server
	PROPERTIES
		AUTOMOC ON
		RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)

set(AUTOGEN_BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}/murmur_autogen")
message(STATUS "File: ${AUTOGEN_BUILD_DIR}")
set_source_files_properties("${AUTOGEN_BUILD_DIR}/mocs_compilation.cpp" PROPERTIES COMPILE_FLAGS "-w")

target_compile_definitions(mumble_server_object_lib
	PUBLIC
		"MURMUR"
		"QT_RESTRICTED_CAST_FROM_ASCII"
)

target_include_directories(mumble_server_object_lib
	PUBLIC
		${CMAKE_CURRENT_SOURCE_DIR}
		${SHARED_SOURCE_DIR}
)
target_link_libraries(mumble_server_object_lib
	PUBLIC
		shared
		spdlog::spdlog
		soci_core
		soci_mysql
		soci_postgresql
		soci_sqlite3
		Ice::Ice
)

if(static)
	# MariaDB and MySQL
	if(TARGET Qt6::QMYSQLDriverPlugin)
		include_qt_plugin(mumble_server_object_lib PRIVATE "QMYSQLDriverPlugin")
		target_link_libraries(mumble_server_object_lib PRIVATE Qt6::QMYSQLDriverPlugin)
	endif()
	# Open DataBase Connectivity
	if(TARGET Qt6::QODBCDriverPlugin)
		include_qt_plugin(mumble_server_object_lib PRIVATE "QODBCDriverPlugin")
		target_link_libraries(mumble_server_object_lib PRIVATE Qt6::QODBCDriverPlugin)
		if(WIN32)
			find_library(LIB_ODBC32 "odbc32")
			target_link_libraries(mumble_server_object_lib PRIVATE ${LIB_ODBC32})
		endif()
	endif()
	# PostgreSQL
	if(TARGET Qt6::QPSQLDriverPlugin)
		include_qt_plugin(mumble_server_object_lib PRIVATE "QPSQLDriverPlugin")
		target_link_libraries(mumble_server_object_lib PRIVATE Qt6::QPSQLDriverPlugin)
	endif()
	# SQLite
	if(TARGET Qt6::QSQLiteDriverPlugin)
		include_qt_plugin(mumble_server_object_lib PRIVATE "QSQLiteDriverPlugin")
		target_link_libraries(mumble_server_object_lib PRIVATE Qt6::QSQLiteDriverPlugin)
	endif()
endif()

if(WIN32)
	target_sources(mumble_server_object_lib
		PRIVATE
			"About.cpp"
			"About.h"
			"Tray.cpp"
			"Tray.h"
			"murmur.qrc"

			"${CMAKE_SOURCE_DIR}/auxiliary_files/mumble.appcompat.manifest"
			"${MURMUR_RC}"
	)

	set_target_properties(mumble_server_object_lib
		PROPERTIES
			AUTORCC ON
	)

	find_pkg(Qt6 COMPONENTS Widgets REQUIRED)

	target_link_libraries(mumble_server_object_lib
		PUBLIC
			Qt6::Widgets
			dbghelp.lib
			shlwapi.lib
			rpcrt4.lib
	)

	if(static AND TARGET Qt6::QWindowsIntegrationPlugin)
		include_qt_plugin(mumble_server_object_lib PRIVATE QWindowsIntegrationPlugin)
		target_link_libraries(mumble_server_object_lib PRIVATE Qt6::QWindowsIntegrationPlugin)
	endif()
else()
	target_sources(mumble_server_object_lib
		PRIVATE
			"UnixMurmur.cpp"
			"UnixMurmur.h"
	)

	if(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
		find_library(CAP_LIBRARY NAMES cap)
		target_link_libraries(mumble_server_object_lib PUBLIC ${CAP_LIBRARY})
	endif()
endif()

if(zeroconf)
	if(NOT APPLE)
		find_pkg(avahi-compat-libdns_sd QUIET)
		if(avahi-compat-libdns_sd_FOUND)
			target_include_directories(mumble_server_object_lib PUBLIC ${avahi-compat-libdns_sd_INCLUDE_DIRS})
			target_link_libraries(mumble_server_object_lib PUBLIC ${avahi-compat-libdns_sd_LIBRARIES})
		else()
			find_library(LIB_DNSSD "dnssd")
			if(${LIB_DNSSD} STREQUAL "LIB_DNSSD-NOTFOUND")
				message(FATAL_ERROR "DNS-SD library not found!")
			endif()
			target_link_libraries(mumble_server_object_lib PUBLIC ${LIB_DNSSD})
		endif()
	endif()

	target_compile_definitions(mumble_server_object_lib PUBLIC "USE_ZEROCONF")

	target_include_directories(mumble_server_object_lib PUBLIC "${3RDPARTY_DIR}/qqbonjour")

	target_sources(mumble_server_object_lib
		PRIVATE
			"Zeroconf.cpp"
			"Zeroconf.h"
			# Unlike what the name implies, this 3rdparty helper is not actually related to Bonjour.
			# It just uses the API provided by mDNSResponder, making it compatible with Avahi too.
			"${3RDPARTY_DIR}/qqbonjour/BonjourRecord.h"
			"${3RDPARTY_DIR}/qqbonjour/BonjourServiceRegister.cpp"
			"${3RDPARTY_DIR}/qqbonjour/BonjourServiceRegister.h"
	)
endif()



install(TARGETS mumble-server RUNTIME DESTINATION "${MUMBLE_INSTALL_EXECUTABLEDIR}" COMPONENT mumble_server)

if(packaging)
	if(WIN32)
		if(translations)
			list(APPEND installer_vars "--all-languages")
		endif()

		list(APPEND installer_vars
			"--version" ${PROJECT_VERSION}
			"--arch" ${MUMBLE_TARGET_ARCH}
			"--vc-redist-required" "${VC_REDIST_VERSION}"
		)

		if(skip-msi-rebuild)
			list(APPEND installer_vars
				"--skip-msi-rebuild"
			)
		endif()

		file(COPY
			${CMAKE_SOURCE_DIR}/installer/MumbleInstall.cs
			${CMAKE_SOURCE_DIR}/installer/ServerInstaller.cs
			DESTINATION
				${CMAKE_BINARY_DIR}/installer/server
		)

		add_custom_command(TARGET mumble-server
			POST_BUILD
			COMMAND cscs.exe -cd MumbleInstall.cs 
			COMMAND cscs.exe ServerInstaller.cs ${installer_vars}
			WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/installer/server
		)
	endif()
endif()


# Compile and link against database implementation
add_subdirectory(database)

target_link_libraries(mumble_server_object_lib PUBLIC mumble_server_database)
