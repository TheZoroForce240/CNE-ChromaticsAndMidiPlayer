

import funkin.options.type.TextOption;
import funkin.options.OptionsScreen;
import funkin.editors.ui.UISubstateWindow;
import funkin.options.type.EditorIconOption;
import funkin.editors.ui.UIState;
import funkin.menus.FreeplayState.FreeplaySonglist;

public static var SELECTED_MIDI_SONG = "test";
public static var SELECTED_MIDI_DIFF = "normal";

function create()
{
	bgType = "charter";


	var freeplayList = FreeplaySonglist.get(false);

	var list:Array<OptionType> = [];

	for(s in freeplayList.songs) {
		var songOption = new EditorIconOption(s.name, "Press ACCEPT to choose a difficulty.", s.icon, function() {
			curSong = s;
			var list:Array<OptionType> = [
				for(d in s.difficulties) if (d != "")
					new TextOption(d, "Press ACCEPT to view the midi for the selected difficulty", function() {
						SELECTED_MIDI_SONG = s.name;
						SELECTED_MIDI_DIFF = d;
						var s = new UIState();
						s.scriptName = "ChromaticTestState";
						FlxG.switchState(s);
					})
			];
			optionsTree.add(new OptionsScreen(s.name, "Select a difficulty to continue.", list));
		}, 0xFFFFFFFF);
		if (Assets.exists(Paths.getPath("songs/"+s.name+"/midi/"))) {
			list.push(songOption);
		}
	}



	main = new OptionsScreen("Song Midi Tester", "Select a song to view the midi from.", list);

}