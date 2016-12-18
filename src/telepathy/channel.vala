[DBus (name = "org.freedesktop.Telepathy.Channel")]
public interface Telepathy.Channel : Object {
	public string[] get_interfaces_ () { return interfaces; }
	public abstract void close () throws IOError, Telepathy.Error;

	public signal void closed ();

	public abstract string channel_type { owned get; }
	public abstract string[] interfaces { owned get; }

	public abstract uint target_handle_type { owned get; }
	public abstract uint target_handle { owned get; }
	[DBus (name = "TargetID")]
	public abstract string target_id { owned get; }

	public abstract bool requested { owned get; }
	public abstract uint initiator_handle { owned get; }
	[DBus (name = "InitiatorID")]
	public abstract string initiator_id { owned get; }
}

public enum Telepathy.MessageType { NORMAL, ACTION, NOTICE, AUTO_REPLY, DELIVERY_REPORT }

[DBus (name = "org.freedesktop.Telepathy.Channel.Type.Text")]
public interface Telepathy.TextChannel : Channel {
	public abstract void acknowledge_pending_messages (uint[] ids) throws IOError, Telepathy.Error;
}

[DBus (name = "org.freedesktop.Telepathy.Channel.Interface.Messages")]
public interface Telepathy.MessagesChannel : Channel {
	public abstract string send_message (HashTable<string, Variant>[] message, uint flags) throws IOError, Telepathy.Error;

	public signal void message_sent (HashTable<string, Variant>[] content, uint flags, string message_token);
	public signal void pending_messages_removed (uint[] message_ids);
	public signal void message_received (HashTable<string, Variant>[] message);

	public abstract string[] supported_content_types { owned get; }
	public abstract uint[] message_types { owned get; }
	public abstract uint message_part_support_flags { owned get; }
	public abstract HashTable<string, Variant>[,] pending_messages { owned get; }
	public abstract uint delivery_reporting_support { owned get; }
}

public enum Telepathy.ChannelChatState { GONE, INACTIVE, ACTIVE, PAUSED, COMPOSING }

[DBus (name = "org.freedesktop.Telepathy.Channel.Interface.ChatState")]
public interface Telepathy.ChatStateChannel: Channel {
	public abstract void set_chat_state (uint state) throws IOError, Telepathy.Error;
	public signal void chat_state_changed (uint contact, uint state);
}

[DBus (name = "org.freedesktop.Telepathy.Channel.Type.ServerAuthentication")]
public interface Telepathy.ServerAuthenticationChannel: Channel {
	public abstract string authentication_method { owned get; }
}

[DBus (name = "org.freedesktop.Telepathy.Channel.Interface.SASLAuthentication")]
public interface Telepathy.SASLAuthenticationChannel: Channel {
	public abstract void start_mechanism (string mechanism) throws IOError, Telepathy.Error;
	public abstract void start_mechanism_with_data (string mechanism, uint8[] initial_data) throws IOError, Telepathy.Error;
	public abstract void respond (uint8[] response_data) throws IOError, Telepathy.Error;
	[DBus (name = "AcceptSASL")]
	public abstract void accept_sasl () throws IOError, Telepathy.Error;
	[DBus (name = "AbortSASL")]
	public abstract void abort_sasl (uint reason, string debug_message) throws IOError, Telepathy.Error;

	[DBus (name = "SASLStatusChanged")]
	public signal void sasl_status_changed (uint status, string reason, HashTable<string, Variant> details);
	public signal void new_challenge (uint8[] challenge_data);

	public abstract string[] available_mechanisms { owned get; }
	public abstract bool has_initial_data { owned get; }
	public abstract bool can_try_again { owned get; }
	public abstract SASLStatus sasl_status { owned get; }
	public abstract string sasl_error { owned get; }
	public abstract HashTable<string, Variant> sasl_error_details { owned get; }
	public abstract string authorization_identity { owned get; }
	public abstract string default_username { owned get; }
	public abstract string default_realm { owned get; }
	public abstract bool may_save_response { owned get; }
}

public enum Telepathy.SASLStatus {
	NOT_STARTED,
	IN_PROGRESS,
	SERVER_SUCCEEDED,
	CLIENT_ACCEPTED,
	SUCCEEDED,
	SERVER_FAILED,
	CLIENT_FAILED
}
