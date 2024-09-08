import funkin.backend.utils.CoolUtil;
import funkin.backend.utils.IniUtil;
import funkin.backend.system.Logs;

class ChromaticScale extends FlxBasic {
	
	/**
	 * Stores a set of sounds, with the currently playing key, octave and velocity
	 */
	public var soundData = [];

	/**
	 * Sound object (only used by waveform in editor)
	 */
	public var sound:FlxSound = null;

	///settings
	/////////////////////////////////////////////

	/**
	 * Chromatic Volume settings
	 */
	public var volume:Float = 1.0;
	/**
	 * Starting octave of the chromatic, 3 means it will start at C4 (the note octave starts at -1 in the code)
	 */
	public var startOctave:Int = 3;
	/**
	 * Audio offset for markers in milliseconds
	 */
	public var timeOffset:Float = 0;
	/**
	 * Difference bettwen each sample in milliseconds
	 */
	public var timeDiff:Float = 2000;
	/**
	 * Percentage of sample time that the loop ends at
	 */
	public var loopEnd:Float = 0.75;
	/**
	 * Percentage of sample time that the loop will repeat at
	 */
	public var loopStart:Float = 0.5;
	/**
	 * Note key offset
	 */
	public var keyOffset:Int = 0;

	/////////////////////////////////////////////////

	/**
	 * Midi events list
	 */
	public var events:Array<Dynamic> = [];

	/**
	 * Midi Volume Setting
	 */
	public var midiVolume:Float = 1.0;

	/**
	 * Vocal volume (used in game for muting on misses)
	 */
	public var vocalVolume:Float = 1.0;

	/**
	 * Name of the .ogg/ini file that was loaded
	 */
	public var chromName:String = "";

	/**
	 * Loads the chromatic from its .ogg and .ini file inside the ```chromatics/``` folder
	 * @param name Chromatic file name
	 */
	public function initFromFile(name:String) {
		var path = Paths.getPath("chromatics/"+name);
		if (!Assets.exists(path+".ogg")) return;

		for (data in soundData) {
			data.sound.stop();
		}
		soundData = [];

		for (i in 0...4) { //allow up to 4 different sounds at once (in case a song has doubles)
			soundData.push({
				sound: FlxG.sound.load(path+".ogg"),
				curNote: -1,
				curOctave: -1,
				curVelocity: 100
			});
		}
		sound = FlxG.sound.load(path+".ogg"); //for waveform (not used to actually play sound)

		volume = 1.0;
		keyOffset = 0;
		chromName = name;

		if (!Assets.exists(path+".ini")) return;

		var iniData = IniUtil.parseString(Assets.getText(path+".ini"));
		
		if (iniData.exists("START_OCTAVE")) startOctave = Std.parseInt(iniData.get("START_OCTAVE"));
		if (iniData.exists("TIME_OFFSET")) timeOffset = Std.parseFloat(iniData.get("TIME_OFFSET"));
		if (iniData.exists("SAMPLE_TIME_DIFF")) timeDiff = Std.parseFloat(iniData.get("SAMPLE_TIME_DIFF"));
		if (iniData.exists("LOOP_END")) loopEnd = Std.parseFloat(iniData.get("LOOP_END"));
		if (iniData.exists("LOOP_START")) loopStart = Std.parseFloat(iniData.get("LOOP_START"));
		if (iniData.exists("VOLUME")) volume = Std.parseFloat(iniData.get("VOLUME"));
		if (iniData.exists("KEY_OFFSET")) keyOffset = Std.parseInt(iniData.get("KEY_OFFSET"));

		verifyBounds(true);
	}

