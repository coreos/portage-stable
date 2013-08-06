# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/distutils-r1.eclass,v 1.74 2013/08/01 13:02:32 mgorny Exp $

# @ECLASS: distutils-r1
# @MAINTAINER:
# Python team <python@gentoo.org>
# @AUTHOR:
# Author: Michał Górny <mgorny@gentoo.org>
# Based on the work of: Krzysztof Pawlik <nelchael@gentoo.org>
# @BLURB: A simple eclass to build Python packages using distutils.
# @DESCRIPTION:
# A simple eclass providing functions to build Python packages using
# the distutils build system. It exports phase functions for all
# the src_* phases. Each of the phases runs two pseudo-phases:
# python_..._all() (e.g. python_prepare_all()) once in ${S}, then
# python_...() (e.g. python_prepare()) for each implementation
# (see: python_foreach_impl() in python-r1).
#
# In distutils-r1_src_prepare(), the 'all' function is run before
# per-implementation ones (because it creates the implementations),
# per-implementation functions are run in a random order.
#
# In remaining phase functions, the per-implementation functions are run
# before the 'all' one, and they are ordered from the least to the most
# preferred implementation (so that 'better' files overwrite 'worse'
# ones).
#
# If the ebuild doesn't specify a particular pseudo-phase function,
# the default one will be used (distutils-r1_...). Defaults are provided
# for all per-implementation pseudo-phases, python_prepare_all()
# and python_install_all(); whenever writing your own pseudo-phase
# functions, you should consider calling the defaults (and especially
# distutils-r1_python_prepare_all).
#
# Please note that distutils-r1 sets RDEPEND and DEPEND unconditionally
# for you.
#
# Also, please note that distutils-r1 will always inherit python-r1
# as well. Thus, all the variables defined and documented there are
# relevant to the packages using distutils-r1.
#
# For more information, please see the python-r1 Developer's Guide:
# http://www.gentoo.org/proj/en/Python/python-r1/dev-guide.xml

case "${EAPI:-0}" in
	0|1|2|3)
		die "Unsupported EAPI=${EAPI:-0} (too old) for ${ECLASS}"
		;;
	4|5)
		;;
	*)
		die "Unsupported EAPI=${EAPI} (unknown) for ${ECLASS}"
		;;
esac

# @ECLASS-VARIABLE: DISTUTILS_OPTIONAL
# @DEFAULT_UNSET
# @DESCRIPTION:
# If set to a non-null value, distutils part in the ebuild will
# be considered optional. No dependencies will be added and no phase
# functions will be exported.
#
# If you enable DISTUTILS_OPTIONAL, you have to set proper dependencies
# for your package (using ${PYTHON_DEPS}) and to either call
# distutils-r1 default phase functions or call the build system
# manually.

# @ECLASS-VARIABLE: DISTUTILS_SINGLE_IMPL
# @DEFAULT_UNSET
# @DESCRIPTION:
# If set to a non-null value, the ebuild will support setting a single
# Python implementation only. It will effectively replace the python-r1
# eclass inherit with python-single-r1.
#
# Note that inheriting python-single-r1 will cause pkg_setup()
# to be exported. It must be run in order for the eclass functions
# to function properly.

if [[ ! ${_DISTUTILS_R1} ]]; then

inherit eutils

if [[ ! ${DISTUTILS_SINGLE_IMPL} ]]; then
	inherit multiprocessing python-r1
else
	inherit python-single-r1
fi

fi

if [[ ! ${DISTUTILS_OPTIONAL} ]]; then
	EXPORT_FUNCTIONS src_prepare src_configure src_compile src_test src_install
fi

if [[ ! ${_DISTUTILS_R1} ]]; then

if [[ ! ${DISTUTILS_OPTIONAL} ]]; then
	RDEPEND=${PYTHON_DEPS}
	DEPEND=${PYTHON_DEPS}
	REQUIRED_USE=${PYTHON_REQUIRED_USE}
fi

# @ECLASS-VARIABLE: PATCHES
# @DEFAULT_UNSET
# @DESCRIPTION:
# An array containing patches to be applied to the sources before
# copying them.
#
# If unset, no custom patches will be applied.
#
# Please note, however, that at some point the eclass may apply
# additional distutils patches/quirks independently of this variable.
#
# Example:
# @CODE
# PATCHES=( "${FILESDIR}"/${P}-make-gentoo-happy.patch )
# @CODE

