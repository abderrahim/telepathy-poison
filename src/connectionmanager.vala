using Telepathy;

public class ConnectionManager : Object, Telepathy.ConnectionManager {
	internal Protocol proto = new Protocol ();
	public HashTable<string, HashTable<string, Variant>> protocols {
		owned get {
			var res = new HashTable<string, HashTable<string, Variant>> (str_hash, str_equal);

			var tox = new HashTable<string, Variant> (str_hash, str_equal);
			var PROTO = "org.freedesktop.Telepathy.Protocol";
			tox[PROTO + ".Interfaces"] = proto.interfaces;
			tox[PROTO + ".Parameters"] = proto.parameters;
			tox[PROTO + ".ConnectionInterfaces"] = proto.connection_interfaces;
			tox[PROTO + ".RequestableChannelClasses"] = proto.requestable_channel_classes;
			tox[PROTO + ".VCardField"] = proto.vcard_field;
			tox[PROTO + ".EnglishName"] = proto.english_name;
			tox[PROTO + ".Icon"] = proto.icon;
			tox[PROTO + ".AuthenticationTypes"] = proto.authentication_types;

			res["tox"] = tox;
			return res;
		}
	}
	public string[] interfaces { owned get { return {}; } }
	
	public string[] list_protocols () {
		return new string[] { "tox" };
	}

	public Telepathy.ParamSpec[] get_parameters (string protocol) requires (protocol == "tox") {
		return proto.parameters;
	}

	public async void request_connection (string protocol, HashTable<string, Variant> parameters, out string busname, out ObjectPath objpath) requires (protocol == "tox") {
		debug("request connection %s %s", protocol, (string) parameters["profile"]);

		var profile = (string) parameters["profile"];
		var password = ("password" in parameters) ? (string) parameters["password"] : null;
		var create = ("create profile" in parameters) ? (bool) parameters["create profile"] : false;
		var enable_udp = ("enable UDP" in parameters) ? (bool) parameters["enable UDP"] : true;

		var conn = new Connection (this, profile, password, create, enable_udp, request_connection.callback);
		yield;
		print("cont\n");

		busname = conn.busname;
		objpath = conn.objpath;
		new_connection(busname, objpath, protocol);
	}

	static void main () {
		var busname = "org.freedesktop.Telepathy.ConnectionManager.poison";
		var objpath = "/org/freedesktop/Telepathy/ConnectionManager/poison";
		var proto_objpath = objpath + "/tox";
		Bus.own_name (BusType.SESSION,
					  busname,
					  BusNameOwnerFlags.NONE,
					  (conn) => {
						  var conman = new ConnectionManager ();
						  conn.register_object<Telepathy.ConnectionManager>(objpath, conman);
						  conn.register_object<Telepathy.Protocol>(proto_objpath, conman.proto);
					  },
					  () => {},
					  () => warning("could not acquire name %s", busname));

		new MainLoop ().run ();
	}
}