	/**
	 * Saves the chromatic .ini with its current settings
	 * @param name .ini file name
	 */
	public function saveIniFile(name:String) {

		var fileData:String = "";
		fileData += "START_OCTAVE = " + startOctave;
		fileData += "\nTIME_OFFSET = " + timeOffset;
		fileData += "\nSAMPLE_TIME_DIFF = " + timeDiff;
		fileData += "\nLOOP_END = " + loopEnd;
		fileData += "\nLOOP_START = " + loopStart;
		fileData += "\nVOLUME = " + volume;
		fileData += "\nKEY_OFFSET = " + keyOffset;

		CoolUtil.safeSaveFile(Paths.getAssetsRoot() + "/chromatics/"+name+".ini", fileData);
	}
	public function play(note:Int, octave:Int, velocity:Float) {

		for (data in soundData) {
			if (data.curNote == -1 && data.curOctave == -1) {
				data.curNote = note;
				data.curOctave = octave;
				data.curVelocity = velocity;
				data.sound.play(true, timeOffset + (((octave-startOctave)*12) + note + keyOffset)*timeDiff);
				data.sound.volume = volume * (data.curVelocity / 100) * midiVolume * vocalVolume;
				break;
			}				
		}		
	}
	public function update() {
		//loop check
		for (data in soundData) {
			if (data.sound.playing) {
				var timeStarted = timeOffset + (((data.curOctave-startOctave)*12) + data.curNote + keyOffset)*timeDiff;
				if (data.sound.time >= timeStarted + (timeDiff*loopEnd)) {
					data.sound._channel.position = timeStarted + timeDiff*loopStart;
				}
				data.sound.volume = volume * (data.curVelocity / 100) * midiVolume * vocalVolume;
			}
		}

		//do events
		while (events.length > 0 && Conductor.songPosition >= events[0].time) {
				
			var oct = Math.floor(events[0].note / 12) - 1;
			var note = events[0].note%12;

			if (!events[0].isOff)
				play(note, oct, events[0].velocity);
			else
				stop(note, oct);

			//trace(events[0]);

			events.splice(0, 1);
		}
	}
	public function stop(note:Int, octave:Int) {

		for (data in soundData) {
			if (data.curNote == note && data.curOctave == octave) {
				data.curNote = -1;
				data.curOctave = -1;
				data.sound.stop();
			}
		}
	}

	public function getSoundTimeAtNote(note, octave) {
		return timeOffset + (((octave-startOctave)*12) + note + keyOffset)*timeDiff;
	}

	public var minNote:Float = -1;
	public var maxNote:Float = -1;
	
	public function loadMidiEvents(midi, ?channel:Int = null, ?trackNum:Int = null, ?octaveOffset:Int = 0) {

		var offset = 0;
		if (octaveOffset != null) {
			offset = octaveOffset*12;
		}

		var trackIndex = 0;
		var lastEvent = null;


		minNote = 127;
		maxNote = 0;

		for (track in midi.tracks) {
			if (trackNum == null || (trackIndex == trackNum)) {
				for (event in track.events) {
					if (channel == null || (event.channel == channel)) {
						if (event.type == 0x90 || event.type == 0x80) {
							var e = {
								time: convertTicksToMilliseconds(event.time, Conductor.bpm, midi.ticksPerQuarterNote),
								note: event.param1+offset,
								isOff: event.type != 0x90,
								channel: event.channel,
								velocity: event.param2
							};
							if (lastEvent != null && e.note == lastEvent.note && e.isOff == lastEvent.isOff) {
								//trace("skip");
								continue;
							}

							if (e.note < minNote) minNote = e.note;
							if (e.note > maxNote) maxNote = e.note;

							lastEvent = e;
							if (FlxG.sound.music == null || FlxG.sound.music.time <= e.time) events.push(e);
						}
							
					}
				}
			}

			trackIndex++;
		}
		events.sort(function(a, b) {
			if(a.time < b.time) return -1;
			else if(a.time > b.time) return 1;
			else return 0;
		});


		verifyBounds(true);
	}

	public function verifyBounds(first:Bool = true) {
		if (minNote == -1 && maxNote == -1) return;

		//check if a note is too low or high for the chrom
		var lowOct = Math.floor(minNote / 12) - 1;
		var lowNote = minNote%12;
		if (getSoundTimeAtNote(lowNote, lowOct) < 0.0) {
			if (first) {
				keyOffset += 12; //offset by 1 octave if the chromatic does not go that low
			} else {
				Logs.trace('Chromatic "'+chromName+'" cannot play all notes (note is too low!)', 1);
			}
		}

		var highOct = Math.floor(maxNote / 12) - 1;
		var highNote = maxNote%12;
		if (getSoundTimeAtNote(highNote, highOct) > sound.length) {			
			if (first) {
				keyOffset -= 12; //offset by 1 octave if the chromatic does not go that hight
			} else {
				Logs.trace('Chromatic "'+chromName+'" cannot play all notes (note is too high!)', 1);
			}
		}
		if (first) verifyBounds(false); //check again after auto adjust
	}

	public function convertTicksToMilliseconds(ticks, bpm, ppq) {
		return (60000 / (bpm * ppq)) * ticks;
	}

	public function convertMillisecondsToTicks(milliseconds, bpm, ppq) {
		return milliseconds / (60000 / (bpm * ppq));
	}

	public function setVocalVolume(vol:Float) {
		vocalVolume = vol;
		for (data in soundData) {
			if (data.sound.playing) {
				data.sound.volume = volume * (data.curVelocity / 100) * midiVolume * vocalVolume;
			}
		}
	}


	override public function destroy() {
		for (data in soundData) {
			data.sound.stop();
			data = null;
			soundData.splice(0, 1);
		}
		for (e in events) {
			e = null;
			events.splice(0, 1);
		}
		soundData = [];
		sound = null;
		events = [];
	}
}