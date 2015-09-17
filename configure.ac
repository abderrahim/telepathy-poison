AC_PREREQ([2.69])
AC_INIT([telepathy-poison], [0.1])

AM_INIT_AUTOMAKE([1.11 foreign subdir-objects])
AM_SILENT_RULES([yes])

AC_PROG_CC
AM_PROG_VALAC

PKG_CHECK_MODULES(GIO, [gio-2.0])
PKG_CHECK_MODULES(TOX, [libtoxcore])

AC_CONFIG_FILES([Makefile])
dnl                 misc/Makefile])
AC_OUTPUT
