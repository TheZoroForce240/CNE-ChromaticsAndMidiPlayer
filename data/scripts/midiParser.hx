import sys.FileSystem;
import funkin.backend.system.Conductor;
import openfl.Assets;
import flixel.FlxSprite;
import openfl.utils.ByteArray;




public function loadMidiFromAssets(path) {
	if (!Assets.exists(path)) return null;

	var bytes = Assets.getBytes(path);
	if (bytes != null) {
		var midi = generateEmptyMidiFile();
		midi.bytes = ByteArray.fromBytes(bytes);
		midi = parseMidi(midi);
		
		return midi;
	}
	return null;
}
public function loadMidiFromPath(path) {

	if (!FileSystem.exists(path))
		return null;

	var bytes = ByteArray.fromFile(path);
	if (bytes != null) {
		var midi = generateEmptyMidiFile();
		midi.bytes = bytes;
		midi = parseMidi(midi);
		
		return midi;
	}
	return null;
}
public function loadMidiFromBytes(bytes) {
	if (bytes == null) return;

	var midi = generateEmptyMidiFile();
	midi.bytes = ByteArray.fromBytes(bytes);
	midi = parseMidi(midi);
	return midi;
}

public function convertTicksToMilliseconds(ticks, bpm, ppq) {
	return (60000 / (bpm * ppq)) * ticks;
}
public function convertMillisecondsToTicks(milliseconds, bpm, ppq) {
	return milliseconds / (60000 / (bpm * ppq));
}
public function getNoteOctave(note) {
	return Math.floor(num / 12) - 1;
}
public function getNoteKey(note) {
	return num%12;
}

function generateEmptyMidiFile() {
	return {
		tracks: [],
		bytes: null,
		position: 0,
		length: 0,
		ticksPerQuarterNote: 120,
		format: 0,
		trackLength: 0,
	};
}
function generateEmptyMidiTrack() {
	return {
		events: [],
		length: 0,
	};
}
function generateEmptyMidiEvent() {
	return {
		type: 0,
		channel: 0,
		status: 0,
		delta: 0,
		time: 0,
		length: 0,
		param1: 0,
		param2: 0
	};
}

//big credits to https://github.com/davidluzgouveia/midi-parser for making it easier to understand

function parseMidi(midi) {

	midi.bytes.endian = 0; //big endian

	if (midi.bytes.readUTFBytes(4) != "MThd") {
		trace("bad header");
		return;
	}

	if (midi.bytes.readInt() != 6) {
		trace("die");
		return;
	}
	
	midi.format = midi.bytes.readShort();
	midi.trackLength = midi.bytes.readShort();
	midi.ticksPerQuarterNote = midi.bytes.readShort();

	for (i in 0...midi.trackLength) {
		curTrack = generateEmptyMidiTrack();
		curTrack = parseTrack(curTrack, midi);
		midi.tracks.push(curTrack);
	}

	return midi;
}

function parseTrack(track, midi) {

	if (midi.bytes.readUTFBytes(4) != "MTrk") {
		trace("bad track");
		return track;
	}

	track.length = midi.bytes.readInt();
	var end = midi.bytes.position + track.length;

	var time:Int = 0;
	var status:Int = 0;

	while (midi.bytes.position < end) {
		var deltaTime = readVariableLengthInt(midi.bytes);
		time += deltaTime;

		status = midi.bytes.readByte();
		
		switch (status) {

			case 0xFF | -1: //meta
				status = 0xFF; //should be 0xFF but it gets turned into -1 for some reason
				var type = midi.bytes.readByte();
				

				//trace("meta");
				//trace(StringTools.hex(type));

				if (type >= 0x01 && type <= 0x0F) {
                    var text = midi.bytes.readUTFBytes(readVariableLengthInt(midi.bytes)); //text
				} else {
					//other meta events
					var len = readVariableLengthInt(midi.bytes);
					midi.bytes.position += len;
				}
			case 0xF7: //sys ex cont
				trace("sys ex cont");
				//not implemented yet

			case 0xF0: //sys ex
				trace("sys ex");
				//not implemented yet

			case 0x00: //do nothing
				//break;
			default:

				//trace("midi event");
				var event = generateEmptyMidiEvent();
				event.type = (status & 0xF0);
				event.channel = ((status & 0x0F) + 1);
				event.delta = deltaTime;
				event.time = time;
				event.status = status;
				event.param1 = midi.bytes.readByte();

				if (event.type != 0xD0 && event.type != 0xC0) { //program change and channel pressure has no second param
					event.param2 = midi.bytes.readByte();
				}
				if (event.type == 0x90 && event.param2 == 0) { //0 velocity notes count as note off?
					event.type = 0x80;
				}
				
				track.events.push(event);
		}
	}
	midi.bytes.position = end; //make sure it ends in the correct position?

	return track;
}

//7 bits per byte int shit idk
function readVariableLengthInt(bytes) {
	var result = bytes.readByte();

	if ((result & 0x80) == 0)
	{
		return result;
	}

	result &= 0x7F;

	for (j in 0...3)
	{
		var value = bytes.readByte();

		result = (result << 7) | (value & 0x7F);

		if ((value & 0x80) == 0)
		{
			break;
		}
	}

	return result;
}
