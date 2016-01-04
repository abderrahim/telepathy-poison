using Telepathy;

public class Protocol : Object, Telepathy.Protocol {
	public string identify_account (HashTable<string, Variant> parameters) {
		return (string) parameters["account"];
	}
	public string normalize_contact (string contact_id) {
		return contact_id;
	}

	public string[] interfaces { owned get { return {}; } }
	public Telepathy.ParamSpec[] parameters {
		owned get {
			return new Telepathy.ParamSpec[] {
				Telepathy.ParamSpec ("profile", Telepathy.ParamFlags.REQUIRED, "s", ""),
				Telepathy.ParamSpec ("password", Telepathy.ParamFlags.REGISTER | Telepathy.ParamFlags.SECRET, "s", ""),
				Telepathy.ParamSpec ("create profile", Telepathy.ParamFlags.HAS_DEFAULT, "b", false),
				Telepathy.ParamSpec ("enable UDP", Telepathy.ParamFlags.HAS_DEFAULT, "b", true),
			};
		}
	}
	public string[] connection_interfaces {
		owned get {
			return {"org.freedesktop.Telepathy.Connection.Interface.Contacts",
					"org.freedesktop.Telepathy.Connection.Interface.Requests",
					"org.freedesktop.Telepathy.Connection.Interface.Aliasing",
					"org.freedesktop.Telepathy.Connection.Interface.ContactList",
					"org.freedesktop.Telepathy.Connection.Interface.SimplePresence",
					};
		}
	}

	RequestableChannel[] requestable_channels = null;
	public RequestableChannel[] requestable_channel_classes {
		owned get {
			if (requestable_channels == null) {
				var fixed_properties = new HashTable<string, Variant> (str_hash, str_equal);
				fixed_properties["org.freedesktop.Telepathy.Channel.ChannelType"] = "org.freedesktop.Telepathy.Channel.Type.Text";
				fixed_properties["org.freedesktop.Telepathy.Channel.TargetHandleType"] = HandleType.CONTACT;
				var allowed_properties = new string[] {"org.freedesktop.Telepathy.Channel.TargetHandle", "org.freedesktop.Telepathy.Channel.TargetID"};

				requestable_channels = { RequestableChannel () { fixed_properties = fixed_properties, allowed_properties = allowed_properties}};
			}
			return requestable_channels;
		}
	}

	public string vcard_field { owned get { return "x-tox"; } }
	public string english_name { owned get { return "Tox"; } }
	public string icon { owned get { return "im-tox"; } }
	public string[] authentication_types { owned get { return {}; } }
}
