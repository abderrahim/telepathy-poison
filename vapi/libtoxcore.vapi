[CCode (cheader_filename="tox/tox.h")]
namespace Tox {
	public const int ADDRESS_SIZE;
	public const int PUBLIC_KEY_SIZE;
	public const int SECRET_KEY_SIZE;
	public const int MAX_STATUS_MESSAGE_LENGTH;
	public const int HASH_LENGTH;
	public const int FILE_ID_LENGTH;

	[CCode (cname = "TOX_USER_STATUS")]
	public enum UserStatus { NONE, AWAY, BUSY }

	[CCode (cname = "TOX_PROXY_TYPE", cprefix = "TOX_PROXY_TYPE_")]
	public enum ProxyType {NONE, HTTP, SOCKS5}
	[CCode (cname = "TOX_SAVEDATA_TYPE", cprefix = "TOX_SAVEDATA_TYPE_")]
	public enum SavedataType {NONE, TOX_SAVE, SECRET_KEY}

	[CCode (cname = "TOX_CONNECTION")]
	public enum Connection { NONE, TCP, UDP }

	[CCode (cname = "TOX_FILE_KIND")]
	public enum FileKind { DATA, AVATAR }

	[CCode (cname = "TOX_FILE_CONTROL")]
	public enum FileControl { RESUME, PAUSE, CANCEL }

	[CCode (cname="struct Tox_Options", lower_case_cprefix = "tox_options_")]
	[Compact]
	public class Options {
		public Options(out int error/*TOX_ERR_OPTIONS_NEW*/);

		public bool ipv6_enabled;
		public bool udp_enabled;
		public ProxyType proxy_type;
		public unowned string proxy_host;
		public uint16 proxy_port;

		public uint16 start_port;
		public uint16 end_port;
		public uint16 tcp_port;
		public SavedataType savedata_type;

		[CCode (cname = "savedata_data", array_length_cname = "savedata_length")]
		public unowned uint8[] savedata;
	}

	[CCode (cname = "Tox", lower_case_cprefix="tox_", free_function = "tox_kill", cheader_filename="tox/tox.h")]
	[Compact]
	public class Instance {
		public Instance (Options options, out int error);

		size_t get_savedata_size ();
		[CCode (cname = "tox_get_savedata")]
		void get_savedata_raw ([CCode (array_length = false)] uint8[] savedata);

		[CCode (cname = "_vala_tox_get_savedata")]
		public uint8[] get_savedata () {
			var result = new uint8[get_savedata_size()];
			get_savedata_raw(result);
			return result;
		}
	
		// lifecycle and event loop
		public bool bootstrap (string address, uint16 port, [CCode (array_length = false)] uint8[] public_key, out int /*TOX_ERR_BOOTSTRAP*/ error);
		public bool add_tcp_relay (string address, uint16 port, [CCode (array_length = false)] uint8[] public_key, out int /*TOX_ERR_BOOTSTRAP*/ error);

		public Connection self_get_connection_status ();
		[CCode (cname = "tox_self_connection_status_cb")]
		public delegate void SelfConnectionStatusCb (Instance tox, Connection connection_status);
		public void callback_self_connection_status (SelfConnectionStatusCb callback);

		public uint32 iteration_interval { [CCode (cname = "tox_iteration_interval")] get; }
		public void iterate ();

		// Internal client information
		[CCode (cname = "tox_self_get_address")]
		void self_get_address_raw ([CCode (array_length = false)] uint8[] address);
		[CCode (cname = "_vala_tox_self_get_address")]
		public uint8[] self_get_address () {
			var result = new uint8[ADDRESS_SIZE];
			self_get_address_raw(result);
			return result;
		}


		public void self_set_nospam (uint32 nospam);
		public uint32 self_get_nospam ();

		[CCode (cname = "tox_self_get_public_key")]
		void self_get_public_key_raw([CCode (array_length = false)] uint8[] public_key);
		[CCode (cname = "_vala_tox_self_get_public_key")]
		public uint8[] self_get_public_key () {
			var result = new uint8[PUBLIC_KEY_SIZE];
			self_get_public_key_raw(result);
			return result;
		}
	
		[CCode (cname = "tox_self_get_secret_key")]
		void self_get_secret_key_raw([CCode (array_length = false)] uint8[] secret_key);
		[CCode (cname = "_vala_tox_self_get_secret_key")]
		public uint8[] self_get_secret_key () {
			var result = new uint8[SECRET_KEY_SIZE];
			self_get_secret_key_raw(result);
			return result;
		}


		// User-visible client information
		public bool self_set_name(uint8[] name, out int/* TOX_ERR_SET_INFO * */error);

		size_t self_get_name_size ();
		[CCode (cname = "tox_self_get_name")]
		void self_get_name_raw([CCode (array_length = false)] uint8[] name);

		[CCode (cname = "_vala_tox_self_get_name")]
		public uint8[] self_get_name () {
			var result = new uint8[get_savedata_size()];
			self_get_name_raw(result);
			return result;
		}

