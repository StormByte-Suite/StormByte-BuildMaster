# =============================================================================
# component/backend/binary/materialize.cmake — stage anchors + meta reject
# =============================================================================

## @brief Keep stage anchors and run the component hook.
## @param[in] _component Registered binary id.
## @note Download and extract already ran at registration. The anchors exist
##       so depend / link / group can name this id like any other node.
function(_bm_backend_binary_materialize _component)
	if(NOT TARGET "${_component}")
		_bm_log_message(COMPONENT FATAL
			"binary materialize: target '${_component}' does not exist")
	endif()
	foreach(_stage configure build install)
		if(NOT TARGET "${_component}_${_stage}")
			add_custom_target("${_component}_${_stage}")
		endif()
	endforeach()
	if(TARGET "_bm_bin_${_component}_dl")
		add_dependencies("${_component}_build" "_bm_bin_${_component}_dl")
	endif()
	if(TARGET "_bm_bin_${_component}_unpack")
		add_dependencies("${_component}_install" "_bm_bin_${_component}_unpack")
	endif()
	add_dependencies("${_component}_install" "${_component}_build")
	_bm_hook_run_component("${_component}")
endfunction()

## @brief Order each binary install behind the dests recorded by link/depend.
## @note `buildmaster_link` already stores a depend edge and, because the id
##       is INTERFACE, puts that dest on the link line. The nested cmake
##       fragment is what normally waits on `<dest>_install`. A binary has
##       no fragment, so `<id>_install` would otherwise extract this archive
##       without downloading or extracting the dest. Call after every
##       component has materialized: a cmake dest's stage targets do not
##       exist until its own materialize.
function(_bm_binary_wire_deps)
	get_property(_ids GLOBAL PROPERTY BUILDMASTER_COMPONENT_IDS)
	if(NOT _ids)
		return()
	endif()
	foreach(_id IN LISTS _ids)
		get_property(_sys GLOBAL PROPERTY BUILDMASTER_COMPONENT_${_id}_SYSTEM)
		if(NOT _sys STREQUAL "binary")
			continue()
		endif()
		if(NOT TARGET "${_id}_install")
			_bm_log_message(COMPONENT FATAL
				"BACKEND=binary '${_id}': ${_id}_install does not exist")
		endif()
		_bm_graph_dep_targets("${_id}" _wait)
		if("${_wait}" STREQUAL "")
			continue()
		endif()
		separate_arguments(_wait)
		foreach(_tgt IN LISTS _wait)
			if(NOT TARGET "${_tgt}")
				_bm_log_message(COMPONENT FATAL
					"BACKEND=binary '${_id}': dependency '${_tgt}' is not a target")
			endif()
			add_dependencies("${_id}_install" "${_tgt}")
		endforeach()
	endforeach()
endfunction()

## @brief FATAL when `_id` is already listed in a meta.
## @param[in] _id Component id.
function(_bm_binary_reject_meta_member _id)
	get_property(_metas GLOBAL PROPERTY BUILDMASTER_META_IDS)
	if(NOT _metas)
		return()
	endif()
	foreach(_meta IN LISTS _metas)
		get_property(_members GLOBAL PROPERTY BUILDMASTER_META_${_meta}_MEMBERS)
		if("${_id}" IN_LIST _members)
			_bm_log_message(COMPONENT FATAL
				"BACKEND=binary '${_id}' cannot be a member of meta '${_meta}'")
		endif()
	endforeach()
endfunction()

## @brief FATAL if any registered binary id was added to a meta after register.
function(_bm_binary_reject_meta)
	get_property(_ids GLOBAL PROPERTY BUILDMASTER_COMPONENT_IDS)
	if(NOT _ids)
		return()
	endif()
	foreach(_id IN LISTS _ids)
		get_property(_sys GLOBAL PROPERTY BUILDMASTER_COMPONENT_${_id}_SYSTEM)
		if(_sys STREQUAL "binary")
			_bm_binary_reject_meta_member("${_id}")
		endif()
	endforeach()
endfunction()