# @ECLASS-VARIABLE: DOCS
# @DEFAULT_UNSET
# @DESCRIPTION:
# An array containing documents installed using dodoc. The files listed
# there must exist in the directory from which
# distutils-r1_python_install_all() is run (${S} by default).
#
# If unset, the function will instead look up files matching default
# filename pattern list (from the Package Manager Specification),
# and install those found.
#
# Example:
# @CODE
# DOCS=( NEWS README )
# @CODE

# @ECLASS-VARIABLE: HTML_DOCS
# @DEFAULT_UNSET
# @DESCRIPTION:
# An array containing documents installed using dohtml. The files
# and directories listed there must exist in the directory from which
# distutils-r1_python_install_all() is run (${S} by default).
#
# If unset, no HTML docs will be installed.
#
# Example:
# @CODE
# HTML_DOCS=( doc/html/. )
# @CODE

# @ECLASS-VARIABLE: EXAMPLES
# @DEFAULT_UNSET
# @DESCRIPTION:
# An array containing examples installed into 'examples' doc
# subdirectory. The files and directories listed there must exist
# in the directory from which distutils-r1_python_install_all() is run
# (${S} by default).
#
# The 'examples' subdirectory will be marked not to be compressed
# automatically.
#
# If unset, no examples will be installed.
#
# Example:
# @CODE
# EXAMPLES=( examples/. demos/. )
# @CODE

# @ECLASS-VARIABLE: DISTUTILS_IN_SOURCE_BUILD
# @DEFAULT_UNSET
# @DESCRIPTION:
# If set to a non-null value, in-source builds will be enabled.
# If unset, the default is to use in-source builds when python_prepare()
# is declared, and out-of-source builds otherwise.
#
# If in-source builds are used, the eclass will create a copy of package
# sources for each Python implementation in python_prepare_all(),
# and work on that copy afterwards.
#
# If out-of-source builds are used, the eclass will instead work
# on the sources directly, prepending setup.py arguments with
# 'build --build-base ${BUILD_DIR}' to enforce keeping & using built
# files in the specific root.

# @ECLASS-VARIABLE: DISTUTILS_NO_PARALLEL_BUILD
# @DEFAULT_UNSET
# @DESCRIPTION:
# If set to a non-null value, the parallel build feature will
# be disabled.
#
# When parallel builds are used, the implementation-specific sub-phases
# for selected Python implementation will be run in parallel. This will
# increase build efficiency with distutils which does not do parallel
# builds.
#
# This variable can be used to disable the afore-mentioned feature
# in case it causes issues with the package.

# @ECLASS-VARIABLE: mydistutilsargs
# @DEFAULT_UNSET
# @DESCRIPTION:
# An array containing options to be passed to setup.py.
#
# Example:
# @CODE
# python_configure_all() {
# 	mydistutilsargs=( --enable-my-hidden-option )
# }
# @CODE

# @FUNCTION: esetup.py
# @USAGE: [<args>...]
# @DESCRIPTION:
# Run setup.py using currently selected Python interpreter
# (if ${PYTHON} is set; fallback 'python' otherwise).
#
# setup.py will be passed the following, in order:
# 1. ${mydistutilsargs[@]}
# 2. The 'build' command and standard build options including ${BUILD_DIR}
# 3. Any additional arguments passed to the esetup.py function.
#
# This command dies on failure.
esetup.py() {
	debug-print-function ${FUNCNAME} "${@}"

	local add_args=()
	if [[ ${BUILD_DIR} ]]; then
		add_args+=(
			build
			--build-base "${BUILD_DIR}"

			# using a single directory for them helps us export
			# ${PYTHONPATH} and ebuilds find the sources independently
			# of whether the package installs extensions or not
			#
			# note: due to some packages (wxpython) relying on separate
			# platlib & purelib dirs, we do not set --build-lib (which
			# can not be overriden with --build-*lib)
			--build-platlib "${BUILD_DIR}/lib"
			--build-purelib "${BUILD_DIR}/lib"

			# make the ebuild writer lives easier
			--build-scripts "${BUILD_DIR}/scripts"
		)

		# if setuptools is used, adjust egg_info path as well
		if "${PYTHON:-python}" setup.py --help egg_info &>/dev/null; then
			add_args+=(
				egg_info --egg-base "${BUILD_DIR}"
			)
		fi
	elif [[ ! ${DISTUTILS_IN_SOURCE_BUILD} ]]; then
		die 'Out-of-source build requested, yet BUILD_DIR unset.'
	fi

	set -- "${PYTHON:-python}" setup.py \
		"${mydistutilsargs[@]}" "${add_args[@]}" "${@}"

	echo "${@}" >&2
	"${@}" || die
}

