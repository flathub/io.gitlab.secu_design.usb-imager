#!/bin/bash
# Removes what the PySide base app installs for building bindings and for Qt
# modules the application never imports. Saves about 270 MB.
set -eu

APP="${FLATPAK_DEST:-/app}"
SITE_PACKAGES="${APP}"/lib/python3.*/site-packages

# The shiboken binding generator only runs at build time. It pulls in LLVM and
# clang, together about 160 MB.
rm -rf "${APP}"/lib/libLLVM.so* "${APP}"/lib/libclang.so* "${APP}"/lib/libclang-cpp.so*
rm -rf ${SITE_PACKAGES}/shiboken6_generator ${SITE_PACKAGES}/shiboken6_generator-*.dist-info
rm -f "${APP}"/bin/shiboken6 "${APP}"/bin/shiboken6-genpyi

# PyOpenGL comes with the base app. The application never imports it.
rm -rf ${SITE_PACKAGES}/OpenGL ${SITE_PACKAGES}/pyopengl-*.dist-info

# Qt developer tools, none of them run inside the application.
for tool in assistant designer lupdate lrelease qmlls qmlformat qmllint qsb balsam balsamui; do
    rm -rf ${SITE_PACKAGES}/PySide6/"${tool}"
done

# Headers, type systems and glue code belong to the binding generator.
rm -rf ${SITE_PACKAGES}/PySide6/include ${SITE_PACKAGES}/PySide6/typesystems ${SITE_PACKAGES}/PySide6/glue

# Type stubs serve editors, not the running program.
rm -f ${SITE_PACKAGES}/PySide6/*.pyi

# The application imports QtCore, QtGui, QtSvg and QtWidgets. The other 47
# modules add about 26 MB.
find ${SITE_PACKAGES}/PySide6 -maxdepth 1 -name 'Qt*.abi3.so' \
    ! -name 'QtCore.*' ! -name 'QtGui.*' ! -name 'QtSvg.*' ! -name 'QtWidgets.*' -delete

# FFmpeg is bundled for QtMultimedia, which the line above just removed.
rm -rf ${SITE_PACKAGES}/PySide6/Qt/lib

# Build backends of the packaging step.
rm -rf ${SITE_PACKAGES}/flit_core ${SITE_PACKAGES}/flit_core-*.dist-info
rm -rf ${SITE_PACKAGES}/pyproject_hooks ${SITE_PACKAGES}/pyproject_hooks-*.dist-info
rm -rf ${SITE_PACKAGES}/patchelf-*.dist-info

rm -f "$0"
