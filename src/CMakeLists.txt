vala_precompile(VALA_C
    config.vala

    ExternalStorageManager.vala

    Core/Device.vala

    Widgets/DeviceMenuItem.vala

PACKAGES
    glib-2.0
    gtk+-3.0
    appindicator3-0.1
    libnotify
    granite
    ${ADD_PKG}
OPTIONS
    --target-glib=2.32
    --thread
    ${ADD_OPTIONS}
GENERATE_VAPI
    external-storage-manager
GENERATE_HEADER
    external-storage-manager
)

add_definitions(${DEPS_CFLAGS})
link_directories(${DEPS_LIBRARY_DIRS})
add_executable(external-storage-manager ${VALA_C})
target_link_libraries (external-storage-manager ${DEPS_LIBRARIES})
install (TARGETS external-storage-manager RUNTIME DESTINATION bin)
