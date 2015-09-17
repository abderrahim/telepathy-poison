/* XXX: get this in glib vapi */
[CCode (cname = "g_strndup")]
extern static string buffer_to_string (/*[CCode (array_length_type = "gsize")]*/ uint8[] buffer);
