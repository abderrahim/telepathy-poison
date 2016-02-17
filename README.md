This is a [telepathy](http://telepathy.freedesktop.org/wiki/) connection manager for [tox](http://tox.chat).

It can be compiled using the standard autotools way:

    autoreconf -i     # only needed if compiling from git
    ./configure
    make
    sudo make install

The only dependencies toxcore and glib. You also need Vala with the patch from
[Bug 735437](https://bugzilla.gnome.org/show_bug.cgi?id=735437), otherwise receiving a message will fail if
the contact window isn't open.
