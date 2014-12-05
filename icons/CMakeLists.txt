# icons
install(FILES hicolor/16x16/apps/external-storage-manager.svg DESTINATION share/icons/hicolor/16x16/apps)
install(FILES hicolor/22x22/apps/external-storage-manager.svg DESTINATION share/icons/hicolor/22x22/apps)
install(FILES hicolor/24x24/apps/external-storage-manager.svg DESTINATION share/icons/hicolor/24x24/apps)
install(FILES hicolor/scalable/apps/external-storage-manager.svg DESTINATION share/icons/hicolor/scalable/apps)


# Update icon cache
option (ICON_UPDATE "Run gtk-update-icon-cache after the install." ON)
if (ICON_UPDATE)
  install (CODE "message(\"-- Updating icon cache...\")")
  install (CODE "execute_process(COMMAND gtk-update-icon-cache -f -t ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor)")
endif ()
