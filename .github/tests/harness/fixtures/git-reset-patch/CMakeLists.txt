# Own throwaway repo. Reset must run before patch on every configure.

set(_GRP "${CMAKE_CURRENT_BINARY_DIR}/repo")
if(NOT EXISTS "${_GRP}/.git")
    file(MAKE_DIRECTORY "${_GRP}")
    execute_process(
        COMMAND "${GIT_EXECUTABLE}" init
        WORKING_DIRECTORY "${_GRP}"
        RESULT_VARIABLE _rc
    )
    if(NOT _rc EQUAL 0)
        message(FATAL_ERROR "git-reset-patch: git init failed")
    endif()
    file(WRITE "${_GRP}/README" "clean\n")
    execute_process(COMMAND "${GIT_EXECUTABLE}" add README WORKING_DIRECTORY "${_GRP}")
    execute_process(
        COMMAND "${GIT_EXECUTABLE}" -c user.email=bm@test -c user.name=BM
            commit -m "seed"
        WORKING_DIRECTORY "${_GRP}"
    )
endif()

file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/add_marker.patch"
"diff --git a/README b/README
index 1111111..2222222 100644
--- a/README
+++ b/README
@@ -1 +1,2 @@
 clean
+patched
")

file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/add_second_marker.patch"
"diff --git a/SECOND_MARKER b/SECOND_MARKER
new file mode 100644
--- /dev/null
+++ b/SECOND_MARKER
@@ -0,0 +1 @@
+second patch applied
")

# Patch first in source order; flush must still reset then apply.
# Reset before applying the variable-backed PATCH batch on every configure.
_bm_tools_git_reset(
    grp
    "harness reset-patch reset"
    "${_GRP}"
)

set(_patches
    "${CMAKE_CURRENT_BINARY_DIR}/add_marker.patch"
    "${CMAKE_CURRENT_BINARY_DIR}/add_second_marker.patch")
set(_git_optstr "GIT={PATCH={${_patches}};TITLE=variable patch batch}")

# PATCHES is a real CMake list expanded into the nested GIT group.
_bm_comp_apply_git(grp "harness reset-patch apply" "${_GRP}" "${_git_optstr}")

file(READ "${_GRP}/README" _readme)
if(NOT _readme MATCHES "patched")
    message(FATAL_ERROR
        "git-reset-patch: README was not patched after flush:\n${_readme}")
endif()
if(NOT EXISTS "${_GRP}/SECOND_MARKER")
    message(FATAL_ERROR "git-reset-patch: second batch patch was not applied")
endif()
