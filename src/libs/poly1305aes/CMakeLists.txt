option(LIBPOLY1305AES_BUILD_SO "build poly1305aes as a shared library" OFF)

if(LIBPOLY1305AES_BUILD_SO)
   set(LIBPOLY1305AES_TYPE SHARED)
   add_definitions( -DLIBPOLY1305AES_BUILD_SO)
else(LIBPOLY1305AES_BUILD_SO)
   set(LIBPOLY1305AES_TYPE STATIC)
endif(LIBPOLY1305AES_BUILD_SO)

file(GLOB LIBPOLY1305AES_PUB_HEADERS "src/poly1305aes/*.h")
file(GLOB LIBPOLY1305AES_SEC_HEADERS "src/poly1305aes/poly1305aes-20050218/*.h")
file(GLOB LIBPOLY1305AES_FILES "src/poly1305aes/*.[cS]")
file(GLOB LIBPOLY1305AES_ASMFILES "src/poly1305aes/*.S")
set_source_files_properties(${LIBPOLY1305AES_ASMFILES} PROPERTIES COMPILE_FLAGS "-DASMFILE__")

add_library(libpoly1305aes ${LIBPOLY1305AES_TYPE}
                           ${LIBPOLY1305AES_PUB_HEADERS}
                           ${LIBPOLY1305AES_FILES})

set_target_properties(libpoly1305aes PROPERTIES OUTPUT_NAME poly1305aes)
set_target_properties(libpoly1305aes PROPERTIES PUBLIC_HEADER "${LIBPOLY1305AES_PUB_HEADERS}")
set_target_properties(libpoly1305aes PROPERTIES PRIVATE_HEADER "${LIBPOLY1305AES_SEC_HEADERS}")
set_target_properties(libpoly1305aes PROPERTIES VERSION ${LIBPOLY1305AES_VERSION} SOVERSION ${LIBPOLY1305AES_VERSION})

install(TARGETS libpoly1305aes
        RUNTIME DESTINATION "${LEELA_INSTALL_BINDIR}"
        LIBRARY DESTINATION "${LEELA_INSTALL_LIBDIR}"
        ARCHIVE DESTINATION "${LEELA_INSTALL_ARCDIR}"
        PUBLIC_HEADER DESTINATION "${LEELA_INSTALL_HDRDIR}/poly1305aes"
        PRIVATE_HEADER DESTINATION "${LEELA_INSTALL_HDRDIR}/poly1305aes/poly1305aes-20050218")
