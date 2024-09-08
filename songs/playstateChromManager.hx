import flixel.sound.FlxSound;
import ChromaticScale;

var _hasMidi = true;
public var chromatics = [];
public var midis = [];
function create() {

	var songToPlay = PlayState.SONG.meta.name;

	if (!Assets.exists(Paths.getPath("songs/"+songToPlay+"/midi/"))) {
		_hasMidi = false;
		return;
	}

	importScript("data/scripts/midiParser");

	var midiOctaveOffset:Int = 0;
	var midiVolume:Float = 1.0;
	var iniData = ["" => ""];
	//midi vocal settings
	if (Assets.exists(Paths.getPath("songs/"+songToPlay+"/midi/settings.ini"))) {
		iniData = IniUtil.parseString(Assets.getText(Paths.getPath("songs/"+songToPlay+"/midi/settings.ini")));
		
		if (iniData.exists("OCTAVE_OFFSET")) midiOctaveOffset = Std.parseInt(iniData.get("OCTAVE_OFFSET"));
		if (iniData.exists("VOCAL_VOLUME")) midiVolume = Std.parseFloat(iniData.get("VOCAL_VOLUME"));
	}

	for (i => strumline in PlayState.SONG.strumLines) {
		var chromName = "BF";
		if (Assets.exists(Paths.getPath("chromatics/"+strumline.characters[0]+".ogg")))
			chromName = strumline.characters[0];

		if (strumLines.members[i].characters[0] != null) {
			if (strumLines.members[i].characters[0].extra.exists("chromatic")) {
				chromName = strumLines.members[i].characters[0].extra.get("chromatic");
			}
		}

		var chrom = new ChromaticScale(); chrom.initFromFile(chromName);
		add(chrom);

		chrom.midiVolume = midiVolume;

		var vocalFile = "Vocals-"+i;
		var channel = null;
		var track = null;
		var octaveOffset = 0;

		if (iniData.exists("STRUMLINE_"+i+"_FILE")) vocalFile = iniData.get("STRUMLINE_"+i+"_FILE");
		if (iniData.exists("STRUMLINE_"+i+"_CHANNEL")) channel = Std.parseInt(iniData.get("STRUMLINE_"+i+"_CHANNEL"));
		if (iniData.exists("STRUMLINE_"+i+"_TRACK")) track = Std.parseInt(iniData.get("STRUMLINE_"+i+"_TRACK"));
		if (iniData.exists("STRUMLINE_"+i+"_OCTAVE_OFFSET")) octaveOffset = Std.parseInt(iniData.get("STRUMLINE_"+i+"_OCTAVE_OFFSET"));

		midi = loadMidiFromAssets(Paths.getPath("songs/"+songToPlay+"/midi/"+vocalFile+".mid"));
		if (midi != null) {
			chrom.loadMidiEvents(midi, channel, track, midiOctaveOffset+octaveOffset);
		}
		chromatics.push(chrom);
		midis.push(midi);
	}

	FlxG.sound.destroySound(vocals);
	vocals = new FlxSound();
}

function onPlayerMiss(event) {
	if (_hasMidi && event.muteVocals) {
		var id = event.playerID;
		if (chromatics[id] != null) chromatics[id].setVocalVolume(0.0);
	}
}
function onNoteHit(event) {
	if (_hasMidi && event.unmuteVocals) {
		var id = event.note.strumLine.ID;
		if (chromatics[id] != null && chromatics[id].vocalVolume != 1.0) chromatics[id].setVocalVolume(1.0);
	}
}
function onPostGameOver(event) {
	if (_hasMidi) {
		for (chrom in chromatics) chrom.setVocalVolume(0.0);
	}
}