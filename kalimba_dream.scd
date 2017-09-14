/////////////////////////////////////////////////
//     _         _ _           _               //
//    | |       | (_)         | |              //
//    | | ____ _| |_ _ __ ___ | |__   __ _     //
//    | |/ / _` | | | '_ ` _ \| '_ \ / _` |    //
//    |   < (_| | | | | | | | | |_) | (_| |    //
//    |_|\_\__,_|_|_|_| |_| |_|_.__/ \__,_|    //
//                                             //
//          _                                  //
//         | |                                 //
//       __| |_ __ ___  __ _ _ __ ___          //
//      / _` | '__/ _ \/ _` | '_ ` _ \         //
//     | (_| | | |  __/ (_| | | | | | |        //
//      \__,_|_|  \___|\__,_|_| |_| |_|        //
//                                             //
//           by Team Trouble Clef              //
//                                             //
//    Pong Trairatvorakul, Sophia Eller,       //
//               Shruti Johari                 //
//                                             //
/////////////////////////////////////////////////

// How to use:
// 1. Evaluate this block (beginning on line 13)
// 2. Evaluate instrument block (beginning around line 400)
// 3. Click big red button on GUI
// 4. Listen & enjoy! :D

(
// notes per octave
n = 12;
// names of notes (for human readability)
~names = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"];

// == Part I: The Harmony ====================================
// Automata system to generate Harmony
g = (
	// current pitch set
	ps:  [0, 1, 4, 5, 7, 11, 12, 16],

	// tonality
	//  where \maj => maj7        9 #11
	//        \min => min7        9  11
	//        \dom => dom7       b9  11
	//        \hdm => half-dim7  b9 b13
	//        \sct => scott7
	//                ...like maj7 but with tensions b9 and 11
	ton1: \sct, // curent
	ton2: \sct, // previous

	// key
	key: 0,     // where 0:C, 1:Db, ... , 11:B

	// initialize the pitch class and tonality states
	init: {
		g.ps   = [0, 1, 4, 5, 7, 11, 12, 16];
		g.ton1 = \sct;
		g.ton2 = \sct;
		g.key  = rand(11);
	},

	// gives the output of automata
	out: {
		// bass :
		//   bottom note
		//   lowest octave
		var bs  = g.ps[0] + g.key;
		var bss = [bs + (2*n)];

		// guide tones :
		//   third and seventh of chord
		//   next two octaves
		var gt  = ([g.ps[2], g.ps[5]] + g.key) % n;
		var gts = [gt + (3*n), gt + (4*n)];

		// upper structure :
		//   all notes in pc
		//   next two octaves
		var us  = g.ps + g.key;
		var uss = [us + (5*n), us + (6*n)];

		// Print out chord and tonality
		(~names[g.key] + "\t" + g.ton1 + "\t").post;

		// output in nice sorted array that
		(bss ++ gts.flatten ++ uss.flatten).sort
	},

	// increment state
	incr: {
		// auxiliary functions:
		// transform guidetones in pc, given tonality
		var getGT = {
			|ton|
			var newGT;
			case
			{ton == \maj} {newGT = [4,11]}
			{ton == \dom} {newGT = [4,10]}
			{ton == \min} {newGT = [3,10]}
			{ton == \hdm} {newGT = [3,10]}
			{ton == \sct} {newGT = [4,11]};
			g.ps[2] = newGT[0];
			g.ps[5] = newGT[1];
		};
		// transform upper structure in pc, given tonality
		var getUS = {
			|ton|
			var newUS;
			case
			{ton == \maj} {newUS = [2,6,7,12,16]}
			{ton == \dom} {newUS = [1,5,7,12,16]}
			{ton == \min} {newUS = [2,5,7,12,15]}
			{ton == \hdm} {newUS = [1,6,8,12,15]}
			{ton == \sct} {newUS = [1,5,7,12,16]};
			g.ps[1] = newUS[0];
			g.ps[3] = newUS[1];
			g.ps[4] = newUS[2];
			g.ps[6] = newUS[3];
			g.ps[7] = newUS[4];
		};

		// find new tonality
		var next; // next tonality
		case
		// maj7 can pretty much lead anywhere
		//   took dom out since we'd rather hear ii-V-I
		{g.ton1 == \maj} {
			next = [\maj, \min, \hdm, \sct].choose;
		}
		// min7 can also pretty much lead anywhere
		{g.ton1 == \min} {
			next = [\maj, \min, \dom, \hdm].choose;
		}
		// min7-dom7-maj7 sequence #idiomatic
		{g.ton1 == \dom && g.ton2 == \min} {
			next = [\maj].choose;
		}
		// hdm7-dom7-min7 sequence #idiomatic
		{g.ton1 == \dom && g.ton2 == \hdm} {
			next = [\min].choose;
		}
		// reached dom by other means (\dom is the only option left)
		//   can lead to maj, min, another dom
		{g.ton1 == \dom} {
			next = [\maj, \min, \dom].choose;
		}
		// hdm always goes to dom (and then to min) :D
		{g.ton1 == \hdm} {
			next = \dom;
		}
		// scott7 is like a maj with weird tensions
		//   so use as maj-sct-maj
		{g.ton1 == \sct} {
			next = \maj;
		}
		{ "Input not accepted.".postln;};
		g.ton2 = g.ton1;   // move current tonality to prev
		g.ton1 = next;     // store next tonality to current
		getGT.value(next); // get guide tones
		getUS.value(next); // get upper structure

		// find new key
		// d for how many semitones down
		case
		// if dom, then down P5 motion (or tritone sub)
		{g.ton2 == \dom} {
			d = [7,1].wchoose([0.6,0.4]);
		}
		// hdm goes down P5
		{g.ton2 == \hdm} {
			d = 7;
		}
		// sct stays on same key
		{g.ton2 == \sct || g.ton1 == \sct} {
			d = 0;
		}
		// else can go down m3, M3, P4, P5, m6, M6
		{ d = [3,4,5,7,8,9].choose; };
		// calculate new key and scale (to keep it in one oct)
		g.key = (g.key - d) % 12;
	}
);

// == Part II: The Melody ====================================
// Celular automata to generate melody
// Inputs: rule (ca rule [0,255]), numSteps (height of ca),
//         width (width of ca), seed (where to have 1 in first row)
// Outputs celular automat based on inputs
~ca = {
	|rule = 30, numSteps = 25, width = 18, seed = 5|
	var initState, bin, rules, output;

	// get initial stage, given seed
	initState = Array.fill(width, {0});
	if (seed < 0 || seed >= width) {
		initState.put(round(width/2) - 1, 1);
	} {
		initState.put(seed, 1);
	};

	// rule dictionary
	bin = rule.asBinaryDigits(8);
	rules = (
		'[ 1, 1, 1 ]': bin[0],
		'[ 1, 1, 0 ]': bin[1],
		'[ 1, 0, 1 ]': bin[2],
		'[ 1, 0, 0 ]': bin[3],
		'[ 0, 1, 1 ]': bin[4],
		'[ 0, 1, 0 ]': bin[5],
		'[ 0, 0, 1 ]': bin[6],
		'[ 0, 0, 0 ]': bin[7]
	);

	// generate the grid
	output = Array.fill(numSteps, {Array.fill(initState.size, {0})});
	output[0] = initState;
	for(1, numSteps-1,
		{|i|
			var state, newState;
			state = [0]++output[i-1]++[0];
			newState = Array.fill(state.size, {0});
			(state.size-1).do{|index|
				var array;
				index = index+1;
				array = [state[index-1], state[index], state[index+1]];
				newState[index]  = rules.at( array.asSymbol );
			};
			// add to ouput
			output[i] = newState[1..(newState.size - 2)];
		}
	);

	output;
};

// == Part IIa: The Melody Durations ================================
// Simple routine to determine number of notes in melody / chord
~notesperchord = Routine ({
	// Version A - 100
	/*
	2.do({2.yield;});
	20.do({16.yield;});
	18.do({8.yield;});
	10.do({4.yield;});
	10.do({2.yield;});
	40.do({|i| (i+1).yield;});
	*/
	// Version B - 100
	/*
	25.do({|i| (i+1).yield;});
	25.do({|i| (25-i).yield;});
	40.do({|i| (i+1).yield;});
	10.do({|i| ((10-i)*4).yield;});
	*/
	// Version C - 100
	30.do({|i| ((i+1)/2).ceil.yield;});
	30.do({|i| ((30-i)/2).ceil.yield;});
	30.do({|i| (i+1).yield;});
	10.do({|i| ((10-i)*3).yield;});
});

// == Part III: Put It Together and Make Sound=======================
~play = {
	// array of notes & durs to be concatenated
	var top    = []; // top voice
	var middle = []; // middle voice
	var bottom = []; // bottom voice
	var durs   = []; // duration of notes in top voice
	var chordLength = 2;  // duration of each chord (can change for fun! :D)
	var measures = 100;   // number of measures
	~notesperchord.reset; // reset the routine every time we play
	g.init; // reset harmony automata

	// for each harmonic beat...
	measures.do({
		|i|
		var notePerChord = ~notesperchord.next + 1; // grab from routine
		var len = chordLength/notePerChord;         // length of each note
		var dur; // duration of notes in this harmonic beat
		var chord = g.out; // get the chord
		var upperPC = chord.drop(5); // pitch class of upper voice

		// rule selection
		var rules = [218, 154, 86, 22]; // curated list of rules for your ears
		var rule = rules.choose;        // pick from the above

		// result of ca
		var matrix = ~ca.value(
			rule: rule,
			numSteps: notePerChord,
			width: size(upperPC),
			seed: rand(size(upperPC))
		);

		// print stuff so user can track info
		("Rule " + rule + "\t Notes per chord: " + notePerChord).postln;

		// increment harmony automata
		g.incr;

		// extract voices
		bottom = bottom ++ chord[0]; // bass
		middle = middle ++ [[chord[1], chord[2], chord[3], chord[4]]]; // guide tones

		// reverse line for fun
		if (coin(0.5)) {
			matrix = matrix.reverse;
		};
		// for each melodic beat
		matrix.do({
			|row, i|
			var beat = [];
			row.do({
				|val, j|
				// if 1, then add note to the beat
				if (val == 1) {
					beat = beat ++ upperPC[j];
				};
				// otherwise do nothing
			});
			// insert rest if beat has less than two notes
			if (size(beat) < 2) {
				beat = \rest;
			};
			// concatenate beat to top melody
			top = top ++ [beat];
		});

		// store duration
		dur = Array.fill(notePerChord, len);
		durs = durs ++ dur;
	});


	// Acutually make some sound
	// top (melody)
	Pbind(
		\instrument, \kalimba,
		\dur, Pseq(durs, 1),
		\amp, 0.1,
		\midinote, Pseq(top, 1)
	).play;
	// middle (guide tones)
	Pbind(
		\instrument, \flute,
		//\sustain, chordLength * 1.1,
		\dur, chordLength,
		\amp, 0.02,
		\midinote, Pseq(middle + 12, 1)
	).play;
	// bottom (bass)
	Pbind(
		\instrument, \wobble,
		\dur, chordLength,
		\sustain, chordLength * 1.01,
		\amp, 0.04,
		\midinote, Pseq(bottom + 12, 1)
	).play;
};

// == Part IV: GUI ==============================================
// because GUIs are fun
w = Window.new("Trouble Clefs", Rect(200,200,500,200));
b = Button.new(w,Rect(40,40,420,120)).states_([
	["CLICK ME", Color.black, Color.red],
	["...enlightenment...",Color. white, Color.black]
]);

// yessss comic sans!!! :D
b.font_(Font("Comic Sans MS", 36));
// list of fonts
/*
Font.availableFonts.do({
	|item|
	item.postln;
});
*/
b.action = {
	~play.(p.value, q.value, u.value);
};

w.front;

)

