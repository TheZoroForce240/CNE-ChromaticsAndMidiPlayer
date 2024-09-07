import funkin.game.PlayState;
import flixel.FlxSprite;
import funkin.backend.system.Conductor;
import funkin.editors.ui.UIDropDown;
import funkin.editors.EditorTreeMenu;
import ChromaticScale;

var midis = [];

var chromatics = [];

var inst = null;

var dropdowns = [];

var chromList = [];

var notes = [];

var songToPlay = "test";

function postCreate() {
	var bg = new FlxSprite();
	bg.loadGraphic(Paths.image('menus/menuDesat'));
	bg.color = 0x666666;
	bg.scrollFactor.set();
	add(bg);

	importScript("data/scripts/midiParser");




	songToPlay = SELECTED_MIDI_SONG;

	PlayState.loadSong(songToPlay, SELECTED_MIDI_DIFF);
	Conductor.setupSong(PlayState.SONG);

	if (FlxG.sound.music != null) {
		FlxG.sound.music.stop();
	}

	
	inst = FlxG.sound.load(Paths.inst(PlayState.SONG.meta.name, PlayState.difficulty));
	inst.group = FlxG.sound.defaultMusicGroup;
	inst.persist = false;
	CoolUtil.setMusic(FlxG.sound, inst);
	FlxG.sound.music.play(true, 0);
	
	//FlxG.sound.music.time = 5000;

	
	for (file in Paths.getFolderContent("chromatics/")) {
		if (StringTools.endsWith(file, ".ogg")) {
			chromList.push(StringTools.replace(file, ".ogg", ""));
		}
	}

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
		var chrom = new ChromaticScale(); chrom.initFromFile("BF"); chromatics.push(chrom);
		add(chrom);

		chrom.midiVolume = midiVolume;

		var dropdown = new UIDropDown(20, 100 + (32*i), 320, 32, chromList);
		dropdown.screenCenter(FlxAxes.X);
		dropdown.x -= 160;
		dropdown.scrollFactor.set();
		dropdown.onChange = function(index) {
			chrom.initFromFile(chromList[index]);
		};
		add(dropdown);

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

			switch(strumline.type) {
				case 1: 
					printMidiTracks(midi, 0xFF00BFFF, 640);
				case 2:
					printMidiTracks(midi, 0xFFFF0051, 320);
				default:
					printMidiTracks(midi, 0xFFFF4D00, 0);
			}
			
		}
	}

}

function onFocus() {
	FlxG.sound.music.resume();
}
function onFocusLost() {
	FlxG.sound.music.pause();
}

function printMidiTracks(midi, color, offset) {
	var curNotes:Array<FlxSprite> = [];
	for (i in 0...127) {
		curNotes.push(null);
	}
	for (track in midi.tracks) {
		for (event in track.events) {
			if (event.type == 0x90) {
				curNotes[event.param1] = new FlxSprite((FlxG.width*0.5) - (event.param1 * ((FlxG.width*0.5)/128)) + offset, 
					FlxG.height - convertTicksToMilliseconds(event.time, Conductor.bpm, midi.ticksPerQuarterNote));

				curNotes[event.param1].makeGraphic(1,1, color);
				//curNotes[event.param1].setGraphicSize((FlxG.width*0.5)/128, (FlxG.width*0.5)/128);
				//curNotes[event.param1].updateHitbox();
				add(curNotes[event.param1]);
				notes.push(curNotes[event.param1]);
				
			} else if (event.type == 0x80) {

				if (curNotes[event.param1] != null) {

					var y = FlxG.height - convertTicksToMilliseconds(event.time, Conductor.bpm, midi.ticksPerQuarterNote);
					var diff = Math.abs(curNotes[event.param1].y - y);

					curNotes[event.param1].setGraphicSize((FlxG.width*0.5)/128, diff-20);
					curNotes[event.param1].updateHitbox();
					curNotes[event.param1].y -= curNotes[event.param1].height;
				}
			}
		}
	}
}

function update(elapsed) {

	FlxG.camera.scroll.y = -Conductor.songPosition;

	if (controls.BACK) {
		exit();
	}
}
function exit() {
	var state = new EditorTreeMenu();
	state.scriptName = "SongMidiSelectState";
	FlxG.switchState(state);
}

function destroy() {
	midi0 = null;
	midi1 = null;
	chrom0 = null;
	chrom1 = null;

	
	if (FlxG.sound.music != null) {
		FlxG.sound.music.stop();
		FlxG.sound.music = null;
	}
	FlxG.sound.destroySound(inst);
	inst = null;
	
	
	for (c in chromatics) {
		c.destroy();
		c = null;
	}
 	chromatics = [];
}