# @FUNCTION: distutils_install_for_testing
# @USAGE: [<args>...]
# @DESCRIPTION:
# Install the package into a temporary location for running tests.
# Update PYTHONPATH appropriately and set TEST_DIR to the test
# installation root. The Python packages will be installed in 'lib'
# subdir, and scripts in 'scripts' subdir (like in BUILD_DIR).
#
# Please note that this function should be only used if package uses
# namespaces (and therefore proper install needs to be done to enforce
# PYTHONPATH) or tests rely on the results of install command.
# For most of the packages, tests built in BUILD_DIR are good enough.
distutils_install_for_testing() {
	debug-print-function ${FUNCNAME} "${@}"

	# A few notes:
	# 1) because of namespaces, we can't use 'install --root',
	# 2) 'install --home' is terribly broken on pypy, so we need
	#    to override --install-lib and --install-scripts,
	# 3) non-root 'install' complains about PYTHONPATH and missing dirs,
	#    so we need to set it properly and mkdir them,
	# 4) it runs a bunch of commands which write random files to cwd,
	#    in order to avoid that, we need to run them ourselves to pass
	#    alternate build paths,
	# 5) 'install' needs to go before 'bdist_egg' or the latter would
	#    re-set install paths.

	TEST_DIR=${BUILD_DIR}/test
	local bindir=${TEST_DIR}/scripts
	local libdir=${TEST_DIR}/lib
	PYTHONPATH=${libdir}:${PYTHONPATH}

	local add_args=(
		install
			--home="${TEST_DIR}"
			--install-lib="${libdir}"
			--install-scripts="${bindir}"
	)

	if "${PYTHON:-python}" setup.py --help bdist_egg &>/dev/null; then
		add_args+=(
			bdist_egg --dist-dir="${TEST_DIR}"
		)
	fi

	mkdir -p "${libdir}" || die
	esetup.py "${add_args[@]}"
}

_disable_ez_setup() {
	local stub="def use_setuptools(*args, **kwargs): pass"
	[[ -f ez_setup.py ]] && echo "${stub}" > ez_setup.py
	[[ -f distribute_setup.py ]] && echo "${stub}" > distribute_setup.py
}

# @FUNCTION: distutils-r1_python_prepare_all
# @DESCRIPTION:
# The default python_prepare_all(). It applies the patches from PATCHES
# array, then user patches and finally calls python_copy_sources to
# create copies of resulting sources for each Python implementation.
#
# At some point in the future, it may also apply eclass-specific
# distutils patches and/or quirks.
distutils-r1_python_prepare_all() {
	debug-print-function ${FUNCNAME} "${@}"

	[[ ${PATCHES} ]] && epatch "${PATCHES[@]}"

	epatch_user

	# by default, use in-source build if python_prepare() is used
	if [[ ! ${DISTUTILS_IN_SOURCE_BUILD+1} ]]; then
		if declare -f python_prepare >/dev/null; then
			DISTUTILS_IN_SOURCE_BUILD=1
		fi
	fi

	# Prevent packages from downloading their own copy of setuptools
	_disable_ez_setup

	if [[ ${DISTUTILS_IN_SOURCE_BUILD} && ! ${DISTUTILS_SINGLE_IMPL} ]]
	then
		# create source copies for each implementation
		python_copy_sources
	fi

	_DISTUTILS_DEFAULT_CALLED=1
}

# @FUNCTION: distutils-r1_python_prepare
# @DESCRIPTION:
# The default python_prepare(). A no-op.
distutils-r1_python_prepare() {
	debug-print-function ${FUNCNAME} "${@}"

	:
}

# @FUNCTION: distutils-r1_python_configure
# @DESCRIPTION:
# The default python_configure(). A no-op.
distutils-r1_python_configure() {
	debug-print-function ${FUNCNAME} "${@}"

	:
}

# @FUNCTION: distutils-r1_python_compile
# @USAGE: [additional-args...]
# @DESCRIPTION:
# The default python_compile(). Runs 'esetup.py build'. Any parameters
# passed to this function will be appended to setup.py invocation,
# i.e. passed as options to the 'build' command.
distutils-r1_python_compile() {
	debug-print-function ${FUNCNAME} "${@}"

	esetup.py "${@}"
}

# @FUNCTION: distutils-r1_python_test
# @DESCRIPTION:
# The default python_test(). A no-op.
distutils-r1_python_test() {
	debug-print-function ${FUNCNAME} "${@}"

	:
}