// test harmmonic FSA
(
m =[];
100.do({
	var stream = g.out;
	g.incr;
	"".postln;
	m = m ++ stream;
});
m;
Pbind(
	\instrument, \rhodey_sc,
	\dur, 0.1,
	\sustain, 2,
	\midinote, Pseq(m, 1)
).play;
)

// test ca
(
var matrix = ~ca.value(
	rule:     126,
	numSteps: 10,
	width:    7,
	seed:     500
);
matrix.do({
	|row, i|
	row.postln;
});
)

//-----INSTRUMENTS-----

(

// Bass
//     from http://sccode.org/1-4VI
SynthDef(\wobble, { arg out=0, amp=0.1, gate=1, pan=0, spread=0.8, freq=200, doneAction=2;
	var wave = {
		|freq|
		var sig, sig1, sig2, sig3;
		sig1 = LFSaw.ar(freq * 1 + (0.04 * [1,-1]));
		sig2 = LFSaw.ar(freq * 0.99 );
		sig3 = LFSaw.ar(freq * 1 );
		sig = sig1 + sig2 + sig3;
		sig = (sig*50).tanh;
		sig = sig * EnvGen.ar(\adsr.kr(Env.adsr(0.05,0.1,0.8,0.1)),gate,doneAction:doneAction);
		sig = Splay.ar(sig, spread, amp, pan);
	};
	var sig = wave.value(freq) + wave.value(0.5 * freq);
	Out.ar(out, LPF.ar(sig,freq*6));
}).add;

// Bass
//   from http://sccode.org/1-52Z
SynthDef(\acid, {
    var snd;
    snd = Pulse.ar(\freq.kr(440), 0.45);
    snd = RLPF.ar(snd, EnvGen.ar(Env([\ffreq.kr(3000), 1000, 100], [0.08, 0.4], \exp)), 0.21);
    snd = snd + (snd + 0.2 * 3).atan * 0.5;
    snd = snd * Env.adsr(0.001, 0.01, 0.7, 0.05).kr(2, \gate.kr(1));
    snd = Pan2.ar(snd, \pan.kr(0), \amp.kr(0.1));
    Out.ar(\out.kr, snd);
}).add;

// from "http://sccode.org/1-4E"
// sounds more like a trumpet/horn after the failure and cheesyness of the stk sax
SynthDef(\sax, { |out, freq=440, amp=0.1, gate=1|
	var num = 16;
	var harms = Array.series(num, 1, 1) * Array.exprand(num, 0.995, 1.001);
	var snd = SinOsc.ar(freq * SinOsc.kr(Rand(2.0,5.0),0,Rand(0.001, 0.01),1) * harms, mul:Array.geom(num, 1, 0.63));
	snd = Splay.ar(snd);
	snd = BBandPass.ar(snd, freq * XLine.kr(0.1,4,0.01), 2);
	snd = snd * amp * EnvGen.ar(Env.adsr(0.001, 0.2, 0.7, 0.2), gate, doneAction:2);
	Out.ar(out, snd!2);
}).add;

// should be more like a gated synth, but this one gives the rhythmic element
// remember to pass the bps from the language tempo!
SynthDef(\lead, { |out, freq=440, amp=0.1, gate=1, bps=2|
    var snd;
    var seq = Demand.kr(Impulse.kr(bps*4), 0, Dseq(freq*[1,3,2], inf)).lag(0.01);
    snd = LFSaw.ar(freq*{rrand(0.995, 1.005)}!4);
    snd = Splay.ar(snd);
    snd = MoogFF.ar(snd, seq, 0.5);
    snd = snd * EnvGen.ar(Env.asr(0.01,1,0.01), gate, doneAction:2);
    OffsetOut.ar(out, snd * amp);
}).add;

// yep, an organ with a sub bass tone :D
SynthDef(\organ, { |out, freq=440, amp=0.1, gate=1|
    var snd;
    snd = Splay.ar(SinOsc.ar(freq*Array.geom(4,1,2), mul:1/4));
    snd = snd + SinOsc.ar(freq/2, mul:0.4)!2;
    snd = snd * EnvGen.ar(Env.asr(0.001,1,0.01), gate, doneAction:2);
    OffsetOut.ar(out, snd * amp);
}).add;

// Kalimba
//     from http://sccode.org/1-51l
SynthDef(\kalimba, {
    |out = 0, freq = 440, amp = 0.1, mix = 0.1|
    var snd;
    // Basic tone is a SinOsc
    snd = SinOsc.ar(freq) * EnvGen.ar(Env.perc(0.005, Rand(2.5, 3.5), 1, -8), doneAction: 2);
    // The "clicking" sounds are modeled with a bank of resonators excited by enveloped pink noise
    snd = (snd * (1 - mix)) + (DynKlank.ar(`[
        // the resonant frequencies are randomized a little to add variation
        // there are two high resonant freqs and one quiet "bass" freq to give it some depth
        [240*ExpRand(0.9, 1.1), 2020*ExpRand(0.9, 1.1), 3151*ExpRand(0.9, 1.1)],
        [-7, 0, 3].dbamp,
        [0.8, 0.05, 0.07]
    ], PinkNoise.ar * EnvGen.ar(Env.perc(0.001, 0.01))) * mix);
    Out.ar(out, Pan2.ar(snd, 0, amp));
}).add;

// String synth from:
// "http://new-supercollider-mailing-lists-forums-use-these.2681727
//   .n2.nabble.com/guitar-synthdef-td7598199.html"
SynthDef(\string, {arg out=0, freq=440, pan=0, sustain=0.5, amp=0.3;
	var pluck, period, string;
	pluck = PinkNoise.ar(Decay.kr(Impulse.kr(0.005), 0.05));
	period = freq.reciprocal;
	string = CombL.ar(pluck, period, period, sustain*6);
	string = LeakDC.ar(LPF.ar(Pan2.ar(string, pan), 12000)) * amp;
	DetectSilence.ar(string, doneAction:2);
	Out.ar(out, string)
}).add;

// Mario
//     from http://sccode.org/1-11N
SynthDef(\mario, { |out, amp=0.3, freq=440, dur=0.1|
	var snd;
	snd = VarSaw.ar(freq)!2;
	snd = snd * EnvGen.ar(Env.linen(0.001, dur/2, 0.03), doneAction:2);
	OffsetOut.ar(out, snd*amp);
}).add;

// Rhodes Synth
//     from http://sccode.org/1-522
SynthDef(\rhodey_sc, {
    |
    // standard meanings
    out = 0, freq = 440, gate = 1, pan = 0, amp = 0.1,
    // all of these range from 0 to 1
    vel = 0.8, modIndex = 0.2, mix = 0.2, lfoSpeed = 0.4, lfoDepth = 0.1
    |
    var env1, env2, env3, env4;
    var osc1, osc2, osc3, osc4, snd;

    lfoSpeed = lfoSpeed * 12;

    freq = freq * 2;

    env1 = EnvGen.ar(Env.adsr(0.001, 1.25, 0.0, 0.04, curve: \lin));
    env2 = EnvGen.ar(Env.adsr(0.001, 1.00, 0.0, 0.04, curve: \lin));
    env3 = EnvGen.ar(Env.adsr(0.001, 1.50, 0.0, 0.04, curve: \lin));
    env4 = EnvGen.ar(Env.adsr(0.001, 1.50, 0.0, 0.04, curve: \lin));

    osc4 = SinOsc.ar(freq * 0.5) * 2pi * 2 * 0.535887 * modIndex * env4 * vel;
    osc3 = SinOsc.ar(freq, osc4) * env3 * vel;
    osc2 = SinOsc.ar(freq * 15) * 2pi * 0.108819 * env2 * vel;
    osc1 = SinOsc.ar(freq, osc2) * env1 * vel;
    snd = Mix((osc3 * (1 - mix)) + (osc1 * mix));
    snd = snd * (SinOsc.ar(lfoSpeed) * lfoDepth + 1);

    // using the doneAction: 2 on the other envs can create clicks (bc of the linear curve maybe?)
    snd = snd * EnvGen.ar(Env.asr(0, 1, 0.1), gate, doneAction: 2);
    snd = Pan2.ar(snd, pan, amp);

    Out.ar(out, snd);
}).add;

// from "https://github.com/brunoruviaro/SynthDefs-for-Patterns/blob/master/flute.scd"
SynthDef(\flute, { arg scl = 0.2, freq = 440, ipress = 0.9, ibreath = 0.09, ifeedbk1 = 0.4, ifeedbk2 = 0.4, dur = 1, gate = 1, amp = 2;

	var kenv1, kenv2, kenvibr, kvibr, sr, cr, block;
	var poly, signalOut, ifqc;
	var aflow1, asum1, asum2, afqc, atemp1, ax, apoly, asum3, avalue, atemp2, aflute1;
	var fdbckArray;

	sr = SampleRate.ir;
	cr = ControlRate.ir;
	block = cr.reciprocal;

	ifqc = freq;

	// noise envelope
	kenv1 = EnvGen.kr(Env.new(
		[ 0.0, 1.1 * ipress, ipress, ipress, 0.0 ], [ 0.06, 0.2, dur - 0.46, 0.2 ], 'linear' )
	);
	// overall envelope
	kenv2 = EnvGen.kr(Env.new(
		[ 0.0, amp, amp, 0.0 ], [ 0.1, dur - 0.02, 0.1 ], 'linear' ), doneAction: 2
	);
	// vibrato envelope
	kenvibr = EnvGen.kr(Env.new( [ 0.0, 0.0, 1, 1, 0.0 ], [ 0.5, 0.5, dur - 1.5, 0.5 ], 'linear') );

	// create air flow and vibrato
	aflow1 = LFClipNoise.ar( sr, kenv1 );
	kvibr = SinOsc.ar( 5, 0, 0.01 * kenvibr );

	asum1 = ( ibreath * aflow1 ) + kenv1 + kvibr;
	afqc = ifqc.reciprocal - ( asum1/20000 ) - ( 9/sr ) + ( ifqc/12000000 ) - block;

	fdbckArray = LocalIn.ar( 1 );

	aflute1 = fdbckArray;
	asum2 = asum1 + ( aflute1 * ifeedbk1 );

	//ax = DelayL.ar( asum2, ifqc.reciprocal * 0.5, afqc * 0.5 );
	ax = DelayC.ar( asum2, ifqc.reciprocal - block * 0.5, afqc * 0.5 - ( asum1/ifqc/cr ) + 0.001 );

	apoly = ax - ( ax.cubed );
	asum3 = apoly + ( aflute1 * ifeedbk2 );
	avalue = LPF.ar( asum3, 2000 );

	aflute1 = DelayC.ar( avalue, ifqc.reciprocal - block, afqc );

	fdbckArray = [ aflute1 ];

	LocalOut.ar( fdbckArray );

	signalOut = avalue;

	OffsetOut.ar( 0, [ signalOut * kenv2, signalOut * kenv2 ] );

}).add;
)