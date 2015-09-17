public enum Telepathy.HandleType { NONE, CONTACT, ROOM }

public enum Telepathy.ConnectionStatus {CONNECTED, CONNECTING, DISCONNECTED}
public enum Telepathy.ConnectionStatusReason {NONE, REQUESTED, NETWORK_ERROR}

[DBus (name = "org.freedesktop.Telepathy.Connection")]
public interface Telepathy.Connection : Object {
	public abstract void connect () throws IOError;
	public abstract void disconnect () throws IOError;

	public string[] get_interfaces_ () {
		return interfaces;
	}
	// TODO: GetProtocol
	public uint get_status_ () {
		debug("get_status");
		return status;
	}

	public abstract void hold_handles (uint handle_type, uint[] handles) throws IOError;
	// TODO: InspectHandles
	public abstract void release_handles (uint handle_type, uint[] handles) throws IOError;
	public abstract uint[] request_handles (uint handle_type, string[] identifiers) throws IOError;

	public void add_client_interest (string[] tokens) {}
	public void remove_client_interest (string[] tokens) {}

	/* Signals */
	public signal void self_contact_changed (uint self_handle, string self_id);
	// TODO: ConnectionError
	public signal void status_changed (uint status, uint reason);

	/* Properties */
	public abstract string[] interfaces { owned get; }
	public abstract uint self_handle { get; }
	[DBus (name = "SelfID")]
	public abstract string self_id { owned get; }
	public abstract uint status { get; }
	public abstract bool has_immortal_handles { get; }

	public const string CONTACT_ID = "org.freedesktop.Telepathy.Connection/contact-id";
}
	
public struct Telepathy.RequestableChannel {
	public HashTable<string, Variant> fixed_properties;
	public string[] allowed_properties;
}
public struct Telepathy.ChannelDetails {
	public ChannelDetails (ObjectPath chan, HashTable<string, Variant> props) {
		channel = chan;
		properties = props;
	}
	public ObjectPath channel;
	public HashTable<string, Variant> properties;
}

[DBus (name = "org.freedesktop.Telepathy.Connection.Interface.Requests")]
public interface Telepathy.ConnectionRequests : Object, Connection {
	public abstract void create_channel (HashTable<string, Variant> request,
										 out ObjectPath channel,
										 out HashTable<string, Variant> properties) throws IOError;
	public abstract async void ensure_channel (HashTable<string, Variant> request,
										 out bool yours,
										 out ObjectPath channel,
										 out HashTable<string, Variant> properties) throws IOError;

	public signal void new_channels (ChannelDetails[] channels);
	public signal void channel_closed (ObjectPath removed);
	
	public virtual RequestableChannel[] requestable_channel_classes { owned get { return {}; } }
	public virtual ChannelDetails[] channels { owned get { return {}; } }
}

[DBus (name = "org.freedesktop.Telepathy.Connection.Interface.Contacts")]
public interface Telepathy.ConnectionContacts : Object, Connection {
	public abstract string[] contact_attribute_interfaces { owned get; }

	public abstract void get_contact_attributes (uint[] handles, string[] interfaces, bool hold,
												 out HashTable<uint, HashTable<string, Variant>> attrs) throws IOError;
	[DBus (name = "GetContactByID")]
	public abstract void get_contact_by_id (string identifier, string[] interfaces, out uint handle,
											out HashTable<string, Variant> attrs) throws IOError;
}

public enum Telepathy.ContactListState { NONE, WAITING, FAILURE, SUCCESS }

[DBus (name = "org.freedesktop.Telepathy.Connection.Interface.ContactList")]
public interface Telepathy.ConnectionContactList : Object, Connection {

	public const string CONTACT_SUBSCRIBE = "org.freedesktop.Telepathy.Connection.Interface.ContactList/subscribe";
	public const string CONTACT_PUBLISH = "org.freedesktop.Telepathy.Connection.Interface.ContactList/publish";
	public const string CONTACT_PUBLISH_REQUEST = "org.freedesktop.Telepathy.Connection.Interface.ContactList/publish-request";

	public enum SubscriptionState {UNKNOWN, NO, REMOVED_REMOTELY, ASK, YES}
	
	public abstract void get_contact_list_attributes(string[] interfaces, bool hold, out HashTable<uint, HashTable<string, Variant>> attrs) throws IOError;
	public abstract uint contact_list_state { get; protected set; }
}

