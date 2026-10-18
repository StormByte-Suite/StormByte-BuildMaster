#!/bin/bash
# Apple Clang 21 (Xcode 26) aborts a combined compile-and-link that passes
# -flto: "LLVM ERROR: Unexistent dir: .../cc-*.o". Meson dependency probes
# are that command. A normal build compiles with -c and links the .o files,
# which does not hit the bug. Split only the one-shot so LTO stays on.
# The object replaces the source in the argument list: ld64 does not
# rescan, so a static archive that followed the source must follow the .o.
set -euo pipefail
if [[ $# -lt 1 ]]; then
	echo "apple_lto_oneshot: missing compiler" >&2
	exit 2
fi
real="$1"
shift

has_c=0
has_src=0
has_flto=0
has_other=0
for a in "$@"; do
	case "$a" in
		-c) has_c=1 ;;
		-E|-M|-MM|-MG|-fsyntax-only|-S|--version|-dumpmachine|-dumpversion|--print-search-dirs|-###|-dM|--help|--target-help)
			has_other=1 ;;
		-flto|-flto=*) has_flto=1 ;;
		*.c|*.cc|*.cpp|*.cxx|*.C|*.m|*.mm|*.S) has_src=1 ;;
	esac
done
if [[ "$has_c" -eq 1 || "$has_src" -eq 0 || "$has_flto" -eq 0 || "$has_other" -eq 1 ]]; then
	exec "$real" "$@"
fi

args=("$@")
compile=()
link=()
sources=()
out=""
placed=0
i=0
while [[ $i -lt ${#args[@]} ]]; do
	a="${args[$i]}"
	nxt=""
	if [[ $((i + 1)) -lt ${#args[@]} ]]; then
		nxt="${args[$((i + 1))]}"
	fi
	case "$a" in
		-o)
			out="$nxt"
			i=$((i + 2))
			continue
			;;
		*.c|*.cc|*.cpp|*.cxx|*.C|*.m|*.mm|*.S)
			sources+=("$a")
			if [[ "$placed" -eq 0 ]]; then
				link+=("__BM_OBJS__")
				placed=1
			fi
			i=$((i + 1))
			continue
			;;
		-isystem|-include|-x|--sysroot|-isysroot|-target|-arch|-Xclang|-Xlinker)
			# -arch / -isysroot belong to both steps. -Xlinker is link-only.
			case "$a" in
				-Xlinker)
					link+=("$a" "$nxt")
					;;
				-arch|-isysroot|--sysroot|-target)
					compile+=("$a" "$nxt")
					link+=("$a" "$nxt")
					;;
				*)
					compile+=("$a" "$nxt")
					;;
			esac
			i=$((i + 2))
			continue
			;;
		-framework)
			link+=("$a" "$nxt")
			i=$((i + 2))
			continue
			;;
		-flto|-flto=*)
			compile+=("$a")
			link+=("$a")
			;;
		-m*)
			compile+=("$a")
			link+=("$a")
			;;
		-Wl,*|-L*|-l*|-F*)
			link+=("$a")
			;;
		-I*|-D*|-U*|-W*|-f*|-O*|-std=*|-stdlib=*|-isystem*|-include*|-x*|-pthread|-pedantic*|-g*)
			compile+=("$a")
			;;
		*.a|*.o|*.dylib|*.so|*.tbd)
			link+=("$a")
			;;
		*)
			compile+=("$a")
			link+=("$a")
			;;
	esac
	i=$((i + 1))
done

if [[ -z "$out" || ${#sources[@]} -eq 0 ]]; then
	exec "$real" "$@"
fi

objdir="$(mktemp -d "${TMPDIR:-/tmp}/bm-lto.XXXXXX")"
trap 'rm -rf "$objdir"' EXIT
objs=()
n=0
for s in "${sources[@]}"; do
	obj="${objdir}/o${n}.o"
	"$real" -c "${compile[@]}" "$s" -o "$obj"
	objs+=("$obj")
	n=$((n + 1))
done
final=()
for a in "${link[@]}"; do
	if [[ "$a" == "__BM_OBJS__" ]]; then
		final+=("${objs[@]}")
	else
		final+=("$a")
	fi
done
"$real" "${final[@]}" -o "$out"
exit $?
