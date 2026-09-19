#!/bin/bash
# Removes the parts of the PySide6 wheel that the application never loads.
# The wheel ships a complete Qt, so most of it is dead weight here.
#
# The two lists of file names below belong together. Qt loads its platform
# plugins at run time, so a plugin that survives here needs its libraries to
# survive as well. Always rebuild and start the application after changing
# either list.
set -eu

APP="${FLATPAK_DEST:-/app}"
SITE_PACKAGES="${APP}"/lib/python3.*/site-packages
PYSIDE=${SITE_PACKAGES}/PySide6

# Qt developer tools. None of them run inside the application.
for tool in assistant designer linguist lrelease lupdate qmlformat qmllint qmlls; do
    rm -rf ${PYSIDE}/"${tool}"
done

# Headers, glue code, documentation and CMake files serve people who build
# C++ bindings. They have no purpose at run time.
rm -rf ${PYSIDE}/include ${PYSIDE}/typesystems ${PYSIDE}/glue ${PYSIDE}/doc
rm -rf ${SITE_PACKAGES}/shiboken6/include
rm -f ${PYSIDE}/*.cmake

# Type stubs serve editors, not the running program.
rm -f ${PYSIDE}/*.pyi ${SITE_PACKAGES}/shiboken6/*.pyi

# The application imports QtCore, QtGui, QtSvg and QtWidgets.
find ${PYSIDE} -maxdepth 1 -name 'Qt*.abi3.so' \
    ! -name 'QtCore.*' ! -name 'QtGui.*' ! -name 'QtSvg.*' ! -name 'QtWidgets.*' -delete

# The interface is built from widgets, no QML is involved anywhere.
rm -f ${PYSIDE}/libpyside6qml.abi3.so*
rm -rf ${PYSIDE}/Qt/qml

# Plugin groups for subsystems the application never touches. The server side
# of Wayland belongs to a compositor, the application is only a client.
for group in designer qmllint qmltooling sqldrivers networkinformation \
             printsupport egldeviceintegrations tls vectorimageformats \
             wayland-graphics-integration-server; do
    rm -rf ${PYSIDE}/Qt/plugins/"${group}"
done

# Only Wayland and X11 are reachable through the sandbox permissions.
find ${PYSIDE}/Qt/plugins/platforms -type f \
    ! -name 'libqwayland.so' ! -name 'libqxcb.so' -delete

# PDF is not an image format the application displays.
rm -f ${PYSIDE}/Qt/plugins/imageformats/libqpdf.so

# The on-screen keyboard pulls in QML. Compose key and IBus stay.
rm -f ${PYSIDE}/Qt/plugins/platforminputcontexts/libqtvirtualkeyboardplugin.so

# Evdev input handling belongs to a system without a display server.
rm -rf ${PYSIDE}/Qt/plugins/generic

# Qt libraries outside the dependency chain of everything kept above.
find ${PYSIDE}/Qt/lib -maxdepth 1 -type f \
    ! -name 'libQt6Core.so.6' ! -name 'libQt6DBus.so.6' ! -name 'libQt6Gui.so.6' \
    ! -name 'libQt6OpenGL.so.6' ! -name 'libQt6Svg.so.6' ! -name 'libQt6Widgets.so.6' \
    ! -name 'libQt6WaylandClient.so.6' ! -name 'libQt6WlShellIntegration.so.6' \
    ! -name 'libQt6XcbQpa.so.6' \
    ! -name 'libicudata.so.73' ! -name 'libicui18n.so.73' ! -name 'libicuuc.so.73' \
    -delete

# Metatypes describe the Qt API for moc and QML tooling at build time.
rm -rf ${PYSIDE}/Qt/metatypes ${PYSIDE}/Qt/libexec

# Qt translations cover standard dialogs. The application installs no
# QTranslator, so nothing ever reads them.
rm -rf ${PYSIDE}/Qt/translations

# Build backends of the packaging step.
rm -rf ${SITE_PACKAGES}/flit_core ${SITE_PACKAGES}/flit_core-*.dist-info
rm -rf ${SITE_PACKAGES}/pyproject_hooks ${SITE_PACKAGES}/pyproject_hooks-*.dist-info
rm -rf ${SITE_PACKAGES}/patchelf-*.dist-info

rm -f "$0"