# @FUNCTION: _distutils-r1_rename_scripts
# @USAGE: <path>
# @INTERNAL
# @DESCRIPTION:
# Renames installed Python scripts to be implementation-suffixed.
# ${EPYTHON} needs to be set to the implementation name.
#
# All executable scripts having shebang referencing ${EPYTHON}
# in given path will be renamed.
_distutils-r1_rename_scripts() {
	debug-print-function ${FUNCNAME} "${@}"

	local path=${1}
	[[ ${path} ]] || die "${FUNCNAME}: no path given"

	local f
	while IFS= read -r -d '' f; do
		debug-print "${FUNCNAME}: found executable at ${f#${D}/}"

		local shebang
		read -r shebang < "${f}"
		if [[ ${shebang} == '#!'*${EPYTHON}* ]]
		then
			debug-print "${FUNCNAME}: matching shebang: ${shebang}"

			local newf=${f}-${EPYTHON}
			debug-print "${FUNCNAME}: renaming to ${newf#${D}/}"
			mv "${f}" "${newf}" || die

			debug-print "${FUNCNAME}: installing wrapper at ${f#${D}/}"
			_python_ln_rel "${path}${EPREFIX}"/usr/bin/python-exec "${f}" || die
		fi
	done < <(find "${path}" -type f -executable -print0)
}

# @FUNCTION: distutils-r1_python_install
# @USAGE: [additional-args...]
# @DESCRIPTION:
# The default python_install(). Runs 'esetup.py install', appending
# the optimization flags. Then renames the installed scripts.
# Any parameters passed to this function will be appended
# to the setup.py invocation (i.e. as options to the 'install' command).
distutils-r1_python_install() {
	debug-print-function ${FUNCNAME} "${@}"

	local flags

	case "${EPYTHON}" in
		jython*)
			flags=(--compile);;
		*)
			flags=(--compile -O2);;
	esac
	debug-print "${FUNCNAME}: [${EPYTHON}] flags: ${flags}"

	# enable compilation for the install phase.
	local -x PYTHONDONTWRITEBYTECODE

	# python likes to compile any module it sees, which triggers sandbox
	# failures if some packages haven't compiled their modules yet.
	addpredict "$(python_get_sitedir)"
	addpredict /usr/lib/portage/pym

	local root=${D}/_${EPYTHON}
	[[ ${DISTUTILS_SINGLE_IMPL} ]] && root=${D}

	esetup.py install "${flags[@]}" --root="${root}" "${@}"

	if [[ -d ${root}$(python_get_sitedir)/tests ]]; then
		die "Package installs 'tests' package, file collisions likely."
	fi

	if [[ ! ${DISTUTILS_SINGLE_IMPL} ]]; then
		_distutils-r1_rename_scripts "${root}"
		multibuild_merge_root "${root}" "${D}"
	fi
}

# @FUNCTION: distutils-r1_python_install_all
# @DESCRIPTION:
# The default python_install_all(). It installs the documentation.
distutils-r1_python_install_all() {
	debug-print-function ${FUNCNAME} "${@}"

	if declare -p DOCS &>/dev/null; then
		# an empty list == don't install anything
		if [[ ${DOCS[@]} ]]; then
			dodoc -r "${DOCS[@]}"
		fi
	else
		local f
		# same list as in PMS
		for f in README* ChangeLog AUTHORS NEWS TODO CHANGES \
				THANKS BUGS FAQ CREDITS CHANGELOG; do
			if [[ -s ${f} ]]; then
				dodoc "${f}"
			fi
		done
	fi

	if declare -p HTML_DOCS &>/dev/null; then
		dohtml -r "${HTML_DOCS[@]}"
	fi

	if declare -p EXAMPLES &>/dev/null; then
		local INSDESTTREE=/usr/share/doc/${PF}/examples
		doins -r "${EXAMPLES[@]}"
		docompress -x "${INSDESTTREE}"
	fi

	_DISTUTILS_DEFAULT_CALLED=1
}

# @FUNCTION: distutils-r1_run_phase
# @USAGE: [<argv>...]
# @INTERNAL
# @DESCRIPTION:
# Run the given command.
#
# If out-of-source builds are used, the phase function is run in source
# directory, with BUILD_DIR pointing at the build directory
# and PYTHONPATH having an entry for the module build directory.
#
# If in-source builds are used, the command is executed in the directory
# holding the per-implementation copy of sources. BUILD_DIR points
# to the 'build' subdirectory.
distutils-r1_run_phase() {
	debug-print-function ${FUNCNAME} "${@}"

	if [[ ${DISTUTILS_IN_SOURCE_BUILD} ]]; then
		if [[ ! ${DISTUTILS_SINGLE_IMPL} ]]; then
			pushd "${BUILD_DIR}" >/dev/null || die
		fi
		local BUILD_DIR=${BUILD_DIR}/build
	fi
	local -x PYTHONPATH="${BUILD_DIR}/lib:${PYTHONPATH}"

	local TMPDIR=${T}/${EPYTHON}

	mkdir -p "${TMPDIR}" || die

	"${@}"

	if [[ ${DISTUTILS_IN_SOURCE_BUILD} && ! ${DISTUTILS_SINGLE_IMPL} ]]
	then
		popd >/dev/null || die
	fi
}

