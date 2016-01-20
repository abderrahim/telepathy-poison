using Telepathy;
using Util;

struct Node {
	public string address;
	public uint16 port;
	public string key;
}

const Node[] nodes = {
	{"23.226.230.47", 33445, "A09162D68618E742FFBCA1C2C70385E6679604B2D80EA6E84AD0996A1AC8A074"},
	{"178.62.250.138", 33445, "788236D34978D1D5BD822F0A5BEBD2C53C64CC31CD3149350EE27D4D9A2F9B6B"},
	{"130.133.110.14", 33445, "461FA3776EF0FA655F1A05477DF1B3B614F7D6B124F7DB1DD4FE3C08B03B640F"},
	{"104.167.101.29", 33445, "5918AC3C06955962A75AD7DF4F80A5D7C34F7DB9E1498D2E0495DE35B3FE8A57"},
	{"205.185.116.116", 33445, "A179B09749AC826FF01F37A9613F6B57118AE014D4196A0E1105A98F93A54702"},
	{"198.98.51.198", 33445, "1D5A5F2F5D6233058BF0259B09622FB40B482E4FA0931EB8FD3AB8E7BF7DAF6F"},
	{"194.249.212.109", 33445, "3CEE1F054081E7A011234883BC4FC39F661A55B73637A5AC293DDF1251D9432B"},
	{"185.25.116.107", 33445, "DA4E4ED4B697F2E9B000EEFE3A34B554ACD3F45F5C96EAEA2516DD7FF9AF7B43"},
	{"192.99.168.140", 33445, "6A4D0607A296838434A6A7DDF99F50EF9D60A2C510BBF31FE538A25CB6B4652F"},
	{"95.215.46.114", 33445, "5823FB947FF24CF83DDFAC3F3BAA18F96EA2018B16CC08429CB97FA502F40C23"},
	{"5.189.176.217", 5190, "2B2137E094F743AC8BD44652C55F41DFACC502F125E99E4FE24D40537489E32F"},
	{"148.251.23.146", 2306, "7AED21F94D82B05774F697B209628CD5A9AD17E0C073D9329076A4C28ED28147"},
	{"104.223.122.15", 33445, "0FB96EEBFB1650DDB52E70CF773DDFCABE25A95CC3BB50FC251082E4B63EF82A"},
	{"78.47.114.252", 33445, "1C5293AEF2114717547B39DA8EA6F1E331E5E358B35F9B6B5F19317911C5F976"},
	{"81.4.110.149", 33445, "9E7BD4793FFECA7F32238FA2361040C09025ED3333744483CA6F3039BFF0211E"},
	{"95.31.20.151", 33445, "9CA69BB74DE7C056D1CC6B16AB8A0A38725C0349D187D8996766958584D39340"},
	{"104.233.104.126", 33445, "EDEE8F2E839A57820DE3DA4156D88350E53D4161447068A3457EE8F59F362414"},
	{"51.254.84.212", 33445, "AEC204B9A4501412D5F0BB67D9C81B5DB3EE6ADA64122D32A3E9B093D544327D"},
	{"5.135.59.163", 33445, "2D320F971EF2CA18004416C2AAE7BA52BF7949DB34EA8E2E21AF67BD367BE211"},
};

public class Connection : Object, Telepathy.Connection, Telepathy.ConnectionRequests, Telepathy.ConnectionContacts, Telepathy.ConnectionAliasing, Telepathy.ConnectionContactList, Telepathy.ConnectionSimplePresence {
	public string profile { private get; construct; }
	public ConnectionManager cm { private get; construct; }
	public bool enable_udp { private get; construct; }
	string profile_filename;
	bool keep_connecting = true;
	Tox tox;

    unowned SourceFunc callback;
	DBusConnection dbusconn;

	public Connection (ConnectionManager cm, string profile, string? password, bool create, bool enable_udp, SourceFunc callback) {
		Object (cm: cm, profile: profile, enable_udp: enable_udp);
		this.callback = callback;
	}

	/* DBus name and object registration */
	internal string busname {get; private set;}
	internal ObjectPath objpath {get; private set;}
	uint name_id = 0;
	uint[] obj_ids = {};

