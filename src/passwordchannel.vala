using Telepathy;

public class PasswordChannel : GLib.Object, Telepathy.Channel, Telepathy.ServerAuthenticationChannel, Telepathy.SASLAuthenticationChannel {
	unowned Connection conn;

	public PasswordChannel (Connection conn) {
		this.conn = conn;
	}

	public const string IFACE_CHANNEL = "org.freedesktop.Telepathy.Channel";
	public const string IFACE_SERVER_AUTHENTICATION = "org.freedesktop.Telepathy.Channel.Type.ServerAuthentication";
	public const string IFACE_SASL = "org.freedesktop.Telepathy.Channel.Interface.SASLAuthentication";

	internal HashTable<string, Variant> get_properties () {
		var properties = new HashTable<string, Variant> (str_hash, str_equal);

		properties[IFACE_CHANNEL + ".ChannelType"] = channel_type;
		properties[IFACE_CHANNEL + ".TargetHandleType"] = target_handle_type;
		properties[IFACE_CHANNEL + ".TargetHandle"] = target_handle;
		properties[IFACE_CHANNEL + ".TargetID"] = target_id;
		properties[IFACE_CHANNEL + ".InitiatorHandle"] = initiator_handle;
		properties[IFACE_CHANNEL + ".InitiatorID"] = initiator_id;
		properties[IFACE_CHANNEL + ".Requested"] = requested;
		properties[IFACE_CHANNEL + ".Interfaces"] = interfaces;

		properties[IFACE_SERVER_AUTHENTICATION + ".AuthenticationMethod"] = authentication_method;

		properties[IFACE_SASL + ".AvailableMechanisms"] = available_mechanisms;
		properties[IFACE_SASL + ".HasInitialData"] = has_initial_data;
		properties[IFACE_SASL + ".CanTryAgain"] = can_try_again;
		properties[IFACE_SASL + ".MaySaveResponse"] = may_save_response;

		return properties;
	}

	/* DBus name and object registration */
	DBusConnection dbusconn;
	internal ObjectPath objpath {get; private set;}
	uint[] obj_ids = {};

	internal void register (DBusConnection conn, ObjectPath parent) {
		objpath = new ObjectPath("%s/%s".printf (parent, "password"));
		debug("register %s\n", parent);

		dbusconn = conn;

		obj_ids = {
			conn.register_object<Telepathy.Channel> (objpath, this),
			conn.register_object<Telepathy.ServerAuthenticationChannel> (objpath, this),
			conn.register_object<Telepathy.SASLAuthenticationChannel> (objpath, this),
		};
	}

	public void close () throws IOError, Telepathy.Error {
		if (sasl_status != SASLStatus.SUCCEEDED)
			conn.disconnect ();

		foreach (var obj_id in obj_ids) {
			dbusconn.unregister_object (obj_id);
		}

		obj_ids = {};
		closed ();
	}


	public string channel_type { owned get { return "org.freedesktop.Telepathy.Channel.Type.ServerAuthentication";} }
	public string[] interfaces { owned get { return new string[] { "org.freedesktop.Telepathy.Channel.Interface.SASLAuthentication" }; } }

	public uint target_handle_type { owned get { return Telepathy.HandleType.NONE; } }
	public uint target_handle { owned get { return 0; } }
	public string target_id { owned get { return ""; } }
	public bool requested { owned get { return false; } }
	public uint initiator_handle { owned get { return 0; } }
	public string initiator_id { owned get { return ""; } }

	public string authentication_method { owned get { return "org.freedesktop.Telepathy.Channel.Interface.SASLAuthentication"; } }

	public void start_mechanism (string mechanism) throws IOError, Telepathy.Error {
		throw new Telepathy.Error.NOT_IMPLEMENTED ("use StartMechanismWithData and the X-TELEPATHY-PASSWORD mechanism");
	}
	public void start_mechanism_with_data (string mechanism, uint8[] password) throws Telepathy.Error {
		if (mechanism != "X-TELEPATHY-PASSWORD")
			throw new Telepathy.Error.NOT_IMPLEMENTED ("unsupported mechanism %s.".printf(mechanism));

		if (conn.decrypt_savedata (password))
			set_status (SASLStatus.SERVER_SUCCEEDED, "");
		else
			set_status (SASLStatus.SERVER_FAILED, "org.freedesktop.Telepathy.Error.AuthenticationFailed");
	}

	public void respond (uint8[] response_data) throws Telepathy.Error {
		throw new Telepathy.Error.NOT_IMPLEMENTED ("use StartMechanismWithData and the X-TELEPATHY-PASSWORD mechanism");
	}

	public void accept_sasl () {
		set_status (SASLStatus.SUCCEEDED, "");
		conn.continue_connection ();
	}
	public void abort_sasl (uint reason, string debug_message) {
		set_status (SASLStatus.CLIENT_FAILED, "");
	}

	public string[] available_mechanisms { owned get { return new string[] { "X-TELEPATHY-PASSWORD" }; } }
	public bool has_initial_data { owned get { return true; } }
	public bool can_try_again { owned get { return true; } }

	void set_status (SASLStatus status, string error) {
		_sasl_status = status;
		_sasl_error = error;
		sasl_status_changed (status, error, new HashTable<string, Variant> (str_hash, str_equal));
	}

	SASLStatus _sasl_status = SASLStatus.NOT_STARTED;
	public SASLStatus sasl_status { owned get { return _sasl_status; } }
	string _sasl_error = "";
	public string sasl_error { owned get { return _sasl_error; } }
	public HashTable<string, Variant> sasl_error_details { owned get { return new HashTable<string, Variant> (str_hash, str_equal); } }

	public string authorization_identity { owned get { return ""; } }
	public string default_username { owned get { return ""; } }
	public string default_realm { owned get { return ""; } }
	public bool may_save_response { owned get { return true; } }
}
