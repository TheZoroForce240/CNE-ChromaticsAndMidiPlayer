
import funkin.options.type.TextOption;
import funkin.options.OptionsScreen;
import funkin.editors.ui.UISubstateWindow;
import funkin.editors.ui.UIState;

public static var SELECTED_CHROM = "BF";

function create()
{
	bgType = "charter";

	var chromList = [];
	for (file in Paths.getFolderContent("chromatics/")) {
		if (StringTools.endsWith(file, ".ogg")) {
			chromList.push(StringTools.replace(file, ".ogg", ""));
		}
	}

	var options = [];
	for (chrom in chromList) {
		var option = new TextOption(chrom, "", function() {
			SELECTED_CHROM = chrom;
			var s = new UIState();
			s.scriptName = "ChromaticEditState";
			FlxG.switchState(s);
		});
		options.push(option);
	}



	main = new OptionsScreen("Chromatic Editor", "Press ACCEPT to choose a chromatic to edit.", options);

}