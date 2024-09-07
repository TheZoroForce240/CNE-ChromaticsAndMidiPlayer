import flixel.math.FlxMath;
import funkin.menus.MainMenuState;
import flixel.FlxSprite;
import funkin.editors.ui.UIText;
import funkin.editors.ui.UINumericStepper;
import funkin.editors.ui.UIFileExplorer;
import funkin.editors.ui.UIDropDown;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UICheckbox;
import funkin.editors.ui.UIWindow;
import funkin.editors.ui.UISlider;
import funkin.editors.ui.UITopMenu;
import funkin.editors.charter.CharterWaveformHandler;
import funkin.editors.EditorTreeMenu;
import funkin.backend.system.framerate.Framerate;
import ChromaticScale;
import ChromaticWaveform;

var chromatic:ChromaticScale = null;

var waveformSprite:ChromaticWaveform;

var notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
var previewKeys:Array<UIButton> = [];
var keysWindow:UIWindow;
var keysCamera:FlxCamera;

var optionsWindow:UIWindow;
var gapStepper:UINumericStepper;
var volumeStepper:UINumericStepper;
var loopStartStepper:UINumericStepper;
var loopEndStepper:UINumericStepper;
var startOctaveStepper:UINumericStepper;
var timeOffsetStepper:UINumericStepper;

function postCreate() {
	
	var bg = new FlxSprite();
	bg.loadGraphic(Paths.image('menus/menuDesat'));
	add(bg);
	FlxG.mouse.visible = true;

	add(new UITopMenu([
		{
			label: "File",
			childs: [
				{
					label: "Save",
					onSelect: (t) -> {save();}
				},
				null,
				{
					label: "Exit",
					onSelect: (t) -> {exit();}
				}
			]
		},
		{
			label: "View"
		}
	]));


	chromatic = new ChromaticScale();
	chromatic.initFromFile(SELECTED_CHROM); //static var from ChromaticSelectState

	var waveformWindow = new UIWindow(160, 220, 960, 250, "Waveform");
	add(waveformWindow);

	waveformSprite = new ChromaticWaveform();
	waveformSprite.initSound(chromatic.soundData[0].sound);
	waveformSprite.refreshMarkers(chromatic.timeDiff);
	add(waveformSprite);
	add(waveformSprite.waveformHandler);
	add(waveformSprite.markers);
	add(waveformSprite.loopStartSpr);
	add(waveformSprite.loopEndSpr);
	add(waveformSprite.timeSprite);

	keysWindow = new UIWindow(20, 100, 120, 600, "Keys");
	add(keysWindow);
	keysCamera = new FlxCamera(20, 100+30, 120, 600-30-1);
	FlxG.cameras.add(keysCamera, false);
	keysCamera.bgColor = 0;
	for (i in 0...11) {
		var line = new FlxSprite(0, -32*((i*12)-1));
		line.makeGraphic(1, 1);
		line.setGraphicSize(120,2);
		line.updateHitbox();
		line.cameras = [keysCamera];
		add(line);
	}
	for (i in 0...127) {
		var button = new UIButton(60, -32*i, notes[i%12] + "" + Math.floor(i / 12), function(){}, 60);
		button.ID = i;
		button.cameras = [keysCamera];
		add(button); previewKeys.push(button);
	}
	refreshKeys();
	keysCamera.scroll.y = -32*12*5.5;

	function addLabelOn(ui:UISprite, text:String) {
		var t = new UIText(ui.x, ui.y - 24, 0, text); add(t);
		return t;
	}
	function addStepperButtons(stepper, val1, val2, w) {

		var leftButton = new UIButton(stepper.x-w, stepper.y, "<", function() {
			stepper.onChange((stepper.value-val1)+"");
		}, w); add(leftButton);

		if (val2 != 0.0) {
			var leftButton2 = new UIButton(leftButton.x-w, stepper.y, "<<", function() {
				stepper.onChange((stepper.value-val2)+"");
			}, w); add(leftButton2);
		}

		var rightButton = new UIButton(stepper.x+stepper.bWidth, stepper.y, ">", function() {
			stepper.onChange((stepper.value+val1)+"");
		}, w); add(rightButton);

		if (val2 != 0.0) {
			var rightButton2 = new UIButton(rightButton.x+rightButton.bWidth, stepper.y, ">>", function() {
				stepper.onChange((stepper.value+val2)+"");
			}, w); add(rightButton2);
		}

	}

	optionsWindow = new UIWindow(160, 500, 960, 200, "Options");
	add(optionsWindow);

	gapStepper = new UINumericStepper(optionsWindow.x + 20, optionsWindow.y + 75, chromatic.timeDiff, 1, 2, 0, 999999, 120);
	gapStepper.onChange = function(str) {
		var val = Std.parseFloat(str);
		if (!Math.isNaN(val)) {
			gapStepper.value = val;

			chromatic.timeDiff = gapStepper.value;
			refreshKeys();
			waveformSprite.refreshMarkers(chromatic.timeDiff);
		}
	};
	add(gapStepper);
	var gapText = addLabelOn(gapStepper, "Sample Time Gap (milliseconds)");
	gapStepper.x += (gapText.width*0.5) - (gapStepper.bWidth*0.5);
	addStepperButtons(gapStepper, 1, 50, 35);

	loopStartStepper = new UINumericStepper(optionsWindow.x + 350, optionsWindow.y + 75, chromatic.loopStart, 1, 3, 0, 1, 100);
	loopStartStepper.onChange = function(str) {
		var val = Std.parseFloat(str);
		if (!Math.isNaN(val)) {
			loopStartStepper.value = val;
			chromatic.loopStart = loopStartStepper.value;
		}
	};
	add(loopStartStepper);
	var lsText = addLabelOn(loopStartStepper, "Loop Start (0-1)");
	loopStartStepper.x += (lsText.width*0.5) - (loopStartStepper.bWidth*0.5);
	addStepperButtons(loopStartStepper, 0.01, 0.1, 35);

	loopEndStepper = new UINumericStepper(optionsWindow.x + 350, optionsWindow.y + 150, chromatic.loopEnd, 1, 3, 0, 1, 100);
	loopEndStepper.onChange = function(str) {
		var val = Std.parseFloat(str);
		if (!Math.isNaN(val)) {
			loopEndStepper.value = val;
			chromatic.loopEnd = loopEndStepper.value;
		}
	};
	add(loopEndStepper);
	var leText = addLabelOn(loopEndStepper, "Loop End (0-1)");
	loopEndStepper.x = loopStartStepper.x;
	addStepperButtons(loopEndStepper, 0.01, 0.1, 35);

}

