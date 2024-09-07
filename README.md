# CNE-ChromaticsAndMidiPlayer
 
Very WIP!

Press 7 on the main menu to access the chromatic editor and midi test viewer.

### Chromatics

These go in ```chromatics/``` as a ```.ogg``` file, which should then appear in game.

Inside the editor you can view the waveform, play each key, and tweak specific settings (not everything has been implemented yet!).

Chromatics need to have a consistent gap to work correctly! (its also recommened to trim the beginning and boost the audio slightly (since you cannot boost above 100% in game))

Each chromatic uses a .ini file to store its settings and can be easily edited (if you don't have one it should appear after saving inside the editor)
- ```START_OCTAVE``` (octave that the chrom starts at, typically 2 or 3)
- ```TIME_OFFSET``` (offset, buggy rn)
- ```SAMPLE_TIME_DIFF``` (difference in milliseconds between each sample)
- ```LOOP_START``` (time in the sample that a loop starts at, 0-1)
- ```LOOP_END``` (time in the sameple that the loop ends at, 0-1)
- ```VOLUME``` (0-1)
- ```KEY_OFFSET``` (offset in case a chromatic is offkey)



### Song Midis

Song midis can be added in ```songs/songname/midi/``` and will default to `Vocals-0.mid` with the `0` being the strumline number.

Song midis also have a settings.ini that can tweak a certain values:
- ```OCTAVE_OFFSET```
- ```VOCAL_VOLUME``` (0-1)
- ```STRUMLINE_0_FILE``` (changes the file that it loads, ```0``` is the strumline number)
- ```STRUMLINE_0_OCTAVE_OFFSET```
- ```STRUMLINE_0_TRACK``` (makes the midi to only load a specific track)
- ```STRUMLINE_0_CHANNEL``` (makes the midi to only load a specific channel)


If a ```midi/``` folder exists in a song folder, the vocals file will not play in game so that the midi can play instead (mainly for addon mods).

If a character has the same name as a chromatic it will be used, and if a ```chromatic``` value is added into the character xml it will be loaded instead.
