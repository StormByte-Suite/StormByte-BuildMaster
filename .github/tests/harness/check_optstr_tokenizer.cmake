set(_patches patch-one.diff patch-two.diff)
if(WIN32)
	set(_linkflags_platform WINDOWS)
	set(_linkflags_expected "/FORCE:MULTIPLE;/INCREMENTAL:NO")
elseif(APPLE)
	set(_linkflags_platform MAC)
	set(_linkflags_expected "-pthread;-Wl,--as-needed")
else()
	set(_linkflags_platform LINUX)
	set(_linkflags_expected "-pthread;-Wl,--as-needed")
endif()
set(_optstr
	"TOOLCHAIN=gcc;GIT={PATCH={${_patches}};TITLE=tokenizer probe};LINK={m;dl};LINKFLAGS={${_linkflags_platform}={${_linkflags_expected}}}")

_bm_opt_split_pairs("${_optstr}" _pairs)
list(LENGTH _pairs _pair_count)
if(NOT _pair_count EQUAL 4)
	message(FATAL_ERROR
		"optstr tokenizer: expected 4 outer items, got ${_pair_count}: ${_pairs}")
endif()

_bm_opt_parse_git("${_optstr}"
	_git_present _fetch _switch _reset _parsed_patches _title _root)
if(NOT _git_present OR NOT "${_parsed_patches}" STREQUAL "patch-one.diff;patch-two.diff")
	message(FATAL_ERROR
		"optstr tokenizer: PATCH batch parsed as '${_parsed_patches}'")
endif()
if(NOT _title STREQUAL "tokenizer probe")
	message(FATAL_ERROR
		"optstr tokenizer: sibling TITLE parsed as '${_title}'")
endif()

_bm_opt_parse_link("${_optstr}" _link_items)
if(NOT "${_link_items}" STREQUAL "m;dl")
	message(FATAL_ERROR
		"optstr tokenizer: LINK list parsed as '${_link_items}'")
endif()

_bm_opt_parse_linkflags("${_optstr}" _linkflags)
if(NOT "${_linkflags}" STREQUAL "${_linkflags_expected}")
	message(FATAL_ERROR
		"optstr tokenizer: nested LINKFLAGS parsed as '${_linkflags}'")
endif()

message(STATUS "optstr tokenizer: list-valued nested items stay intact")