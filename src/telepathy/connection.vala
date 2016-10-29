public enum Telepathy.HandleType { NONE, CONTACT, ROOM }

public enum Telepathy.ConnectionStatus {CONNECTED, CONNECTING, DISCONNECTED}
public enum Telepathy.ConnectionStatusReason {NONE, REQUESTED, NETWORK_ERROR}

[DBus (name = "org.freedesktop.Telepathy.Connection")]
public interface Telepathy.Connection : Object {
	public abstract void connect () throws IOError, Telepathy.Error;
	public abstract void disconnect () throws IOError, Telepathy.Error;

	public string[] get_interfaces_ () {
		return interfaces;
	}
	// TODO: GetProtocol
	public uint get_status_ () {
		debug("get_status");
		return status;
	}

	public abstract void hold_handles (uint handle_type, uint[] handles) throws IOError, Telepathy.Error;
	// TODO: InspectHandles
	public abstract void release_handles (uint handle_type, uint[] handles) throws IOError, Telepathy.Error;
	public abstract uint[] request_handles (uint handle_type, string[] identifiers) throws IOError, Telepathy.Error;

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
										 out HashTable<string, Variant> properties) throws IOError, Telepathy.Error;
	public abstract async void ensure_channel (HashTable<string, Variant> request,
										 out bool yours,
										 out ObjectPath channel,
										 out HashTable<string, Variant> properties) throws IOError, Telepathy.Error;

	public signal void new_channels (ChannelDetails[] channels);
	public signal void channel_closed (ObjectPath removed);
	
	public virtual RequestableChannel[] requestable_channel_classes { owned get { return {}; } }
	public virtual ChannelDetails[] channels { owned get { return {}; } }
}

[DBus (name = "org.freedesktop.Telepathy.Connection.Interface.Contacts")]
public interface Telepathy.ConnectionContacts : Object, Connection {
	public abstract string[] contact_attribute_interfaces { owned get; }

	public abstract void get_contact_attributes (uint[] handles, string[] interfaces, bool hold,
												 out HashTable<uint, HashTable<string, Variant>> attrs) throws IOError, Telepathy.Error;
	[DBus (name = "GetContactByID")]
	public abstract void get_contact_by_id (string identifier, string[] interfaces, out uint handle,
											out HashTable<string, Variant> attrs) throws IOError, Telepathy.Error;
}

public enum Telepathy.ContactListState { NONE, WAITING, FAILURE, SUCCESS }
public enum Telepathy.SubscriptionState { UNKNOWN, NO, REMOVED_REMOTELY, ASK, YES }

public struct Telepathy.ContactSubscriptions {
	public ContactSubscriptions (uint subscribe, uint publish, string publish_request) {
		this.subscribe = subscribe;
		this.publish = publish;
		this.publish_request = publish_request;
	}
	public uint subscribe;
	public uint publish;
	public string publish_request;
}

[DBus (name = "org.freedesktop.Telepathy.Connection.Interface.ContactList")]
public interface Telepathy.ConnectionContactList : Object, Connection {
	public abstract void get_contact_list_attributes(string[] interfaces, bool hold, out HashTable<uint, HashTable<string, Variant>> attrs) throws IOError, Telepathy.Error;

	public abstract void request_subscription (uint[] contacts, string message) throws IOError, Telepathy.Error;
	public abstract void authorize_publication (uint[] contacts) throws IOError, Telepathy.Error;
	public abstract void remove_contacts (uint[] contacts) throws IOError, Telepathy.Error;
	public abstract void unsubscribe (uint[] contacts) throws IOError, Telepathy.Error;
	public abstract void unpublish (uint[] contacts) throws IOError, Telepathy.Error;
	public abstract void download () throws IOError, Telepathy.Error;

	public signal void contact_list_state_changed (uint contact_list_state);
	[DBus (name = "ContactsChangedWithID")]
	public signal void contacts_changed_with_id (HashTable<uint, ContactSubscriptions?> changes, HashTable<uint, string> identifiers, HashTable<uint, string> removals);

	public abstract uint contact_list_state { get; }
	public abstract bool contact_list_persists { get; }
	public abstract bool can_change_contact_list { get; }
	public abstract bool request_uses_message { get; }
	public abstract bool download_at_connection { get; }

	public const string CONTACT_SUBSCRIBE = "org.freedesktop.Telepathy.Connection.Interface.ContactList/subscribe";
	public const string CONTACT_PUBLISH = "org.freedesktop.Telepathy.Connection.Interface.ContactList/publish";
	public const string CONTACT_PUBLISH_REQUEST = "org.freedesktop.Telepathy.Connection.Interface.ContactList/publish-request";
}

public struct Telepathy.AliasPair {
	public AliasPair (uint handle, string alias) {
		this.handle = handle;
		this.alias = alias;
	}
	public uint handle;
	public string alias;
}
[DBus (name = "org.freedesktop.Telepathy.Connection.Interface.Aliasing")]
public interface Telepathy.ConnectionAliasing : Object, Connection {
	public abstract uint get_alias_flags () throws IOError, Telepathy.Error;
	public abstract string[] request_aliases (uint[] contacts) throws IOError, Telepathy.Error;
	public abstract HashTable<uint, string> get_aliases (uint[] contacts) throws IOError, Telepathy.Error;
	public abstract void set_aliases (HashTable<uint, string> aliases) throws IOError, Telepathy.Error;

	public signal void aliases_changed (AliasPair[] aliases);
	public const string CONTACT_ALIAS = "org.freedesktop.Telepathy.Connection.Interface.Aliasing/alias";
}

public struct Telepathy.SimplePresence {
	public SimplePresence (uint type, string status, string? status_message) {
		this.type = type;
		this.status = status;
		this.status_message = status_message ?? "";
	}
	uint type; // PresenceType
	string status;
	string status_message;
}
public struct Telepathy.SimpleStatusSpec {
	public SimpleStatusSpec (uint type, bool may_set_on_self, bool can_have_message) {
		this.type = type;
		this.may_set_on_self = may_set_on_self;
		this.can_have_message = can_have_message;
	}
	uint type; // PresenceType
	bool may_set_on_self;
	bool can_have_message;
}


[DBus (name = "org.freedesktop.Telepathy.Connection.Interface.SimplePresence")]
public interface Telepathy.ConnectionSimplePresence : Object, Connection {
	public abstract void set_presence (string status, string status_message) throws IOError, Telepathy.Error;
	public abstract HashTable<uint, SimplePresence?> get_presences (uint[] contacts) throws IOError, Telepathy.Error;

	public signal void presences_changed (HashTable<uint, SimplePresence?> presence);

	public abstract HashTable<string, SimpleStatusSpec?> statuses { owned get; }
	public abstract uint maximum_status_message_length { get; }

	public const string CONTACT_PRESENCE = "org.freedesktop.Telepathy.Connection.Interface.SimplePresence/presence";

	public enum PresenceType {
		UNSET, OFFLINE, AVAILABLE, AWAY, EXTENDED_AWAY, HIDDEN, BUSY, UNKNOWN, ERROR
	}

}
