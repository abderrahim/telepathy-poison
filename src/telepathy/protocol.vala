[DBus (name = "org.freedesktop.Telepathy.Protocol")]
public interface Telepathy.Protocol : Object {
	public abstract string identify_account (HashTable<string, Variant> parameters) throws IOError, Telepathy.Error;
	public abstract string normalize_contact (string contact_id) throws IOError, Telepathy.Error;

	public abstract string[] interfaces { owned get; }
	public abstract ParamSpec[] parameters { owned get; }
	public abstract string[] connection_interfaces { owned get; }
	public abstract RequestableChannel[] requestable_channel_classes { owned get; }
	[DBus (name = "VCardField")]
	public abstract string vcard_field { owned get; }
	public abstract string english_name { owned get; }
	public abstract string icon { owned get; }
	public abstract string[] authentication_types { owned get; }
}