	construct {
		print("%s\n", profile);
		var escprofile = profile;

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
					conn.register_object<Telepathy.ConnectionAliasing> (objpath, this),
					conn.register_object<Telepathy.ConnectionContactList> (objpath, this),
					conn.register_object<Telepathy.ConnectionSimplePresence> (objpath, this),
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
		opt.udp_enabled = enable_udp;
		print("Enable UDP: %s - TCP port: %d\n", opt.udp_enabled ? "yes" : "no", opt.tcp_port);

		tox = new Tox(opt, null);
		/* Register the callbacks */
		tox.callback_self_connection_status(self_connection_status_callback);

		tox.callback_friend_message(friend_message_callback);

		tox.callback_friend_request(friend_request_callback);

		tox.callback_friend_name (friend_name_callback);

		tox.callback_friend_status(friend_status_callback);
		tox.callback_friend_status_message(friend_status_message_callback);
		tox.callback_friend_connection_status(friend_connection_status_callback);

		tox.callback_friend_typing(friend_typing_callback);

		var address = tox.self_get_address();

		var hex_address = bin_string_to_hex(address);
		_self_id = hex_address;
		self_contact_changed (self_handle, self_id);
		print("self address %s\n", hex_address);

		contact_list_state_changed (ContactListState.SUCCESS);

		run ();
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
			return cm.proto.connection_interfaces;
		}
	}

	public bool has_immortal_handles { get { return true; } }
	public void hold_handles (uint handle_type, uint[] handles) {}
	public void release_handles (uint handle_type, uint[] handles) {}

	/* 
	 * Telepathy handles are mapped this way:
	 * - self is uint.MAX
	 * - friends are friend_number + 1
	 * - others are assigned values decreasing from uint.MAX - 1
	 */

	uint next_handle = uint.MAX - 1;
	HashTable<uint, string> handles = new HashTable<uint, string> (direct_hash, direct_equal);
	public uint[] request_handles (uint handle_type, string[] identifiers) {
		return_val_if_fail (handle_type == HandleType.CONTACT, new uint[0]);

		var res = new uint[identifiers.length];
		for (var i = 0; i < identifiers.length; i++) {
			var friend_number = tox.friend_by_public_key (hex_string_to_bin (identifiers[i]), null);
			if (friend_number != uint32.MAX) {
				res[i] = friend_number + 1;
			} else {
				uint handle = 0;
				handles.find ((k, v) => {
					if (v == identifiers[i]) {
						handle = k;
						return true;
					}
					return false;
				});

				if (handle != 0) {
					res[i] = handle;
				} else {
					handles[next_handle] = identifiers[i];
					info("handle %u -> %s", next_handle, identifiers[i]);
					res[i] = next_handle--;
				}
			}
		}
		return res;
	}

	public void add_client_interest (string[] tokens) {}
	public void remove_client_interest (string[] tokens) {}

	/* Connection.Interface.Contacts implementation */
	public string[] contact_attribute_interfaces {
		owned get {
			return {"org.freedesktop.Telepathy.Connection.Interface.Aliasing",
					"org.freedesktop.Telepathy.Connection.Interface.ContactList",
					"org.freedesktop.Telepathy.Connection.Interface.SimplePresence",
					};
		}
	}

	public void get_contact_attributes (uint[] contacts, string[] interfaces, bool hold,
										out HashTable<uint, HashTable<string, Variant>> attrs) {
		debug("get_contact_attributes (%d)", contacts.length);
		attrs = new HashTable<uint, HashTable<string, Variant>> (direct_hash, direct_equal);
		foreach (var handle in contacts) {
			var res = new HashTable<string, Variant> (str_hash, str_equal);
			if (handle == self_handle)
				res[CONTACT_ID] = bin_string_to_hex(tox.self_get_public_key ());
			else if (handle in handles) {
				print("%u is in handles\n", handle);
				res[CONTACT_ID] = handles[handle];
			} else {
				var friend_number = handle - 1;
				res[CONTACT_ID] = bin_string_to_hex(tox.friend_get_public_key (friend_number, null));
			}
			debug("%s", (string) res[CONTACT_ID]);
			foreach (var iface in interfaces) {
				switch(iface) {
				case "org.freedesktop.Telepathy.Connection.Interface.Aliasing":
					if (handle == self_handle)
						res[CONTACT_ALIAS] = (string) tox.self_get_name ();
					else if (!(handle in handles)) {
						var friend_number = handle - 1;
						var friend_name = tox.friend_get_name (friend_number, null);
						if (friend_name != null)
							res[CONTACT_ALIAS] = (string) friend_name;
					}
					break;
				case "org.freedesktop.Telepathy.Connection.Interface.ContactList":
					var subs = get_subscription_state (handle);
					res[CONTACT_SUBSCRIBE] = subs.subscribe;
					res[CONTACT_PUBLISH] = subs.publish;
					if (subs.publish_request != "")
						res[CONTACT_PUBLISH_REQUEST] = subs.publish_request;
					break;
				case "org.freedesktop.Telepathy.Connection.Interface.SimplePresence":
					res[CONTACT_PRESENCE] = get_presence (handle);
					break;
				default:
					print("get_contact_attributes: unknown interface %s\n", iface);
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

	public RequestableChannel[] requestable_channel_classes {
		owned get {
			return cm.proto.requestable_channel_classes;
		}
	}

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
		debug("get_contact_list_attributes (%u friends, %u requests)", friends.length, handles.length);
		var contacts = new uint[friends.length + received_requests.length];
		for(var i = 0; i < friends.length; i++)
			/* tox friend numbers start at 0, but telepathy handles start at 1 */
			contacts[i] = friends[i] + 1;

		var i = friends.length;
		foreach (var handle in received_requests.get_keys ()) {
			contacts[i++] = handle;
			print("%u\n", handle);
		}
		get_contact_attributes (contacts, interfaces, hold, out attrs);
	}

	/* There are four possible subscription states for a tox contact:
	 * - They have sent a friend request, and it hasn't yet been accepted
	 *   (in handles, received_requests) => subscribe=no, publish=ask
	 * - We are about to send them a friend request
	 *   (in handles) => subscribe=no, publish=no
	 * - They are on the friend list, and a request has been sent this session (and we could not yet connect)
	 *   (in sent_requests and the friend list) => subscribe=ask, publish=yes
	 * - They are on the friend list, but a request hasn't been sent this session, or has been accepted
	 *   (unless we are currently connected, this could mean many things but we cannot distinguish between them)
	 *   (in the friend list) => subscribe=yes, publish=yes
	 *
	 * (This will change with the new groupchats, but this will do for now)
	 */

	HashTable<uint, string> received_requests = new HashTable<uint, string> (direct_hash, direct_equal);
	GenericSet<uint> sent_requests = new GenericSet<uint> (direct_hash, direct_equal);

	ContactSubscriptions get_subscription_state (uint handle) {
		if (handle in received_requests) {
			return ContactSubscriptions (SubscriptionState.NO, SubscriptionState.ASK, received_requests[handle]);
		} else if (handle in sent_requests) {
			return ContactSubscriptions (SubscriptionState.ASK, SubscriptionState.YES, "");
		} else if (handle in handles) {
			return ContactSubscriptions (SubscriptionState.NO, SubscriptionState.NO, "");
		} else {
			return ContactSubscriptions (SubscriptionState.YES, SubscriptionState.YES, "");
		}
	}

	public void request_subscription (uint[] contacts, string message) {
		var changes = new HashTable<uint, ContactSubscriptions?> (direct_hash, direct_equal);
		var identifiers = new HashTable<uint, string> (direct_hash, direct_equal);
		var removals = new HashTable<uint, string> (direct_hash, direct_equal);
		foreach (var contact in contacts) {
			if (contact in handles) {
				int err;
				if (message == null || message == "")
					message = "No message";
				var friend_number = tox.friend_add (hex_string_to_bin (handles[contact]), message.data, out err);
				if (err != 0) {
					warning ("friend_add %s %d", handles[contact], err);
					continue;
				}

				var new_handle = friend_number + 1;
				sent_requests.add (new_handle);
				changes[new_handle] = ContactSubscriptions (SubscriptionState.ASK, SubscriptionState.YES, "");
				identifiers[new_handle] = handles[contact];

				removals[contact] = handles[contact];
				handles.remove (contact);
			} else
				warning ("address for handle %u unknown", contact);
		}

		save_tox_data ();
		contacts_changed_with_id (changes, identifiers, removals);
	}
	public void authorize_publication (uint[] contacts) {
		var changes = new HashTable<uint, ContactSubscriptions?> (direct_hash, direct_equal);
		var identifiers = new HashTable<uint, string> (direct_hash, direct_equal);
		var removals = new HashTable<uint, string> (direct_hash, direct_equal);

		foreach (var contact in contacts) {
			if (contact in handles) {
				var friend_number = tox.friend_add_norequest (hex_string_to_bin (handles[contact]), null);
				var new_handle = friend_number + 1;
				changes[new_handle] = ContactSubscriptions (SubscriptionState.YES, SubscriptionState.YES, "");
				identifiers[new_handle] = handles[contact];

				removals[contact] = handles[contact];
				received_requests.remove (contact);
				handles.remove (contact);
			}
		}

		save_tox_data ();
		contacts_changed_with_id (changes, identifiers, removals);
	}

	public void remove_contacts (uint[] contacts) {
		var removals = new HashTable<uint, string> (direct_hash, direct_equal);

		foreach (var handle in contacts) {
			var friend_number = handle - 1;
			var ident = bin_string_to_hex (tox.friend_get_public_key (friend_number, null));
			tox.friend_delete (friend_number, null);
			removals[handle] = ident;
		}

		save_tox_data ();
		contacts_changed_with_id (new HashTable<uint, ContactSubscriptions?> (direct_hash, direct_equal),
								  new HashTable<uint, string> (direct_hash, direct_equal),
								  removals);
	}

	public void unsubscribe (uint[] contacts) {
		remove_contacts (contacts);
	}
	public void unpublish (uint[] contacts) {
		remove_contacts (contacts);
	}
	public void download () {}

	void friend_request_callback(Tox tox, [CCode (array_length_cexpr = "TOX_PUBLIC_KEY_SIZE")] uint8[] public_key,
								 uint8[] message) {
		print("friend_request_callback\n");
		print("friend request from %s: %s\n",
			  bin_string_to_hex(public_key),
			  ((string)message).escape(""));

		var identifier = bin_string_to_hex (public_key);
		var handle = next_handle--;

		handles[handle] = identifier;
		received_requests[handle] = buffer_to_string (message);

		var changes = new HashTable<uint, ContactSubscriptions?> (direct_hash, direct_equal);
		var identifiers = new HashTable<uint, string> (direct_hash, direct_equal);

		changes[handle] = ContactSubscriptions (SubscriptionState.NO, SubscriptionState.ASK, received_requests[handle]);
		identifiers[handle] = identifier;

		contacts_changed_with_id (changes, identifiers, new HashTable<uint, string> (direct_hash, direct_equal));
	}

	public uint contact_list_state { get { return ContactListState.SUCCESS; } }
	public bool contact_list_persists { get { return true; } }
	public bool can_change_contact_list { get { return true; } }
	public bool request_uses_message { get { return true; } }
	public bool download_at_connection { get { return true; } }

	/* Connection.Interface.Aliasing implementation */
	public uint get_alias_flags () { return 0; }
	public string[] request_aliases (uint[] contacts) {
		var res = new string[contacts.length];
		for (var i = 0; i < contacts.length; i++) {
			var friend_number = contacts[i] - 1;
			res[i] = (string) tox.friend_get_name (friend_number, null);
		}
		return res;
	}
	public HashTable<uint, string> get_aliases (uint[] contacts) {
		var res = new HashTable<uint, string> (direct_hash, direct_equal);
		foreach (var contact in contacts) {
			if (contact == self_handle) {
				res[contact] = (string) tox.self_get_name ();
			} else {
				var friend_number = contact - 1;
				res[contact] = (string) tox.friend_get_name (friend_number, null);
			}
		}
		return res;
	}
	public void set_aliases (HashTable<uint, string> aliases) {
		if (self_handle in aliases) {
			var name = aliases[self_handle];
			tox.self_set_name (name.data, null);

			save_tox_data ();
			var changed = new AliasPair[] { AliasPair(self_handle, name) };
			aliases_changed (changed);
		}
	}

	void friend_name_callback (Tox tox, uint32 friend_number, uint8[] name) {
		var handle = friend_number + 1;
		var changed = new AliasPair[] { AliasPair(handle, buffer_to_string (name)) };
		aliases_changed (changed);
	}

	/* Connection.Interface.SimplePresence implementation */
	public void set_presence (string status, string status_message) {
		switch(status) {
		case "available":
			tox.self_set_status (Tox.UserStatus.NONE);
			break;
		case "away":
			tox.self_set_status (Tox.UserStatus.AWAY);
			break;
		case "busy":
			tox.self_set_status (Tox.UserStatus.BUSY);
			break;
		}
		tox.self_set_status_message (status_message.data, null);

		save_tox_data ();
		presences_changed (get_presences ({ uint.MAX }));
	}

	SimplePresence get_presence (uint handle) {
		if (handle == self_handle) {
			uint presence_type;
			if (tox.self_get_connection_status () == Tox.Connection.NONE)
				presence_type = PresenceType.OFFLINE;
			else switch (tox.self_get_status ()) {
				case Tox.UserStatus.NONE:
					presence_type = PresenceType.AVAILABLE;
					break;
				case Tox.UserStatus.AWAY:
					presence_type = PresenceType.AWAY;
					break;
				case Tox.UserStatus.BUSY:
					presence_type = PresenceType.BUSY;
					break;
				default:
					assert_not_reached ();
				}

			var message = (string) tox.self_get_status_message ();
			return SimplePresence (presence_type, "", message);
		}

		if (handle in received_requests || handle in sent_requests || handle in handles)
			return SimplePresence (PresenceType.UNKNOWN, "", "");

		/* tox friend numbers start at 0, but telepathy handles start at 1 */
		var friend_number = handle - 1;
		uint presence_type;
		if (tox.friend_get_connection_status (friend_number, null) == Tox.Connection.NONE)
			presence_type = PresenceType.OFFLINE;
		else switch (tox.friend_get_status (friend_number, null)) {
			case Tox.UserStatus.NONE:
				presence_type = PresenceType.AVAILABLE;
				break;
			case Tox.UserStatus.AWAY:
				presence_type = PresenceType.AWAY;
				break;
			case Tox.UserStatus.BUSY:
				presence_type = PresenceType.BUSY;
				break;
			default:
				assert_not_reached ();
			}

		var message = (string) tox.friend_get_status_message (friend_number, null);
		return SimplePresence (presence_type, "", message);
	}

	public HashTable<uint, SimplePresence?> get_presences (uint[] contacts) {
		var res = new HashTable<uint, SimplePresence?> (direct_hash, direct_equal);
		foreach (var id in contacts) {
			res[id] = get_presence (id);
		}
		return res;
	}

	void friend_status_callback (Tox tox, uint32 friend_number, Tox.UserStatus status) {
		debug("friend_status_callback %u", friend_number);
		uint presence_type;
		switch (status) {
		case Tox.UserStatus.NONE:
			presence_type = PresenceType.AVAILABLE;
			break;
		case Tox.UserStatus.AWAY:
			presence_type = PresenceType.AWAY;
			break;
		case Tox.UserStatus.BUSY:
			presence_type = PresenceType.BUSY;
			break;
		default:
			assert_not_reached ();
		}

		var message = (string) tox.friend_get_status_message (friend_number, null);
		var presence = SimplePresence (presence_type, "", message);

		var presences = new HashTable<uint, SimplePresence?> (direct_hash, direct_equal);
		presences[friend_number + 1] = presence;
		presences_changed (presences);
	}

	void friend_status_message_callback (Tox tox, uint32 friend_number, uint8[] message) {
		debug("friend_status_message_callback %u", friend_number);
		uint presence_type;
		switch (tox.friend_get_status (friend_number, null)) {
		case Tox.UserStatus.NONE:
			presence_type = PresenceType.AVAILABLE;
			break;
		case Tox.UserStatus.AWAY:
			presence_type = PresenceType.AWAY;
			break;
		case Tox.UserStatus.BUSY:
			presence_type = PresenceType.BUSY;
			break;
		default:
			assert_not_reached ();
		}

		var presence = SimplePresence (presence_type, "", buffer_to_string (message));

		var presences = new HashTable<uint, SimplePresence?> (direct_hash, direct_equal);
		presences[friend_number + 1] = presence;
		presences_changed (presences);
	}

	void friend_connection_status_callback (Tox tox, uint32 friend_number, Tox.Connection connection_status) {
		debug("friend_connection_status_callback %u", friend_number);
		var handle = friend_number + 1;
		if (handle in sent_requests)
			sent_requests.remove (handle);

		uint presence_type;
		if (connection_status == Tox.Connection.NONE)
			presence_type = PresenceType.OFFLINE;
		else switch (tox.friend_get_status (friend_number, null)) {
			case Tox.UserStatus.NONE:
				presence_type = PresenceType.AVAILABLE;
				break;
			case Tox.UserStatus.AWAY:
				presence_type = PresenceType.AWAY;
				break;
			case Tox.UserStatus.BUSY:
				presence_type = PresenceType.BUSY;
				break;
			default:
				assert_not_reached ();
			}
		var message = (string) tox.friend_get_status_message (friend_number, null);
		var presence = SimplePresence (presence_type, "", message);

		var presences = new HashTable<uint, SimplePresence?> (direct_hash, direct_equal);
		presences[handle] = presence;
		presences_changed (presences);
	}


	HashTable<string, SimpleStatusSpec?> _statuses;
	public HashTable<string, SimpleStatusSpec?> statuses {
		owned get {
			if (_statuses != null) return _statuses;

			_statuses = new HashTable<string, SimpleStatusSpec?> (str_hash, str_equal);
			_statuses["available"] = SimpleStatusSpec(PresenceType.AVAILABLE, true, true);
			_statuses["away"] = SimpleStatusSpec(PresenceType.AWAY, true, true);
			_statuses["busy"] = SimpleStatusSpec(PresenceType.BUSY, true, true);
			_statuses["offline"] = SimpleStatusSpec(PresenceType.OFFLINE, false, true);

			return _statuses;
		}
	}
	public uint maximum_status_message_length { get { return Tox.MAX_STATUS_MESSAGE_LENGTH; } }


	void friend_typing_callback (Tox tox, uint32 friend_number, bool is_typing) {
		var channel = chans[friend_number];

		if (channel == null) {
			debug("no channel for friend number %u", friend_number);
			return;
		}

		uint state;
		if (is_typing)
			state = Telepathy.ChannelChatState.COMPOSING;
		else
			state = Telepathy.ChannelChatState.INACTIVE;

		channel.chat_state_changed(channel.target_handle, state);

		debug("remote typing state changed: contact %u %u\n", friend_number, state);
	}

	void save_tox_data () {
		var savedata = tox.get_savedata();
		FileUtils.set_data(profile_filename, savedata);
		print("savedata written\n");
	}

	void run () {
		/* Bootstrap from the nodes defined above */
		int udp_err, tcp_err;
		for(int i=0; i<nodes.length; i++) {
			udp_err = tcp_err = -1;
			var bootstrap_pub_key = hex_string_to_bin(nodes[i].key);
			tox.bootstrap(nodes[i].address, nodes[i].port, bootstrap_pub_key, out udp_err);
			// If TCP relays are to be used, explicitly tell the core to initialize a few
			if(!enable_udp && i<10) tox.add_tcp_relay(nodes[i].address, nodes[i].port, bootstrap_pub_key, out tcp_err);
			print("bootstrap %s:%d (status: %d UDP, %d TCP)\n", nodes[i].address, nodes[i].port, udp_err, tcp_err);
		}
		//...

		SourceFunc tox_iterate = null;
		tox_iterate = () => {
			// will call the callback functions defined and registered
			tox.iterate();

			if (keep_connecting) {
				Timeout.add (tox.iteration_interval, tox_iterate);
			} else {
				print("unregistering connection\n");
				foreach (var id in obj_ids) {
					dbusconn.unregister_object(id);
				}
				obj_ids = {};

				Bus.unown_name (name_id);
				name_id = 0;

				save_tox_data ();

				tox = null;
			}
			return false;
		};

		tox_iterate ();
	}
}
