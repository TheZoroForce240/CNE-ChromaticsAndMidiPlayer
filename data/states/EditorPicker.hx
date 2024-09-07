import funkin.editors.ui.UIState;
import funkin.editors.EditorPicker;
import flixel.effects.FlxFlicker;
import funkin.editors.EditorTreeMenu;
import Type;

var chromEditID = 5;
var midiPlayerID = 6;

function create()
{
	options.push(
		{
			name: "Chromatic Editor",
			iconID: 5,
			state: EditorTreeMenu
		}
	);
	chromEditID = options.length-1;
	options.push(
		{
			name: "Song Midi Tester",
			iconID: 5,
			state: EditorTreeMenu
		}
	);
	midiPlayerID = options.length-1;
	
}
var didSelect = false;
function postUpdate(elapsed)
{
	if (!didSelect)
	{
		if (selected)
		{
			didSelect = true;
			if (curSelected == chromEditID)
				overrideStateLoad("ChromaticSelectState");
			else if (curSelected == midiPlayerID)
				overrideStateLoad("SongMidiSelectState");
		}
	}

}

function overrideStateLoad(script) {
	FlxFlicker.stopFlickering(sprites[curSelected].label); //stop currrent callback
	sprites[curSelected].flicker(function() {
		subCam.fade(0xFF000000, 0.25, false, function() {
			var state = Type.createInstance(options[curSelected].state, []);
			state.scriptName = script;
			FlxG.switchState(state);
		});
	});
}