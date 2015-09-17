using Telepathy;
using Util;

const string BOOTSTRAP_ADDRESS = "23.226.230.47";
const uint16 BOOTSTRAP_PORT = 33445;
const string BOOTSTRAP_KEY = "A09162D68618E742FFBCA1C2C70385E6679604B2D80EA6E84AD0996A1AC8A074";

const string MY_NAME = "ImoutoBot";
const string MY_STATUS_MESSAGE = "This is a message!";


public class Connection : Object, Telepathy.Connection, Telepathy.ConnectionRequests, Telepathy.ConnectionContacts, Telepathy.ConnectionContactList {
	string profile;
	string profile_filename;
	bool keep_connecting = true;
	//bool register;
	Tox tox;

	weak ConnectionManager cm;
    unowned SourceFunc callback;
	DBusConnection dbusconn;

	public Connection (ConnectionManager cm, SourceFunc callback) {
		this.cm = cm;
		this.callback = callback;
	}

	/* DBus name and object registration */
	internal string busname {get; private set;}
	internal ObjectPath objpath {get; private set;}
	uint name_id = 0;
	uint[] obj_ids = {};

	construct {
		profile = "tox_save";
		var escprofile = "tox_save";

		busname = "org.freedesktop.Telepathy.Connection.poison.tox.%s".printf(escprofile);
		objpath = new ObjectPath ("/org/freedesktop/Telepathy/Connection/poison/tox/%s".printf(escprofile));
		debug("own_name %s\n", busname);
		name_id = Bus.own_name (
			BusType.SESSION,
			busname,
			BusNameOwnerFlags.NONE,
			(conn) => {
				dbusconn = conn;
				obj_ids = {
					conn.register_object<Telepathy.Connection> (objpath, this),
					conn.register_object<Telepathy.ConnectionRequests> (objpath, this),
					conn.register_object<Telepathy.ConnectionContacts> (objpath, this),
					conn.register_object<Telepathy.ConnectionContactList> (objpath, this)
				};
				if (callback != null) {
					callback();
					callback = null;
				}
			},
			() => {},
			() => {
				if (callback != null) {
					callback();
					callback = null;
				}
			});

		var config_dir = Environment.get_user_config_dir();
		profile_filename = Path.build_filename(config_dir, "tox", profile + ".tox");
		uint8[] savedata;
		FileUtils.get_data(profile_filename, out savedata);
		debug("loaded %s (%d bytes)", profile_filename, savedata.length);

		var opt = new Tox.Options (null);
		opt.savedata_type = Tox.SavedataType.TOX_SAVE;
		opt.savedata = savedata;

		tox = new Tox(opt, null);
		/* Register the callbacks */
		tox.callback_friend_request(friend_request_callback);
		tox.callback_friend_message(friend_message_callback);
		tox.callback_self_connection_status(self_connection_status_callback);
		/* Define or load some user details for the sake of it */
		// Sets the username
		//tox.self_set_name(MY_NAME.data, null);
		// Sets the status message
		//tox.self_set_status_message(MY_STATUS_MESSAGE.data, null);

		/* Set the user status to MY_TOX.USER_STATUS_NONE. Other possible values:
		   MY_TOX.USER_STATUS_AWAY and MY_TOX.USER_STATUS_BUSY */
		tox.self_set_status(0/*USER_STATUS_NONE*/);

		var address = tox.self_get_address();

		var hex_address = bin_string_to_hex(address);
		_self_id = hex_address;
		//self_handle_changed (self_handle);
		self_contact_changed (self_handle, self_id);
		print("self address %s\n", hex_address);

		var friends = tox.self_get_friend_list();
		print("%d friends\n", friends.length);
		foreach(var friend in friends) {
			print("friend %u\n", friend);
			print("%s %s\n", (string)tox.friend_get_name(friend, null), bin_string_to_hex(tox.friend_get_public_key(friend, null)));
		}
		contact_list_state = ContactListState.SUCCESS;

		run ();
	}
	void friend_request_callback(Tox tox, [CCode (array_length_cexpr = "TOX_PUBLIC_KEY_SIZE")] uint8[] public_key,
								 uint8[] message) {
		print("friend_request_callback\n");
		print("friend request from %s: %s\n",
			  bin_string_to_hex(public_key),
			  ((string)message).escape(""));
		int err;
		tox.friend_add_norequest(public_key, out err);
		print("friend added: %d\n", err);
	}

	void friend_message_callback(Tox tox, uint32 friend_number,
								 int /*TOX_MESSAGE_TYPE*/ type, uint8[] message) {
		friend_message_callback_async.begin (friend_number, type, message);
	}

