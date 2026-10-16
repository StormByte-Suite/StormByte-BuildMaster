# =============================================================================
# component/backend/binary/create.cmake — BACKEND=binary
# =============================================================================
# Third argument is an http(s) or file URL. The archive is cached under
# BUILDMASTER_DOWNLOADSDIR by its filename, with no hash: an existing file
# is a hit. It is extracted into BUILDMASTER_INSTALL_DIR. The archive root
# must already be the install layout (include/, lib/, bin/).

## @brief Filename used as the cache key (URL path, query stripped).
function(_bm_binary_cache_name _url _out_var)
	string(REGEX REPLACE "[?#].*$" "" _path "${_url}")
	get_filename_component(_name "${_path}" NAME)
	set(${_out_var} "${_name}" PARENT_SCOPE)
endfunction()

## @brief Register a prebuilt library and publish it as IMPORTED targets.
## @param[in] _component       Component id (INTERFACE target + ALIAS).
## @param[in] _component_title Human-readable title.
## @param[in] _url             Download URL. Not a directory.
## @param[in] _options         Ignored (no nested configure).
## @param[in] _library_mode    `static` or `shared`.
## @param[in] _produced        At least one library spec (`<name>` or
##            `<subdir>/<name>`). Names the artifact under the prefix.
## @param[in] _options_string  Optstr. `BACKEND=binary` is required by the
##            factory. `ALIAS=` is applied to the id. `NOINSTALL`, `REPACK`,
##            `WHOLE`, `FILES`, `GIT`, `SOURCE` and meta membership are FATAL.
function(_bm_backend_binary_create _component _component_title _url
		_options _library_mode _produced _options_string)
	string(TOLOWER "${_library_mode}" _mode)
	if(NOT _mode STREQUAL "static" AND NOT _mode STREQUAL "shared")
		_bm_log_message(COMPONENT FATAL
			"BACKEND=binary '${_component}' requires mode static or shared (got '${_library_mode}')")
	endif()

	set(_has_prod FALSE)
	foreach(_spec IN LISTS _produced)
		if(NOT _spec STREQUAL "")
			set(_has_prod TRUE)
			break()
		endif()
	endforeach()
	if(NOT _has_prod)
		_bm_log_message(COMPONENT FATAL
			"BACKEND=binary '${_component}' requires at least one produced library")
	endif()

	_bm_opt_parse(
		_ind _tc _rn _ni _wh _sr
		"${_options_string}")
	if(_ni)
		_bm_log_message(COMPONENT FATAL
			"BACKEND=binary '${_component}': NOINSTALL is not valid")
	endif()
	if(_wh)
		_bm_log_message(COMPONENT FATAL
			"BACKEND=binary '${_component}': WHOLE is not valid")
	endif()
	_bm_opt_parse_repack("${_options_string}" _repack)
	if(_repack)
		_bm_log_message(COMPONENT FATAL
			"BACKEND=binary '${_component}': REPACK is not valid")
	endif()
	_bm_opt_parse_files(
		"${_options_string}" _files_present
		_files_urls _files_names _files_hashes _files_algos
		_files_unpacks _files_forces _files_sources _files_titles)
	if(_files_present)
		_bm_log_message(COMPONENT FATAL
			"BACKEND=binary '${_component}': FILES= is not valid (the URL is the 3rd argument)")
	endif()
	_bm_opt_parse_git(
		"${_options_string}" _git_present _git_fetch _git_switch _git_reset
		_git_patches _git_title _git_root)
	if(_git_present)
		_bm_log_message(COMPONENT FATAL
			"BACKEND=binary '${_component}': GIT= is not valid")
	endif()
	if("${_options_string}" MATCHES "(^|;)SOURCE=")
		_bm_log_message(COMPONENT FATAL
			"BACKEND=binary '${_component}': SOURCE= is not valid")
	endif()

	if("${_url}" STREQUAL "" OR NOT _url MATCHES "^(https?|file)://")
		_bm_log_message(COMPONENT FATAL
			"BACKEND=binary '${_component}': 3rd argument must be an http(s) or file URL")
	endif()
	_bm_binary_cache_name("${_url}" _cache_name)
	if("${_cache_name}" STREQUAL "" OR _cache_name STREQUAL "."
			OR _cache_name MATCHES "[/\\\\]")
		_bm_log_message(COMPONENT FATAL
			"BACKEND=binary '${_component}': URL has no cache filename")
	endif()

	_bm_binary_reject_meta_member("${_component}")

	_bm_graph_create(
		"${_component}" "${_component_title}" "${_url}"
		"${_options}" "${_mode}" "binary" "${_produced}" "${_options_string}")

	set(_dl "_bm_bin_${_component}_dl")
	set(_un "_bm_bin_${_component}_unpack")
	_bm_file_download_cached("${_dl}" "${_url}"
		OUTPUT_NAME "${_cache_name}"
		TITLE "${_component} ${_cache_name}")
	_bm_file_decompress("${_un}"
		"${BUILDMASTER_DOWNLOADSDIR}/${_cache_name}"
		"${BUILDMASTER_INSTALL_DIR}"
		TITLE "${_component} ${_cache_name}"
		DEPENDS "${_dl}")

	set(_names "")
	set(_files "")
	set(_dlls "")
	foreach(_spec IN LISTS _produced)
		if(_spec STREQUAL "")
			continue()
		endif()
		_bm_opt_append_spec(
			"${_mode}" "${_spec}" "${BUILDMASTER_INSTALL_LIBDIR}"
			_names _files _dlls)
	endforeach()

	list(LENGTH _names _nnames)
	set(_i 0)
	while(_i LESS _nnames)
		list(GET _names ${_i} _nm)
		list(GET _files ${_i} _file)
		if(NOT EXISTS "${_file}")
			_bm_log_message(COMPONENT FATAL
				"BACKEND=binary '${_component}': '${_file}' is missing after unpack (the archive root must be the install layout)")
		endif()
		set(_dll "")
		if(MSVC AND _mode STREQUAL "shared")
			list(GET _dlls ${_i} _dll)
			if(NOT EXISTS "${_dll}")
				_bm_log_message(COMPONENT FATAL
					"BACKEND=binary '${_component}': '${_dll}' is missing after unpack (the archive root must be the install layout)")
			endif()
		endif()
		set(_imp "${_component}__bm__${_nm}")
		if(TARGET "${_imp}")
			_bm_log_message(COMPONENT FATAL
				"BACKEND=binary '${_component}': target '${_imp}' already exists")
		endif()
		if(_mode STREQUAL "static")
			add_library("${_imp}" STATIC IMPORTED GLOBAL)
			set_target_properties("${_imp}" PROPERTIES
				IMPORTED_LOCATION "${_file}"
				IMPORTED_LOCATION_DEBUG "${_file}"
				IMPORTED_LOCATION_RELEASE "${_file}"
				IMPORTED_LOCATION_MINSIZEREL "${_file}"
				IMPORTED_LOCATION_RELWITHDEBINFO "${_file}")
		else()
			add_library("${_imp}" SHARED IMPORTED GLOBAL)
			if(MSVC)
				set_target_properties("${_imp}" PROPERTIES
					IMPORTED_IMPLIB "${_file}"
					IMPORTED_IMPLIB_DEBUG "${_file}"
					IMPORTED_IMPLIB_RELEASE "${_file}"
					IMPORTED_IMPLIB_MINSIZEREL "${_file}"
					IMPORTED_IMPLIB_RELWITHDEBINFO "${_file}"
					IMPORTED_LOCATION "${_dll}"
					IMPORTED_LOCATION_DEBUG "${_dll}"
					IMPORTED_LOCATION_RELEASE "${_dll}"
					IMPORTED_LOCATION_MINSIZEREL "${_dll}"
					IMPORTED_LOCATION_RELWITHDEBINFO "${_dll}")
			else()
				set_target_properties("${_imp}" PROPERTIES
					IMPORTED_LOCATION "${_file}"
					IMPORTED_LOCATION_DEBUG "${_file}"
					IMPORTED_LOCATION_RELEASE "${_file}"
					IMPORTED_LOCATION_MINSIZEREL "${_file}"
					IMPORTED_LOCATION_RELWITHDEBINFO "${_file}")
			endif()
		endif()
		math(EXPR _i "${_i} + 1")
	endwhile()

	add_custom_target("${_component}_configure")
	add_custom_target("${_component}_build" DEPENDS "${_dl}")
	add_custom_target("${_component}_install" DEPENDS "${_component}_build" "${_un}")
	set(_i 0)
	while(_i LESS _nnames)
		list(GET _names ${_i} _nm)
		add_dependencies("${_component}__bm__${_nm}" "${_component}_install")
		target_link_libraries("${_component}" INTERFACE "${_component}__bm__${_nm}")
		math(EXPR _i "${_i} + 1")
	endwhile()
	target_include_directories("${_component}" SYSTEM INTERFACE
		"${BUILDMASTER_INSTALL_INCLUDEDIR}")
	add_dependencies("${_component}" "${_component}_install")

	_bm_opt_parse_link("${_options_string}" _link_items)
	if(_link_items)
		target_link_libraries("${_component}" INTERFACE ${_link_items})
	endif()

	set_property(GLOBAL PROPERTY BUILDMASTER_COMPONENT_${_component}_NAMES "${_names}")
	set_property(GLOBAL PROPERTY BUILDMASTER_COMPONENT_${_component}_FILES "${_files}")

	_bm_log_message(COMPONENT STATUS
		"BACKEND=binary '${_component}' (${_mode}) — ${_cache_name}")
endfunction()
