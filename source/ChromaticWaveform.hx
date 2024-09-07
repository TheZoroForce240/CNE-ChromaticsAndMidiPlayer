import flixel.math.FlxRect;
import funkin.backend.system.Conductor;
import flixel.math.FlxMath;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import funkin.editors.charter.CharterWaveformHandler;



class ChromaticWaveform extends flixel.FlxSprite {

	public var waveformHandler:CharterWaveformHandler;
	public var sound:FlxSound;
	public var zoom:Float = 1.0;
	public var markers:FlxSpriteGroup;
	public var timeSprite:FlxSprite;
	public var loopStartSpr:FlxSprite;
	public var loopEndSpr:FlxSprite;

	public var markerDiff:Float = 0;
	public var playTime:Float = 0;
	public var loopEnd:Float = 0;
	public var loopStart:Float = 0;

	public function initSound(sound:FlxSound) {
		if (waveformHandler == null) {
			waveformHandler = new CharterWaveformHandler();
			makeGraphic(1,1, 0xFF000000);
			setGraphicSize(200, 960);
			updateHitbox();
			screenCenter();
			angle = -90;

			timeSprite = new FlxSprite();
			timeSprite.makeGraphic(1,1);
			timeSprite.setGraphicSize(2, 200);
			timeSprite.updateHitbox();
			timeSprite.screenCenter();

			loopStartSpr = new FlxSprite();
			loopStartSpr.makeGraphic(1,1, 0xFF00FF00);
			loopStartSpr.setGraphicSize(2, 200);
			loopStartSpr.updateHitbox();
			loopStartSpr.screenCenter();

			loopEndSpr = new FlxSprite();
			loopEndSpr.makeGraphic(1,1, 0xFF00FF00);
			loopEndSpr.setGraphicSize(2, 200);
			loopEndSpr.updateHitbox();
			loopEndSpr.screenCenter();

			markers = new FlxSpriteGroup();
		}
		this.sound = sound;
		var stepTime = Conductor.getStepForTime(sound.length);
		waveformHandler.ampsNeeded = stepTime*40;
		waveformHandler.clearWaveforms();
		shader = waveformHandler.generateShader("chromatic", sound);
		waveformHandler.waveformList.push("chromatic");
	}

	public function refreshMarkers(diff) {
		markers.clear();
		markerDiff = diff;

		var count = Math.ceil(sound.length / diff);

		for (i in 0...count) {
			var spr = new FlxSprite();
			spr.makeGraphic(1,1, 0xFFFF0000);
			spr.setGraphicSize(2, 200);
			spr.updateHitbox();
			spr.screenCenter();
			markers.add(spr);
		}
	}
	public var timeOffset = 0.0;
	public var lastTime = 0;
	public function updateWaveform() {

		if (FlxG.mouse.wheel != 0 && FlxG.mouse.overlaps(this)) {
			

		}

		var pos = sound.playing ? Conductor.getStepForTime(sound.time)*40 : lastTime;
		if (sound.playing) lastTime = pos;
		shader.data.pixelOffset.value = [pos - (960*0.5*zoom)];
		shader.data.textureRes.value = [width, height*zoom];
		shader.data.playerPosition.value = [pos];

		loopEndSpr.screenCenter();
		loopEndSpr.x += ((Conductor.getStepForTime(playTime + (markerDiff*loopEnd))*40) - pos) / zoom;
		loopStartSpr.screenCenter();
		loopStartSpr.x += ((Conductor.getStepForTime(playTime + (markerDiff*loopStart))*40) - pos) / zoom;
	
		for (i => spr in markers.members) {
			spr.screenCenter();
			spr.x += ((Conductor.getStepForTime((markerDiff*i)+timeOffset)*40) - pos) / zoom;
			if (spr.x < (FlxG.width*0.5) - (960*0.5) || spr.x > (FlxG.width*0.5) + (960*0.5))
				spr.visible = false;
			else
				spr.visible = true;
		}

		timeSprite.visible = sound.playing;
	}
	public function setZoom(z) {
		zoom = z;
		if (zoom <= 1.0) zoom = 1.0;
		if (zoom >= sound.length/40) zoom = sound.length/40;
	}
	
}