	async void friend_message_callback_async (uint32 friend_number, int type, uint8[] message) {
		print("friend message from %u (%d): %s\n", friend_number, type, (string)message);

		TextChannel chan;
		if (friend_number in chans)
			chan = chans[friend_number];
		else
			chan = yield create_text_channel (friend_number, false);

		chan.receive_message (type, message);
	}

	void self_connection_status_callback(Tox tox, Tox.Connection conn) {
		print("connection status %d\n", conn);
		if(conn == Tox.Connection.NONE) {
			_status = ConnectionStatus.CONNECTING;
			status_changed (status, ConnectionStatusReason.NONE);
		} else {
			_status = ConnectionStatus.CONNECTED;
			status_changed (status, ConnectionStatusReason.REQUESTED);
		}
	}

	uint _status = ConnectionStatus.DISCONNECTED;
	string _self_id = "";
	public uint self_handle { get { return uint.MAX; } }
	public string self_id { owned get { return _self_id; } }
	public uint status { get { return _status; } }


	public new void connect () {
		debug("%s connect", profile);

		_status = ConnectionStatus.CONNECTING;
		status_changed (ConnectionStatus.CONNECTING, ConnectionStatusReason.REQUESTED);
	}
	public new void disconnect () {
		debug("%s disconnect", profile);
		keep_connecting = false;
		status_changed (ConnectionStatus.DISCONNECTED, ConnectionStatusReason.REQUESTED);
	}

	public string[] interfaces {
		owned get {
			return {"org.freedesktop.Telepathy.Connection.Interface.Contacts",
					"org.freedesktop.Telepathy.Connection.Interface.Requests",
					"org.freedesktop.Telepathy.Connection.Interface.ContactList"};
		}
	}

	public bool has_immortal_handles { get { return true; } }
	public void hold_handles (uint handle_type, uint[] handles) {}
	public void release_handles (uint handle_type, uint[] handles) {}
	public uint[] request_handles (uint handle_type, string[] identifiers) {
		print("request_handles %s\n", string.join(" ", identifiers));
		return {};
	}

	public void add_client_interest (string[] tokens) {}
	public void remove_client_interest (string[] tokens) {}

	/* Connection.Interface.Contacts implementation */

	HashTable<uint, string> requests = new HashTable<uint, string> (direct_hash, direct_equal);
	List<uint> sent_requests;

	[DBus (visible = false)]
	public /*override*/ string[] contact_attribute_interfaces { owned get { return {"org.freedesktop.Telepathy.Connection.Interface.ContactList"}; } }

	public void get_contact_attributes (uint[] handles, string[] interfaces, bool hold,
										out HashTable<uint, HashTable<string, Variant>> attrs) {
		debug("get_contact_attributes (%d)", handles.length);
		attrs = new HashTable<uint, HashTable<string, Variant>> (direct_hash, direct_equal);
		foreach (var handle in handles) {
			var res = new HashTable<string, Variant> (str_hash, str_equal);
			if (handle == uint32.MAX)
				res[CONTACT_ID] = bin_string_to_hex(tox.self_get_public_key ());
			else
				res[CONTACT_ID] = bin_string_to_hex(tox.friend_get_public_key (handle - 1, null));
			debug("%s", (string) res[CONTACT_ID]);
			foreach (var iface in interfaces) {
				switch(iface) {
				case "org.freedesktop.Telepathy.Connection.Interface.ContactList":
					if (handle in requests) {
						res[CONTACT_PUBLISH] = SubscriptionState.ASK;
						res[CONTACT_PUBLISH_REQUEST] = requests[handle];
						res[CONTACT_SUBSCRIBE] = SubscriptionState.NO;
					} else {
						res[CONTACT_PUBLISH] = SubscriptionState.YES;
						res[CONTACT_SUBSCRIBE] = SubscriptionState.YES;
					}
					break;
				default:
					print("%s\n", iface);
					break;
				}
			}
			attrs[handle] = res;
		}
	}

	public void get_contact_by_id (string identifier, string[] interfaces, out uint handle,
								   out HashTable<string, Variant> attrs) {
		warning("get_contact_by_id %s", identifier);
		handle = 0;
		attrs = new HashTable<string, Variant> (str_hash, str_equal);
	}

	/* Connection.Interface.Requests implementation */
	HashTable<uint32, TextChannel> chans = new HashTable<uint32, TextChannel> (direct_hash, direct_equal);

	async TextChannel create_text_channel (uint32 friend_number, bool requested = true) /*requires (!(friend_number in chans))*/ {
		var chan = new TextChannel (tox, friend_number, requested);
		chans[friend_number] = chan;

		yield chan.register (dbusconn, objpath);

		ulong handler_id = 0;
		handler_id = chan.closed.connect (() => {
			chan.disconnect (handler_id);
			chans.remove (friend_number);
		});

		/* Need to announce it after returning */
		Idle.add (() => {
			new_channels ({ChannelDetails (chan.objpath, chan.get_properties ()) });
			return false;
		});

		return chan;
	}

