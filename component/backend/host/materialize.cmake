# =============================================================================
# component/backend/host/materialize.cmake — deferred host graph wiring
# =============================================================================

function(_bm_backend_host_materialize _component)
	if(NOT TARGET "${_component}")
		_bm_log_message(COMPONENT FATAL
			"host materialize: target '${_component}' does not exist")
	endif()
	foreach(_stage configure build install)
		if(NOT TARGET "${_component}_${_stage}")
			add_custom_target("${_component}_${_stage}")
		endif()
	endforeach()
	add_dependencies("${_component}_build" "${_component}")
	add_dependencies("${_component}_install" "${_component}_build")
	_bm_hook_run_component("${_component}")
endfunction()

function(_bm_backend_host_apply_links)
	get_property(_sources GLOBAL PROPERTY BUILDMASTER_COMPONENT_LINK_SOURCES)
	get_property(_destinations GLOBAL PROPERTY BUILDMASTER_COMPONENT_LINK_DESTS)
	if(NOT _sources)
		return()
	endif()

	set(_index 0)
	foreach(_source IN LISTS _sources)
		list(GET _destinations ${_index} _destination)
		math(EXPR _index "${_index} + 1")
		get_property(_system GLOBAL PROPERTY
			BUILDMASTER_COMPONENT_${_source}_SYSTEM)
		if(_system STREQUAL "host")
			_bm_materialize_apply_link_edge("${_source}" "${_destination}")
		endif()
	endforeach()
endfunction()