# @FUNCTION: _distutils-r1_run_common_phase
# @USAGE: [<argv>...]
# @INTERNAL
# @DESCRIPTION:
# Run the given command, restoring the best-implementation state.
#
# If in-source build is used, the command will be run in the copy
# of sources made for the best Python interpreter.
_distutils-r1_run_common_phase() {
	local DISTUTILS_ORIG_BUILD_DIR=${BUILD_DIR}

	if [[ ! ${DISTUTILS_SINGLE_IMPL} ]]; then
		local MULTIBUILD_VARIANTS
		_python_obtain_impls

		multibuild_for_best_variant _python_multibuild_wrapper \
			distutils-r1_run_phase "${@}"
	else
		# semi-hack, be careful.
		_distutils-r1_run_foreach_impl "${@}"
	fi
}

# @FUNCTION: _distutils-r1_run_foreach_impl
# @INTERNAL
# @DESCRIPTION:
# Run the given phase for each implementation if multiple implementations
# are enabled, once otherwise.
_distutils-r1_run_foreach_impl() {
	debug-print-function ${FUNCNAME} "${@}"

	set -- distutils-r1_run_phase "${@}"

	if [[ ! ${DISTUTILS_SINGLE_IMPL} ]]; then
		if [[ ${DISTUTILS_NO_PARALLEL_BUILD} || ${DISTUTILS_SINGLE_IMPL} ]]
		then
			python_foreach_impl "${@}"
		else
			python_parallel_foreach_impl "${@}"
		fi
	else
		if [[ ! ${EPYTHON} ]]; then
			die "EPYTHON unset, python-single-r1_pkg_setup not called?!"
		fi
		local BUILD_DIR=${BUILD_DIR:-${S}}
		BUILD_DIR=${BUILD_DIR%%/}_${EPYTHON}

		"${@}"
	fi
}

distutils-r1_src_prepare() {
	debug-print-function ${FUNCNAME} "${@}"

	local _DISTUTILS_DEFAULT_CALLED

	# common preparations
	if declare -f python_prepare_all >/dev/null; then
		python_prepare_all
	else
		distutils-r1_python_prepare_all
	fi

	if [[ ! ${_DISTUTILS_DEFAULT_CALLED} ]]; then
		eqawarn "QA warning: python_prepare_all() didn't call distutils-r1_python_prepare_all"
	fi

	if declare -f python_prepare >/dev/null; then
		_distutils-r1_run_foreach_impl python_prepare
	fi
}

distutils-r1_src_configure() {
	if declare -f python_configure >/dev/null; then
		_distutils-r1_run_foreach_impl python_configure
	fi

	if declare -f python_configure_all >/dev/null; then
		_distutils-r1_run_common_phase python_configure_all
	fi
}

distutils-r1_src_compile() {
	debug-print-function ${FUNCNAME} "${@}"

	if declare -f python_compile >/dev/null; then
		_distutils-r1_run_foreach_impl python_compile
	else
		_distutils-r1_run_foreach_impl distutils-r1_python_compile
	fi

	if declare -f python_compile_all >/dev/null; then
		_distutils-r1_run_common_phase python_compile_all
	fi
}

distutils-r1_src_test() {
	debug-print-function ${FUNCNAME} "${@}"

	if declare -f python_test >/dev/null; then
		_distutils-r1_run_foreach_impl python_test
	fi

	if declare -f python_test_all >/dev/null; then
		_distutils-r1_run_common_phase python_test_all
	fi
}

distutils-r1_src_install() {
	debug-print-function ${FUNCNAME} "${@}"

	if declare -f python_install >/dev/null; then
		_distutils-r1_run_foreach_impl python_install
	else
		_distutils-r1_run_foreach_impl distutils-r1_python_install
	fi

	local _DISTUTILS_DEFAULT_CALLED

	if declare -f python_install_all >/dev/null; then
		_distutils-r1_run_common_phase python_install_all
	else
		_distutils-r1_run_common_phase distutils-r1_python_install_all
	fi

	if [[ ! ${_DISTUTILS_DEFAULT_CALLED} ]]; then
		eqawarn "QA warning: python_install_all() didn't call distutils-r1_python_install_all"
	fi
}

_DISTUTILS_R1=1
fi
