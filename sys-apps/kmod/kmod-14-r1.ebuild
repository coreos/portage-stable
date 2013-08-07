# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/kmod/kmod-14-r1.ebuild,v 1.3 2013/07/23 11:54:33 ssuominen Exp $

EAPI=5

VIRTUAL_MODUTILS=1

inherit autotools eutils libtool multilib linux-mod

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="git://git.kernel.org/pub/scm/utils/kernel/${PN}/${PN}.git"
	inherit git-2
else
	SRC_URI="mirror://kernel/linux/utils/kernel/kmod/${P}.tar.xz"
	KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
fi

DESCRIPTION="library and tools for managing linux kernel modules"
HOMEPAGE="http://git.kernel.org/?p=utils/kernel/kmod/kmod.git"

LICENSE="LGPL-2"
SLOT="0"
IUSE="debug doc lzma +openrc static-libs +tools zlib"

# Upstream does not support running the test suite with custom configure flags.
# I was also told that the test suite is intended for kmod developers.
# So we have to restrict it.
# See bug #408915.
RESTRICT="test"

RDEPEND="!sys-apps/module-init-tools
	!sys-apps/modutils
	lzma? ( >=app-arch/xz-utils-5.0.4-r1 )
	zlib? ( >=sys-libs/zlib-1.2.6 )" #427130
DEPEND="${RDEPEND}
	dev-libs/libxslt
	doc? ( dev-util/gtk-doc )
	lzma? ( virtual/pkgconfig )
	zlib? ( virtual/pkgconfig )"

pkg_setup() {
	CONFIG_CHECK="~MODULES ~MODULE_UNLOAD"
	linux-info_pkg_setup
}

src_prepare() {
	if [ ! -e configure ]; then
		if use doc; then
			gtkdocize --copy --docdir libkmod/docs || die
		else
			touch libkmod/docs/gtk-doc.make
		fi
		eautoreconf
	else
		elibtoolize
	fi

	# Restore possibility of running --enable-static wrt #472608
	sed -i \
		-e '/--enable-static is not supported by kmod/s:as_fn_error:echo:' \
		configure || die
}

src_configure() {
	econf \
		--bindir=/bin \
		--with-rootlibdir=/$(get_libdir) \
		--enable-shared \
		$(use_enable static-libs static) \
		$(use_enable tools) \
		$(use_enable debug) \
		$(use_enable doc gtk-doc) \
		$(use_with lzma xz) \
		$(use_with zlib)
}

src_install() {
	default
	prune_libtool_files

	if use tools; then
		local bincmd sbincmd
		for sbincmd in depmod insmod lsmod modinfo modprobe rmmod; do
			dosym /bin/kmod /sbin/${sbincmd}
		done

		# These are also usable as normal user
		for bincmd in lsmod modinfo; do
			dosym kmod /bin/${bincmd}
		done
	fi

	cat <<-EOF > "${T}"/usb-load-ehci-first.conf
	softdep uhci_hcd pre: ehci_hcd
	softdep ohci_hcd pre: ehci_hcd
	EOF

	insinto /lib/modprobe.d
	doins "${T}"/usb-load-ehci-first.conf #260139

	use openrc && doinitd "${FILESDIR}"/static-nodes
}

pkg_postinst() {
	# Upgrade path from sys-apps/module-init-tools
	if [[ -d ${ROOT}/lib/modules/${KV_FULL} ]]; then
		if [[ -z ${REPLACING_VERSIONS} ]]; then
			update_depmod
		fi
	fi

	if use openrc; then
		# Add kmod to the boot runlevel automatically if this is the first install of this package.
		if [[ -z ${REPLACING_VERSIONS} ]]; then
			if [[ -x "${ROOT}"etc/init.d/static-nodes && -d "${ROOT}"etc/runlevels/boot ]]; then
				ln -s /etc/init.d/static-nodes "${ROOT}"/etc/runlevels/boot/static-nodes
			fi
		fi

		if [[ -e "${ROOT}"etc/runlevels/boot ]]; then
			if [[ ! -e "${ROOT}"etc/runlevels/boot/static-nodes ]]; then
				ewarn
				ewarn "You need to add static-nodes to the boot runlevel."
				ewarn "If you do not do this,"
				ewarn "your system will not necessarily have the required static nodes!"
				ewarn "Run this command:"
				ewarn "\trc-update add static-nodes boot"
			fi
		fi
	fi
}
