# =============================================================================
# component/backend/host/create.cmake — in-process add_library (BACKEND=host)
# =============================================================================

function(_bm_backend_host_create _component _component_title _sources
		_options _library_mode _produced _options_string)
	string(TOLOWER "${_library_mode}" _mode)
	if(NOT _mode STREQUAL "static" AND NOT _mode STREQUAL "shared")
		_bm_log_message(COMPONENT FATAL
			"buildmaster_component('${_component}'): BACKEND=host requires mode static or shared (got '${_mode}')")
	endif()
	if("${_sources}" STREQUAL "")
		_bm_log_message(COMPONENT FATAL
			"buildmaster_component('${_component}'): BACKEND=host requires a non-empty source file list as the 3rd argument")
	endif()
	if(TARGET "${_component}")
		_bm_log_message(COMPONENT FATAL
			"buildmaster_component('${_component}'): BACKEND=host target already exists")
	endif()

	_bm_graph_create(
		"${_component}" "${_component_title}" "${CMAKE_CURRENT_SOURCE_DIR}"
		"${_options}" "${_mode}" "host" "${_produced}" "${_options_string}")

	if(_mode STREQUAL "static")
		add_library("${_component}" STATIC ${_sources})
		set(_link_visibility PUBLIC)
	else()
		add_library("${_component}" SHARED ${_sources})
		set(_link_visibility PRIVATE)
	endif()

	_bm_opt_parse_link("${_options_string}" _link_items)
	if(_link_items)
		target_link_libraries("${_component}" ${_link_visibility} ${_link_items})
	endif()

	_bm_opt_parse_alias("${_options_string}" _aliases)
	_bm_alias_apply("${_component}" "${_aliases}")

	add_custom_target("${_component}_configure")
	add_custom_target("${_component}_build")
	add_dependencies("${_component}_build" "${_component}")
	add_custom_target("${_component}_install")
	add_dependencies("${_component}_install" "${_component}_build")

	_bm_log_message(COMPONENT STATUS
		"BACKEND=host '${_component}' (${_mode}) — in-process library")
endfunction()
