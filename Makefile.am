AM_CFLAGS = -w -g
AM_VALAFLAGS = --vapidir $(srcdir)/vapi --target-glib 2.32

bin_PROGRAMS = telepathy-poison

telepathy_poison_SOURCES = \
	src/telepathy/connectionmanager.vala	\
	src/telepathy/connection.vala	\
	src/telepathy/channel.vala	\
	src/connectionmanager.vala	\
	src/connection.vala	\
	src/textchannel.vala	\
	src/util.vala


telepathy_poison_VALAFLAGS = $(AM_VALAFLAGS) --pkg gio-2.0 --pkg libtoxcore --pkg misc

telepathy_poison_CFLAGS = $(AM_CFLAGS) $(GIO_CFLAGS) $(TOX_CFLAGS)
telepathy_poison_LDADD = $(GIO_LIBS) $(TOX_LIBS)

EXTRA_DIST = \
	COPYING
#\
#	INSTALL
