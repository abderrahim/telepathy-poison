
namespace Util {
	uint8 hex_char_to_bin(char ch) {
		if(ch >= '0' && ch <= '9') return ch - '0';
		if(ch >= 'a' && ch <= 'f') return ch - 'a' + 10;
		if(ch >= 'A' && ch <= 'F') return ch - 'A' + 10;
		critical("%c", ch);
		return_val_if_reached(0);
	}

	uint8[] hex_string_to_bin(string input) {
		var output = new uint8[input.length/2];
		for (var i = 0; i < output.length; i++) {
			output[i] = hex_char_to_bin(input[2*i]) * 16 + hex_char_to_bin(input[2*i+1]);
		}
		return output;
	}

	string byte_to_hex_chars(uint8 byte) {
		var ch1 = byte / 16;
		var ch2 = byte % 16;
		ch1 += (ch1 < 10) ? '0' : 'A' - 10;
		ch2 += (ch2 < 10) ? '0' : 'A' - 10;
		return "%c%c".printf(ch1, ch2);
	}

	string bin_string_to_hex(uint8[] bin) {
		var output = new StringBuilder.sized(2*bin.length);
		for (var i = 0; i < bin.length; i++) {
			output.append(byte_to_hex_chars(bin[i]));
		}
		return output.str;
	}
}
