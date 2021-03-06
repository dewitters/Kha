package kha;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesData;
import js.Browser;

using StringTools;

class LocalStorageFile extends StorageFile {
	var name: String;

	public function new(name: String) {
		this.name = name;
	}

	override public function read(): Blob {
		var storage = Browser.getLocalStorage();
		if (storage == null)
			return null;
		var value: String = storage.getItem(System.title + "_" + name);
		if (value == null)
			return null;
		else
			return Blob.fromBytes(decode(value));
	}

	override public function write(data: Blob): Void {
		var storage = Browser.getLocalStorage();
		if (storage == null)
			return;
		storage.setItem(System.title + "_" + name, encode(data.bytes.getData()));
	}

	/**
	 * Encodes byte array to yEnc string (from SASStore).
	 * @param  {Array}  source Byte array to convert to yEnc.
	 * @return {string}        Resulting yEnc string from byte array.
	 */
	static function encode(source: BytesData): String {
		var reserved = [0, 10, 13, 61];
		var output = "";
		var converted, ele;
		var bytes = new js.lib.Uint8Array(source);
		for (i in 0...bytes.length) {
			ele = bytes[i];
			converted = (ele + 42) % 256;
			if (!Lambda.has(reserved, converted)) {
				output += String.fromCharCode(converted);
			}
			else {
				converted = (converted + 64) % 256;
				output += "=" + String.fromCharCode(converted);
			}
		}
		return output;
	}

	/**
	 * Decodes yEnc string to byte array (from SASStore).
	 * @param  {string} source yEnc string to decode to byte array.
	 * @return {Array}         Resulting byte array from yEnc string.
	 */
	static function decode(source: String): Bytes {
		var output = new BytesBuffer();
		var ck = false;
		var c;
		for (i in 0...source.length) {
			c = source.fastCodeAt(i);
			// ignore newlines
			if (c == 13 || c == 10) {
				continue;
			}
			// if we're an "=" and we haven't been flagged, set flag
			if (c == 61 && !ck) {
				ck = true;
				continue;
			}
			if (ck) {
				ck = false;
				c = c - 64;
			}
			if (c < 42 && c > 0) {
				output.addByte(c + 214);
			}
			else {
				output.addByte(c - 42);
			}
		}
		return output.getBytes();
	}
}

class Storage {
	public static function namedFile(name: String): StorageFile {
		return new LocalStorageFile(name);
	}

	public static function defaultFile(): StorageFile {
		return namedFile("default.kha");
	}
}
