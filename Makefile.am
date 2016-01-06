AM_CFLAGS = -w -g
AM_VALAFLAGS = --vapidir $(srcdir)/vapi --target-glib 2.32

bin_PROGRAMS = telepathy-poison

telepathy_poison_SOURCES = \
	src/telepathy/connectionmanager.vala	\
	src/telepathy/protocol.vala	\
	src/telepathy/connection.vala	\
	src/telepathy/channel.vala	\
	src/connectionmanager.vala	\
	src/protocol.vala	\
	src/connection.vala	\
	src/textchannel.vala	\
	src/util.vala


telepathy_poison_VALAFLAGS = $(AM_VALAFLAGS) --pkg gio-2.0 --pkg libtoxcore --pkg misc

telepathy_poison_CFLAGS = $(AM_CFLAGS) $(GIO_CFLAGS) $(TOX_CFLAGS)
telepathy_poison_LDADD = $(GIO_LIBS) $(TOX_LIBS)


servicedir = $(datadir)/dbus-1/services/
service_DATA = data/org.freedesktop.Telepathy.ConnectionManager.poison.service
DISTCLEANFILES = $(service_DATA)

data/org.freedesktop.Telepathy.ConnectionManager.poison.service: Makefile
	$(AM_V_GEN) (echo '[D-BUS Service]'; \
                     echo 'Name=org.freedesktop.Telepathy.ConnectionManager.poison'; \
                     echo 'Exec=${bindir}/telepathy-poison') > $@.tmp && \
                    mv $@.tmp $@

icondir= $(datadir)/icons/hicolor/scalable/apps/
icon_DATA = data/im-tox.svg


EXTRA_DIST = \
	COPYING
#\
#	INSTALL


-include $(top_srcdir)/git.mk
