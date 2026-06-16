# new shader build system

find_program(FXC_COMPILER NAMES fxc
    HINTS 
        "C:/Program Files (x86)/Windows Kits/10/bin/*/x64"
        "C:/Program Files (x86)/Windows Kits/8.1/bin/x64"
)

if(CMAKE_HOST_UNIX AND CMAKE_CROSSCOMPILING AND PLATFORM_NAME STREQUAL "Windows64")
    set(_FXC_COMPILER "${CMAKE_SOURCE_DIR}/Minecraft.Client/Windows64/4JLibs/impls/Windows_Libs/Render/shaders/fxc.exe")

    find_program(WINE NAMES wine)
    if(NOT WINE)
        message(FATAL_ERROR "Could not find 'wine', please make sure you have wine installed.")
    endif()

    message(STATUS "Translating FXC through Wine")

    set(FXC_COMPILER_WRAPPER "${CMAKE_SOURCE_DIR}/Minecraft.Client/Windows64/4JLibs/impls/Windows_Libs/Render/shaders/fxcwinewrapper.sh.in")
    set(_FXC_COMPILER_WRAPPER "${CMAKE_SOURCE_DIR}/Minecraft.Client/Windows64/4JLibs/impls/Windows_Libs/Render/shaders/fxcwinewrapper.sh")

    configure_file(
        "${FXC_COMPILER_WRAPPER}"
        "${_FXC_COMPILER_WRAPPER}"
        @ONLY
    )
	file(CHMOD "${_FXC_COMPILER_WRAPPER}"
	    PERMISSIONS
	    OWNER_READ OWNER_WRITE OWNER_EXECUTE
	    GROUP_READ GROUP_EXECUTE
	    WORLD_READ WORLD_EXECUTE
	)

    set(FXC_COMPILER "${_FXC_COMPILER_WRAPPER}" CACHE FILEPATH "Path to FXC compiler" FORCE)
endif()

if(NOT FXC_COMPILER)
    message(FATAL_ERROR "Could not find 'fxc.exe', please make sure you have the Windows SDK installed or this file is available in this directory.")
endif()

set(SHADER_OUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/inc")

function(compile_hlsl)
    set(options)
    set(argDescriptor SOURCE PROFILE ENTRY OUT_HEADER VAR_NAME)
    set(defDescriptor DEFINES)
    cmake_parse_arguments(ARG "${options}" "${argDescriptor}" "${defDescriptor}" ${ARGN})

    set(OUT_FILE "${SHADER_OUT_DIR}/${ARG_OUT_HEADER}")

    set(FXC_DEFINES "")
    foreach(DEF ${ARG_DEFINES})
        list(APPEND FXC_DEFINES "/D" "${DEF}")
    endforeach()

    add_custom_command(
        OUTPUT  "${OUT_FILE}"
        # should probably disable optimizations and enable debug flags when building in debug mode, but i don't care enough to do that right now BUAHAHAHA
        COMMAND ${FXC_COMPILER} /O3 /nologo /T ${ARG_PROFILE} /E ${ARG_ENTRY} ${FXC_DEFINES} /Fh "${OUT_FILE}" /Vn ${ARG_VAR_NAME} "${CMAKE_CURRENT_LIST_DIR}/${ARG_SOURCE}"
        DEPENDS "${CMAKE_CURRENT_LIST_DIR}/${ARG_SOURCE}"
        COMMENT "Compiling shader: '${ARG_SOURCE}' into '${ARG_OUT_HEADER}'"
        VERBATIM
    )

    # send the generated paths to the parent scope
    set(GENERATED_SHADER_HEADERS ${GENERATED_SHADER_HEADERS} "${OUT_FILE}" PARENT_SCOPE)
endfunction()

compile_hlsl(SOURCE main_VS.hlsl PROFILE vs_4_0 ENTRY main OUT_HEADER VS_Compressed.h VAR_NAME g_main_VS_Compressed DEFINES COMPRESSED)
compile_hlsl(SOURCE main_VS.hlsl PROFILE vs_4_0 ENTRY main OUT_HEADER VS_PF3_TF2_CB4_NB4_XW1.h VAR_NAME g_main_VS_PF3_TF2_CB4_NB4_XW1)
compile_hlsl(SOURCE main_VS.hlsl PROFILE vs_4_0 ENTRY main OUT_HEADER VS_PF3_TF2_CB4_NB4_XW1_LIGHTING.h VAR_NAME g_main_VS_PF3_TF2_CB4_NB4_XW1_LIGHTING DEFINES LIGHTING)
compile_hlsl(SOURCE main_VS.hlsl PROFILE vs_4_0 ENTRY main OUT_HEADER VS_PF3_TF2_CB4_NB4_XW1_TEXGEN.h VAR_NAME g_main_VS_PF3_TF2_CB4_NB4_XW1_TEXGEN DEFINES TEXGEN)
compile_hlsl(SOURCE screen_VS.hlsl PROFILE vs_4_0 ENTRY VS_ScreenSpace OUT_HEADER VS_ScreenSpace.h VAR_NAME g_main_VS_ScreenSpace)
compile_hlsl(SOURCE screen_VS.hlsl PROFILE vs_4_0 ENTRY VS_ScreenClear OUT_HEADER VS_ScreenClear.h VAR_NAME g_main_VS_ScreenClear)

compile_hlsl(SOURCE main_PS.hlsl PROFILE ps_4_0 ENTRY main OUT_HEADER PS_Standard.h VAR_NAME g_main_PS_Standard)
compile_hlsl(SOURCE main_PS.hlsl PROFILE ps_4_0 ENTRY main OUT_HEADER PS_TextureProjection.h VAR_NAME g_main_PS_TextureProjection DEFINES TEXTURE_PROJECTION)
compile_hlsl(SOURCE main_PS.hlsl PROFILE ps_4_0 ENTRY main OUT_HEADER PS_ForceLOD.h VAR_NAME g_main_PS_ForceLOD DEFINES FORCE_LOD)
compile_hlsl(SOURCE screen_PS.hlsl PROFILE ps_4_0 ENTRY PS_ScreenSpace OUT_HEADER PS_ScreenSpace.h VAR_NAME g_main_PS_ScreenSpace)
compile_hlsl(SOURCE screen_PS.hlsl PROFILE ps_4_0 ENTRY PS_ScreenClear OUT_HEADER PS_ScreenClear.h VAR_NAME g_main_PS_ScreenClear)