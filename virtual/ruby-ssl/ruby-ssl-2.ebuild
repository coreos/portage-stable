# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/ruby-ssl/ruby-ssl-2.ebuild,v 1.2 2011/12/15 09:55:27 graaff Exp $

EAPI=2
USE_RUBY="jruby"

inherit ruby-ng

DESCRIPTION="Virtual ebuild for the Ruby OpenSSL bindings"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="${USE_RUBY}"
KEYWORDS="amd64 x86"
IUSE=""

RDEPEND="dev-ruby/jruby-openssl"

pkg_setup() { :; }
src_unpack() { :; }
src_prepare() { :; }
src_compile() { :; }
src_install() { :; }
pkg_preinst() { :; }
pkg_postinst() { :; }

# DEVELOPERS' NOTE!
#
# This virtual has multiple version that ties one-by-one with the Ruby
# implementation they provide the value for; this is to simplify
# keywording practise that has been shown to be very messy for other
# virtuals.
#
# Make sure that you DO NOT change the version of the virtual's
# ebuilds unless you're adding a new implementation; instead simply
# revision-bump it.
#
# A reference to ~${PV} for each of the version has to be added to
# profiles/base/package.use.force to make sure that they are always
# used with their own implementation.
#
# ruby_add_[br]depend will take care of depending on multiple versions
# without any frown.
