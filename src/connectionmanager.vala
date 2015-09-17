using Telepathy;

public class ConnectionManager : Object, Telepathy.ConnectionManager {
	public HashTable<string, HashTable<string,Variant>> protocols = new HashTable<string, HashTable<string,Variant>> (str_hash, str_equal);
	public string[] interfaces { owned get { return {}; } }
	
	public string[] list_protocols () {
		debug("list_protocols");
		return new string[] { "tox" };
	}

	public Telepathy.ParamSpec[] get_parameters (string protocol) requires (protocol == "tox") {
		debug("get_parameters");
		return new Telepathy.ParamSpec[] {};
	}

	public async void request_connection (string protocol, HashTable<string, Variant> parameters, out string busname, out ObjectPath objpath) requires (protocol == "tox") {
		debug("request connection %s", protocol);
		/*var toxidv = parameters["ToxID"];
		if (toxidv == null)
			return;

			var toxid = (string) toxidv;*/
		// || toxid.length != 

		var conn = new Connection (this, request_connection.callback);
		yield;
		print("cont\n");

		busname = conn.busname;
		objpath = conn.objpath;
		new_connection(busname, objpath, protocol);
	}

	static void main () {
		var busname = "org.freedesktop.Telepathy.ConnectionManager.poison";
		var objpath = "/org/freedesktop/Telepathy/ConnectionManager/poison";
		Bus.own_name (BusType.SESSION,
					  busname,
					  BusNameOwnerFlags.NONE,
					  (conn) => conn.register_object<Telepathy.ConnectionManager>(objpath, new ConnectionManager ()),
					  () => {},
					  () => warning("could not acquire name %s", busname));

		new MainLoop ().run ();
	}
}
