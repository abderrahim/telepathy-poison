public struct Telepathy.ParamSpec {
	string name;
	uint flags;
	string signature;
	Variant default_value;
}

[DBus (name = "org.freedesktop.Telepathy.ConnectionManager")]
public interface Telepathy.ConnectionManager : Object {
	public abstract string[] interfaces { owned get; }

	public abstract string[] list_protocols () throws IOError;
	public abstract ParamSpec[] get_parameters (string protocol) throws IOError;
	public abstract async void request_connection (string protocol, HashTable<string, Variant> parameters, out string busname, out ObjectPath objpath) throws IOError;

	public signal void new_connection (string busname, ObjectPath objpath, string protocol);
}
