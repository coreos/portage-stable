# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/clang/clang-9999-r100.ebuild,v 1.1 2013/07/21 10:03:46 mgorny Exp $

EAPI=5

DESCRIPTION="C language family frontend for LLVM (meta-ebuild)"
HOMEPAGE="http://clang.llvm.org/"
SRC_URI=""

LICENSE="UoI-NCSA"
SLOT="0"
KEYWORDS=""
IUSE="debug multitarget python +static-analyzer"

RDEPEND="~sys-devel/llvm-${PV}[clang(-),debug=,multitarget=,python=,static-analyzer=]"

# Please keep this package around since it's quite likely that we'll
# return to separate LLVM & clang ebuilds when the cmake build system
# is complete.
