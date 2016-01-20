using Telepathy;
using Util;

public class TextChannel : Object, Telepathy.Channel, Telepathy.TextChannel, Telepathy.MessagesChannel, Telepathy.ChatStateChannel {
	unowned Tox tox;
	uint32 friend_number;

	public TextChannel (Tox tox, uint32 friend_number, bool requested) {
		this.tox = tox;
		this.friend_number = friend_number;

		_target_handle_type = HandleType.CONTACT;
		_target_handle = friend_number + 1;
		_target_id = bin_string_to_hex (tox.friend_get_public_key (friend_number, null));
		_initiator_handle = _target_handle;
		_initiator_id = _target_id;
		_requested = requested;
	}

	public const string IFACE_CHANNEL = "org.freedesktop.Telepathy.Channel";
	public const string IFACE_CHANNEL_MESSAGES = "org.freedesktop.Telepathy.Channel.Interface.Messages";
	
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

		/* Properties from Channel.Interface.Messages */
		properties[IFACE_CHANNEL_MESSAGES + ".SupportedContentTypes"] = supported_content_types;
		properties[IFACE_CHANNEL_MESSAGES + ".MessageTypes"] = message_types;
		properties[IFACE_CHANNEL_MESSAGES + ".MessagePartSupportFlags"] = message_part_support_flags;
		properties[IFACE_CHANNEL_MESSAGES + ".DeliveryReportingSupport"] = delivery_reporting_support;

		return properties;
	}
		

	/* DBus name and object registration */
	DBusConnection dbusconn;
	internal ObjectPath objpath {get; private set;}
	uint[] obj_ids = {};

	internal async ObjectPath register (DBusConnection conn, ObjectPath parent) {
		debug("register %s\n", parent);

		if (objpath != null) return objpath;

		objpath = new ObjectPath("%s/%s".printf (parent, target_id));
		dbusconn = conn;

		obj_ids = {
			conn.register_object<Telepathy.Channel> (objpath, this),
			conn.register_object<Telepathy.TextChannel> (objpath, this),
			conn.register_object<Telepathy.MessagesChannel> (objpath, this),
			conn.register_object<Telepathy.ChatStateChannel> (objpath, this),
		};

		return objpath;
	}

	public void close () throws IOError {
		foreach (var obj_id in obj_ids) {
			dbusconn.unregister_object (obj_id);
		}
		obj_ids = {};
		closed ();
	}

	public string channel_type { owned get { return "org.freedesktop.Telepathy.Channel.Type.Text"; } }
	public string[] interfaces { owned get { return {
		"org.freedesktop.Telepathy.Channel.Interface.Messages",
		"org.freedesktop.Telepathy.Channel.Interface.ChatState"
	}; } }
	uint _target_handle;
	public uint target_handle { get { return _target_handle; } }
	string _target_id;
	public string target_id { owned get { return _target_id; } }
	uint _target_handle_type;
	public uint target_handle_type { get {return _target_handle_type; } }
	bool _requested;
	public bool requested { get { return _requested; } }
	uint _initiator_handle;
	public uint initiator_handle { get { return _initiator_handle; } }
	string _initiator_id;
	public string initiator_id { owned get { return _initiator_id; } }

	public void acknowledge_pending_messages (uint[] ids) {
		debug("acknowledge_pending_messages");
		foreach(var id in ids) {
			_pending_messages.remove(id);
		}
		pending_messages_removed(ids);
	}

	public string send_message (HashTable<string, Variant>[] message, uint flags) {
		debug("send_message %u", flags);

		var message_type = ("message-type" in message[0]) ?
			(uint) message[0]["message-type"] : MessageType.NORMAL;
		var content = (string) message[1]["content"];

		var token = tox.friend_send_message (friend_number, (int) message_type, content.data, null).to_string();

		var msg = new HashTable<string, Variant>[2];

		msg[0] = new HashTable<string, Variant> (str_hash, str_equal);
		msg[0]["message-token"] = token;
		msg[0]["message-sent"] = (int64) time_t ();
		//msg[0]["message-sender"] = self_handle;
		//msg[0]["message-sender-id"] = self_id;
		msg[0]["message-type"] = message_type;

		msg[1] = new HashTable<string, Variant> (str_hash, str_equal);
		msg[1]["content-type"] = "text/plain";
		msg[1]["content"] = content;

		Idle.add (() => {
			for(var i = 0; i < msg.length; i++) {
				print("%p\n", msg[i]);
				msg[i].foreach((k, v) => {
					print("%s %s\n", k, v.print(true));
				});
			}
			message_sent(msg, 0, token);
			return false;
		});

		return token;
	}

	struct Message {
		HashTable<string, Variant> header;
		HashTable<string, Variant> content;
	}

	uint next_msg_id = 0;

	internal void receive_message (int type, uint8[] message) {
		var msg = new HashTable<string, Variant>[2];
		var msg_id = next_msg_id++;

		msg[0] = new HashTable<string, Variant> (str_hash, str_equal);
		//msg[0]["message-token"]
		msg[0]["message-received"] = (int64) time_t ();
		msg[0]["message-sender"] = target_handle;
		msg[0]["message-sender-id"] = target_id;
		msg[0]["message-type"] = type;
		msg[0]["pending-message-id"] = msg_id;

		//message-token (s - Protocol_Message_Token)
		//message-sent (x - Unix_Timestamp64)
		//message-received (x - Unix_Timestamp64)
		//message-sender (u - Contact_Handle)
		//message-sender-id (s)
		//sender-nickname (s)
		//message-type (u - Channel_Text_Message_Type)
		//supersedes (s – Protocol_Message_Token)
		//original-message-sent (x - Unix_Timestamp64)
		//original-message-received (x - Unix_Timestamp64)
		//pending-message-id (u - Message_ID)
		//interface (s - DBus_Interface)
		//scrollback (b)
		//rescued (b)

		msg[1] = new HashTable<string, Variant> (str_hash, str_equal);
		msg[1]["content-type"] = "text/plain";
		msg[1]["content"] = buffer_to_string (message);

		_pending_messages[msg_id] = Message() { header = msg[0], content = msg[1] };

		message_received (msg);

	}

	public string[] supported_content_types { owned get { return {"text/plain"}; } }
	public uint[] message_types {
		owned get {
			return { MessageType.NORMAL, MessageType.ACTION };
		}
	}
	public uint message_part_support_flags { owned get { return 0; } }
	HashTable<uint, Message?> _pending_messages = new HashTable<uint, Message?>(direct_hash, direct_equal);
	public HashTable<string, Variant>[,] pending_messages {
		owned get {
			var res = new HashTable<string, Variant>[_pending_messages.length, 2];
			var i = 0;
			_pending_messages.foreach((k, v) => {
					res[i, 0] = v.header;
					res[i, 1] = v.content;
					i++;
			});
			return res;
		}
	}
	public uint delivery_reporting_support { owned get { return 0; } }

	public void set_chat_state (uint state) {
		int err;
		if (state == Telepathy.ChannelChatState.COMPOSING)
			tox.self_set_typing(friend_number, true, out err);
		else
			tox.self_set_typing(friend_number, false, out err);

		debug("local typing state changed: contact %u %u\n", friend_number, state);
	}
}
