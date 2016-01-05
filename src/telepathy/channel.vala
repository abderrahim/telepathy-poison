[DBus (name = "org.freedesktop.Telepathy.Channel")]
public interface Telepathy.Channel : Object {
	public string[] get_interfaces_ () { return interfaces; }
	public abstract void close () throws IOError;

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
	public abstract void acknowledge_pending_messages (uint[] ids) throws IOError;
}

[DBus (name = "org.freedesktop.Telepathy.Channel.Interface.Messages")]
public interface Telepathy.MessagesChannel : Channel {
	public abstract string send_message (HashTable<string, Variant>[] message, uint flags) throws IOError;

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
	public abstract void set_chat_state (uint state) throws IOError;
	public signal void chat_state_changed (uint contact, uint state);
}