		public bool self_set_status_message(uint8[] status_message, out int /*TOX_ERR_SET_INFO * */ error);
		size_t self_get_status_message_size();
		[CCode (cname = "tox_self_get_status_message")]
		void self_get_status_message_raw([CCode (array_length = false)] uint8[] status_message);

		[CCode (cname = "_vala_tox_self_get_status_message")]
		public uint8[] self_get_status_message () {
			var result = new uint8[self_get_status_message_size()];
			self_get_status_message_raw(result);
			return result;
		}



		public void self_set_status(UserStatus status);
		public UserStatus self_get_status();

		// Friend list management
		public uint32 friend_add([CCode (array_length = false)] uint8[] address, uint8[] message, out int /*TOX_ERR_FRIEND_ADD **/ error);
		public uint32 friend_add_norequest([CCode (array_length = false)] uint8[] public_key, out int /*TOX_ERR_FRIEND_ADD **/error);
		public bool friend_delete(uint32 friend_number, out int /*TOX_ERR_FRIEND_DELETE **/error);

		// Friend list queries
		public uint32 friend_by_public_key([CCode (array_length = false)] uint8[] public_key, out int /*TOX_ERR_FRIEND_BY_PUBLIC_KEY **/error);
		public bool friend_exists(uint32 friend_number);

		size_t self_get_friend_list_size();
		[CCode (cname = "tox_self_get_friend_list")]
		void self_get_friend_list_raw([CCode (array_length = false)] uint32[] friend_list);

		[CCode (cname = "_vala_tox_self_get_friend_list")]
		public uint32[] self_get_friend_list () {
			var result = new uint32[self_get_friend_list_size()];
			self_get_friend_list_raw(result);
			return result;
		}
	

		[CCode (cname = "tox_friend_get_public_key")]
		bool friend_get_public_key_raw(uint32 friend_number, [CCode (array_length = false)] uint8[] public_key, out int /*TOX_ERR_FRIEND_GET_PUBLIC_KEY **/error);

		[CCode (cname = "_vala_tox_friend_get_public_key")]
		public uint8[] friend_get_public_key (uint32 friend_number, out int /*TOX_ERR_FRIEND_GET_PUBLIC_KEY **/error) {
			var result = new uint8[PUBLIC_KEY_SIZE];
			friend_get_public_key_raw(friend_number, result, out error);
			return result;
		}
	

		public uint64 friend_get_last_online(uint32 friend_number, out int /*TOX_ERR_FRIEND_GET_LAST_ONLINE **/error);

		// Friend-specific state queries
		size_t friend_get_name_size(uint32 friend_number, out int /* TOX_ERR_FRIEND_QUERY **/error);
		[CCode (cname = "tox_friend_get_name")]
		bool friend_get_name_raw(uint32 friend_number, [CCode (array_length = false)] uint8[] name, out int /*TOX_ERR_FRIEND_QUERY **/error);
	
		[CCode (cname = "_vala_tox_friend_get_name")]
		public uint8[] friend_get_name (uint32 friend_number, out int /*TOX_ERR_FRIEND_QUERY*/ error) {
			int err;
			var size = friend_get_name_size(friend_number, out err);
			if (err != 0) {
				error = err;
				return null;
			}
			var result = new uint8[size];
			friend_get_name_raw(friend_number, result, out error);
			return result;
		}


		[CCode (cname = "tox_friend_name_cb")]
		public delegate void FriendNameCb (Instance tox, uint32 friend_number, uint8[] name);
		public void callback_friend_name(FriendNameCb callback);

		public size_t friend_get_status_message_size(uint32 friend_number, out int /*TOX_ERR_FRIEND_QUERY **/error);
		[CCode (cname = "tox_friend_get_status_message")]
		bool friend_get_status_message_raw(uint32 friend_number, [CCode (array_length = false)] uint8[] status_message, out int /*TOX_ERR_FRIEND_QUERY **/error);

		[CCode (cname = "_vala_tox_friend_get_status_message")]
		public uint8[] friend_get_status_message (uint32 friend_number, out int error) {
			int err;
			var size = friend_get_status_message_size(friend_number, out err);
			if (err != 0) {
				error = err;
				return null;
			}
			var result = new uint8[size];
			friend_get_status_message_raw(friend_number, result, out error);
			return result;
		}

		public delegate void FriendStatusMessageCb(Instance tox, uint32 friend_number, uint8[] message);
		public void callback_friend_status_message(FriendStatusMessageCb callback);

		public UserStatus friend_get_status(uint32 friend_number, out int /*TOX_ERR_FRIEND_QUERY **/error);
		[CCode (cname = "tox_friend_status_cb")]
		public delegate void FriendStatusCb(Instance tox, uint32 friend_number, UserStatus status);
		public void callback_friend_status(FriendStatusCb callback);

