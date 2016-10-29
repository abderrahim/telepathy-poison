[Flags]
public enum Telepathy.ParamFlags {
	REQUIRED, REGISTER, HAS_DEFAULT, SECRET, DBUS_PROPERTY
}

public struct Telepathy.ParamSpec {
	public ParamSpec (string name, ParamFlags flags, string signature, Variant default_value) {
		this.name = name;
		this.flags = flags;
		this.signature = signature;
		this.default_value = default_value;
	}
	string name;
	ParamFlags flags;
	string signature;
	Variant default_value;
}

[DBus (name = "org.freedesktop.Telepathy.ConnectionManager")]
public interface Telepathy.ConnectionManager : Object {
	public abstract HashTable<string, HashTable<string, Variant>> protocols { owned get; }
	public abstract string[] interfaces { owned get; }

	public abstract string[] list_protocols () throws IOError, Telepathy.Error;
	public abstract ParamSpec[] get_parameters (string protocol) throws IOError, Telepathy.Error;
	public abstract async void request_connection (string protocol, HashTable<string, Variant> parameters, out string busname, out ObjectPath objpath) throws IOError, Telepathy.Error;

	public signal void new_connection (string busname, ObjectPath objpath, string protocol);
}