var scrollLerp = -32*12*5;
function update(elapsed) {
	chromatic.update(elapsed);
	keyPressLogic();

	waveformSprite.timeOffset = chromatic.timeOffset;
	waveformSprite.loopStart = chromatic.loopStart;
	waveformSprite.loopEnd = chromatic.loopEnd;
	waveformSprite.updateWaveform();



}




function refreshKeys() {
	for (button in previewKeys) {
		var n = button.ID%12;
		var o = Math.floor(button.ID / 12)-1;
		if (chromatic.getSoundTimeAtNote(n, o) < 0 || chromatic.getSoundTimeAtNote(n, o) >= chromatic.sound.length) {
			button.selectable = false;
		} else {
			button.selectable = true;
		}
	}
}
var curNote = -1;
var curOctave = -1;

var playedWithSpace = false;
var lastPressedButtonID = -1;

function keyPressLogic() {
	if (!playedWithSpace) {
		for (button in previewKeys) {
			if (button.hasBeenPressed) {
				var n = button.ID%12;
				var o = Math.floor(button.ID / 12)-1;
				if (curNote != n && curOctave != o) {
					chromatic.stop(curNote, curOctave);
					curNote = n;
					curOctave = o;
					chromatic.play(n, o, 100);
					waveformSprite.playTime = chromatic.getSoundTimeAtNote(n, o);
					lastPressedButtonID = button.ID;
				}
			}
		}
		if (FlxG.mouse.justReleased) {
			chromatic.stop(curNote, curOctave);
			curNote = -1;
			curOctave = -1;
		}
	}
	if (FlxG.keys.justPressed.SPACE && lastPressedButtonID != -1 && curNote == -1 && curOctave == -1) {
		playedWithSpace = true;

		var n = lastPressedButtonID%12;
		var o = Math.floor(lastPressedButtonID / 12)-1;
		curNote = n;
		curOctave = o;
		chromatic.play(n, o, 100);
		waveformSprite.playTime = chromatic.getSoundTimeAtNote(n, o);

	} else if (FlxG.keys.justReleased.SPACE) {
		if (playedWithSpace) {
			playedWithSpace = false;
			chromatic.stop(curNote, curOctave);
			curNote = -1;
			curOctave = -1;
		}
	}


	if (keysWindow.hovered) {
		if (FlxG.mouse.wheel != 0) {
			scrollLerp -= FlxG.mouse.wheel * 32 * 3;
			scrollLerp = FlxMath.bound(scrollLerp, -32*126, -32*12);
		}
	} else {
		waveformSprite.setZoom(waveformSprite.zoom - (FlxG.mouse.wheel * (FlxG.keys.pressed.SHIFT ? 5.0 : 1.0)));
	}
	keysCamera.scroll.y = CoolUtil.fpsLerp(keysCamera.scroll.y, scrollLerp, 0.05);
}



function destroy() {

	if(keysCamera != null) {
		if (FlxG.cameras.list.contains(keysCamera))
			FlxG.cameras.remove(keysCamera);
		keysCamera = null;
	}
}



function exit() {
	var state = new EditorTreeMenu();
	state.scriptName = "ChromaticSelectState";
	FlxG.switchState(state);
}
function save() {
	chromatic.saveIniFile(SELECTED_CHROM);
}