	public void create_channel (HashTable<string, Variant> request,
								out ObjectPath channel,
								out HashTable<string, Variant> properties) throws IOError {
		warning("create_channel");
		request.foreach ((k, v) => {
				print("%s -> %s\n", k, v.print(true));
			});
	}


	[DBus (visible = false)]
	public async void ensure_channel (HashTable<string, Variant> request,
								out bool yours,
								out ObjectPath channel,
								out HashTable<string, Variant> properties) throws IOError {
		debug("ensure_channel");
		request.foreach ((k, v) => {
			print("%s -> %s\n", k, v.print(true));
		});

		const string PROP_TARGET_HANDLE = "org.freedesktop.Telepathy.Channel.TargetHandle";
		const string PROP_TARGET_ID = "org.freedesktop.Telepathy.Channel.TargetID";

		uint32 friend_number;
		if (PROP_TARGET_HANDLE in request)
			friend_number = (uint) request[PROP_TARGET_HANDLE] - 1;
		else
			friend_number = tox.friend_by_public_key(hex_string_to_bin((string) request[PROP_TARGET_ID]), null);

		TextChannel chan;
		if (friend_number in chans) {
			chan = chans[friend_number];
			yours = false;
		} else {
			chan = yield create_text_channel (friend_number);
			yours = true;
		}

		var objpath = chan.objpath;
		var props = chan.get_properties ();

		yours = true;
		channel = objpath;
		properties = props;
	}

	/*public HashTable<string, Variant> fixed_properties;
	  public string[] allowed_properties;*/

	RequestableChannel[] requestable_channels = null;
	[DBus (visible = false)]
	public RequestableChannel[] requestable_channel_classes {
		owned get {
			if (requestable_channels == null) {
				var fixed_properties = new HashTable<string, Variant> (str_hash, str_equal);
				fixed_properties["org.freedesktop.Telepathy.Channel.ChannelType"] = "org.freedesktop.Telepathy.Channel.Type.Text";
				fixed_properties["org.freedesktop.Telepathy.Channel.TargetHandleType"] = HandleType.CONTACT;
				var allowed_properties = new string[] {"org.freedesktop.Telepathy.Channel.TargetHandle", "org.freedesktop.Telepathy.Channel.TargetID"};
				requestable_channels = { RequestableChannel () { fixed_properties = fixed_properties, allowed_properties = allowed_properties}};
			}
			return requestable_channels;
		}
	}
	[DBus (visible = false)]
	public ChannelDetails[] channels {
		owned get {
			var res = new ChannelDetails[chans.length];
			var i = 0;
			foreach(var chan in chans.get_values ()) {
				res[i++] = ChannelDetails (chan.objpath, chan.get_properties ());
			}
			return res;
		}
	}


	/* Connection.Interface.ContactList implementation */
	public void get_contact_list_attributes(string[] interfaces, bool hold,
											out HashTable<uint, HashTable<string, Variant>> attrs) {

		var friends = tox.self_get_friend_list ();
		for(var i = 0; i < friends.length; i++)
			/* tox friend numbers start at 0; but telepathy handles start at 1 */
			friends[i]++;

		/*var contacts = new uint[friends.length + 1];

		contacts[0] = self_handle;
		for(var i = 1; i <= friends.length; i++) {
			/* tox friend numbers start at 0; but telepathy handles start at 1 and need
			 * to use one for self. * /
			contacts[i] = friends[i-1] + 2;
		}*/

		debug("get_contact_list_attributes (%u friends)", friends.length);
		get_contact_attributes (friends, interfaces, hold, out attrs);
	}
	[DBus (visible=false)]
	public uint contact_list_state { get; protected set; default = ContactListState.NONE; }

	void run () {
		/* Bootstrap from the node defined above */
		int err;
		var bootstrap_pub_key = hex_string_to_bin(BOOTSTRAP_KEY);
		tox.bootstrap(BOOTSTRAP_ADDRESS, BOOTSTRAP_PORT, bootstrap_pub_key, out err);
		print("bootstrap %d\n", err);
		//...

		SourceFunc tox_iterate = null;
		tox_iterate = () => {
			// will call the callback functions defined and registered
			tox.iterate();

			if (keep_connecting)
				Timeout.add (tox.iteration_interval, tox_iterate);
			else {
				print("unregistering connection\n");
				foreach (var id in obj_ids) {
					dbusconn.unregister_object(id);
				}
				obj_ids = {};

				Bus.unown_name (name_id);
				name_id = 0;

				var savedata = tox.get_savedata();
				FileUtils.set_data(profile_filename, savedata);
				print("savedata written\n");

				tox = null;
			}
			return false;
		};

		tox_iterate ();
	}
}
