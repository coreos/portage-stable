# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/numpy/numpy-1.6.2-r2.ebuild,v 1.16 2013/03/10 16:20:27 ago Exp $

EAPI=5

PYTHON_COMPAT=( python{2_5,2_6,2_7,3_1,3_2} )

FORTRAN_NEEDED=lapack

inherit distutils-r1 eutils flag-o-matic fortran-2 multilib toolchain-funcs versionator

DOC_P="${PN}-1.6.0"

DESCRIPTION="Fast array and numerical python library"
HOMEPAGE="http://numpy.scipy.org/ http://pypi.python.org/pypi/numpy"
SRC_URI="mirror://sourceforge/numpy/${P}.tar.gz
	doc? (
		http://docs.scipy.org/doc/${DOC_P}/numpy-html.zip -> ${DOC_P}-html.zip
		http://docs.scipy.org/doc/${DOC_P}/numpy-ref.pdf -> ${DOC_P}-ref.pdf
		http://docs.scipy.org/doc/${DOC_P}/numpy-user.pdf -> ${DOC_P}-user.pdf
	)"

LICENSE="BSD"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~x86-interix ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="doc lapack test"

RDEPEND="
	dev-python/setuptools[${PYTHON_USEDEP}]
	lapack? ( virtual/cblas virtual/lapack )"
DEPEND="${RDEPEND}
	doc? ( app-arch/unzip )
	lapack? ( virtual/pkgconfig )
	test? ( >=dev-python/nose-0.10[${PYTHON_USEDEP}] )"

# Uses distutils.command.config.
DISTUTILS_IN_SOURCE_BUILD=1

src_unpack() {
	unpack ${P}.tar.gz
	if use doc; then
		unzip -qo "${DISTDIR}"/${DOC_P}-html.zip -d html || die
	fi
}

pc_incdir() {
	$(tc-getPKG_CONFIG) --cflags-only-I $@ | \
		sed -e 's/^-I//' -e 's/[ ]*-I/:/g'
}

pc_libdir() {
	$(tc-getPKG_CONFIG) --libs-only-L $@ | \
		sed -e 's/^-L//' -e 's/[ ]*-L/:/g'
}

pc_libs() {
	$(tc-getPKG_CONFIG) --libs-only-l $@ | \
		sed -e 's/[ ]-l*\(pthread\|m\)[ ]*//g' \
		-e 's/^-l//' -e 's/[ ]*-l/,/g'
}

python_prepare_all() {
	epatch \
		"${FILESDIR}"/${PN}-1.6.1-atlas.patch \
		"${FILESDIR}"/${P}-test-pareto.patch

	if use lapack; then
		append-ldflags "$($(tc-getPKG_CONFIG) --libs-only-other cblas lapack)"
		local libdir="${EPREFIX}"/usr/$(get_libdir)
		# make sure _dotblas.so gets built
		sed -i -e '/NO_ATLAS_INFO/,+1d' numpy/core/setup.py || die
		cat >> site.cfg <<-EOF
			[blas]
			include_dirs = $(pc_incdir cblas)
			library_dirs = $(pc_libdir cblas blas):${libdir}
			blas_libs = $(pc_libs cblas blas)
			[lapack]
			library_dirs = $(pc_libdir lapack):${libdir}
			lapack_libs = $(pc_libs lapack)
		EOF
	else
		export {ATLAS,PTATLAS,BLAS,LAPACK,MKL}=None
	fi

	export CC="$(tc-getCC) ${CFLAGS}"

	append-flags -fno-strict-aliasing

	# See progress in http://projects.scipy.org/scipy/numpy/ticket/573
	# with the subtle difference that we don't want to break Darwin where
	# -shared is not a valid linker argument
	if [[ ${CHOST} != *-darwin* ]]; then
		append-ldflags -shared
	fi

	# only one fortran to link with:
	# linking with cblas and lapack library will force
	# autodetecting and linking to all available fortran compilers
	if use lapack; then
		append-fflags -fPIC
		NUMPY_FCONFIG="config_fc --noopt --noarch"
		# workaround bug 335908
		[[ $(tc-getFC) == *gfortran* ]] && NUMPY_FCONFIG+=" --fcompiler=gnu95"
	fi

	# don't version f2py, we will handle it.
	sed -i -e '/f2py_exe/s:+os\.path.*$::' numpy/f2py/setup.py || die

	distutils-r1_python_prepare_all
}

python_compile() {
	distutils-r1_python_compile ${NUMPY_FCONFIG}
}

python_test() {
	distutils_install_for_testing ${NUMPY_FCONFIG}

	cd "${TMPDIR}" || die
	"${PYTHON}" -c "
import numpy, sys
r = numpy.test()
sys.exit(0 if r.wasSuccessful() else 1)" || die "Tests fail with ${EPYTHON}"
}

python_install() {
	distutils-r1_python_install ${NUMPY_FCONFIG}

	rm -f "${D}"$(python_get_sitedir)/numpy/*.txt
}

python_install_all() {
	distutils-r1_python_install_all

	dodoc COMPATIBILITY DEV_README.txt THANKS.txt

	docinto f2py
	dodoc numpy/f2py/docs/*.txt
	doman numpy/f2py/f2py.1

	if use doc; then
		insinto /usr/share/doc/${PF}
		doins -r "${WORKDIR}"/html
		doins "${DISTDIR}"/${DOC_P}*pdf
	fi
}