		public Connection friend_get_connection_status(uint32 friend_number, out int /*TOX_ERR_FRIEND_QUERY **/error);
		[CCode (cname = "tox_friend_connection_status_cb")]
		public delegate void FriendConnectionStatusCb(Instance tox, uint32 friend_number, Connection connection_status);
		public void callback_friend_connection_status(FriendConnectionStatusCb callback);

		public bool friend_get_typing(uint32 friend_number, out int/*TOX_ERR_FRIEND_QUERY **/error);
		[CCode (cname = "tox_friend_typing_cb")]
		public delegate void FriendTypingCb(Instance tox, uint32 friend_number, bool is_typing);
		public void callback_friend_typing(FriendTypingCb callback);

		// Sending private messages
		public bool self_set_typing(uint32 friend_number, bool typing, out int /*TOX_ERR_SET_TYPING **/error);
		public uint32 friend_send_message(uint32 friend_number, int /*TOX_MESSAGE_TYPE*/ type, uint8[] message, out int /*TOX_ERR_FRIEND_SEND_MESSAGE **/error);
		[CCode (cname = "tox_friend_read_receipt_cb")]
		public delegate void FriendReadReceiptCb(Instance tox, uint32 friend_number, uint32 message_id);
		public void callback_friend_read_receipt(FriendReadReceiptCb callback);

		// Receiving private messages and friend requests
		[CCode (cname = "tox_friend_request_cb")]
		public delegate void FriendRequestCb(Instance tox, [CCode (array_length=false, array_length_cexpr = "TOX_PUBLIC_KEY_SIZE")] uint8[] public_key, uint8[] message);
		public void callback_friend_request(FriendRequestCb callback);

		[CCode (cname = "tox_friend_message_cb")]
		public delegate void FriendMessageCb(Instance tox, uint32 friend_number, int /*TOX_MESSAGE_TYPE*/ type, uint8[] message);
		public void callback_friend_message(FriendMessageCb callback);

		/* file transmission */

		public static bool hash ([CCode (array_length_cexpr="TOX_HASH_LENGTH")] uint8[] hash, uint8[] data);

		public bool file_control (uint32 friend_number, uint32 file_number, FileControl control, out int /*TOX_ERR_FILE_CONTROL */ error);

		public bool file_seek(uint32 friend_number, uint32 file_number, uint64 position, out int /*TOX_ERR_FILE_SEEK */error);

		public bool file_get_file_id(uint32 friend_number, uint32 file_number, [CCode (array_length_cexpr="TOX_FILE_ID_LENGTH")] uint8[] file_id, out int /*TOX_ERR_FILE_GET */error);

		[CCode (cname = "tox_file_recv_control_cb")]
		public delegate void FileRecvControlCb(Tox.Instance tox, uint32 friend_number, uint32 file_number, FileControl control);
		public void callback_file_recv_control (FileRecvControlCb callback);

		/* file transmission: sending */

		public uint32 file_send (uint32 friend_number, uint32 kind, uint64 file_size, [CCode (array_length_cexpr="TOX_FILE_ID_LENGTH")] uint8[] file_id, uint8[] filename, out int /*TOX_ERR_FILE_SEND */error);

		public bool file_send_chunk (uint32 friend_number, uint32 file_number, uint64 position, uint8[]data, out int /*TOX_ERR_FILE_SEND_CHUNK */error);

		[CCode (cname="tox_file_chunk_request_cb")]
		public delegate void FileChunkRequestCb (uint32 friend_number, uint32 file_number, uint64 position, size_t length);
		public void callback_file_chunk_request (FileChunkRequestCb callback);

		/* File transmission: receiving */

		[CCode (cname="tox_file_recv_cb")]
		public delegate void FileRecvCb (uint32 friend_number, uint32 file_number, uint32 kind, uint64 file_size, uint8[] filename);
		public void callback_file_recv (FileRecvCb callback);

		[CCode (cname="tox_file_recv_chunk_cb")]
		public delegate void FileRecvChunkCb (uint32 friend_number, uint32 file_number, uint64 position, uint8[] data);
		public void callback_file_recv_chunk (FileRecvChunkCb callback);
	}

	/* toxencryptsave bindings */

	[CCode (cheader_filename="tox/toxencryptsave.h")]
	public const int PASS_ENCRYPTION_EXTRA_LENGTH;

	[CCode (cheader_filename="tox/toxencryptsave.h")]
	public bool pass_encrypt(uint8[] data, uint8[] passphrase, [CCode (array_length=false)] uint8[] out, out int /*TOX_ERR_ENCRYPTION*/ error);

	[CCode (cheader_filename="tox/toxencryptsave.h")]
	public bool pass_decrypt(uint8[] data, uint8[] passphrase, [CCode (array_length=false)] uint8[] out, out int /*TOX_ERR_DECRYPTION*/ error);

	[CCode (cheader_filename="tox/toxencryptsave.h")]
	public bool is_data_encrypted([CCode (array_length=false)] uint8[] data);
}
