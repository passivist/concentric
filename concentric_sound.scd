(
~makeNN = {|size|
	var nn, zeros, output_weights;
	zeros = (0 ! size);
	nn = Neuromodule(
		(1.0 ! (size + 4)).rand2, // x
		(1.0 ! (size + 4)).rand2, // theta
		(size + 4).collect{ |i|
			if(i < size){
				output_weights = [1, 0.5, -0.5, -1].rotate(i) / i.linlin(0, size-1, 0.2, 1);

				zeros ++ output_weights
			}{
				(0 ! (size + 4))
			}
		}, // weights
		[size, size+1, size+2, size+3]
	);
	nn
};

~updateNN = {|nn, msg|
	nn.theta = msg.flat;
	// nn.x = msg.flat ++ (0 ! 4);
	//nn.weights = msg.collect{|item, i| (item.linlin(0, 1, -3, 3) * i.linlin(0, 1, 0.25, 1)) };
	nn
};

~parseMsg = { |msg|
	var insideArray, returnList, nestedList;
	insideArray = false;
	returnList = List.new();
	nestedList = List.new();
	msg.do{|item, i|
		if(i != 0){
			if(insideArray){
				if(item == $]){
					returnList.add(Array.newFrom(nestedList));
					insideArray = false;
				}{
					nestedList.add(item);
				}
			}{
				if(item == $[){
					nestedList = List.new();
					insideArray = true;
				};
			}
		}
	};
	Array.newFrom(returnList.linlin(0, 255, -0.5, 5));
};

Ndef(\nn, {|freqs = #[300, 400, 500, 600]|
	Splay.ar(SinOsc.ar(freqs)) * 0.5
});

SynthDef(\grain, {|out, buf=0, rate, pos, pan, amp, sustain|
	var env, sig;
	env = Env([0, 1, 1, 0], (1/[3, 3, 3]) * sustain).ar(2);
	sig = PlayBuf.ar(
		2, buf,
		rate * BufRateScale.kr(buf),
		startPos: pos * BufFrames.kr(buf)) * env;
	sig = Splay.ar(sig, 1, 1, pan);
	OffsetOut.ar(out, sig * amp);
}).add;

~size = 16*16;
~nn = ~makeNN.(~size);

OSCdef(\x, { |msg|
	msg = ~parseMsg.(msg);
	//msg.postln;
	~nn = ~updateNN.(~nn, msg);
}, '/image');

Tdef(\sonify, {
	var time;
	var vals;
	var low, high;
	low = -1; high = 2.5;
	loop{
		vals = ~nn.next;
		vals.postln;
		time = vals[0].linlin(low, high, 0.05, 0.15);
		Ndef(\nn).set(\freqs, vals.linlin(low, high, 100, 1000));
		//
		// Synth(\grain, [
		// 	\buf, ~b,
		// 	\rate, [0.25, 0.5, 1, 2, -0.5].at(vals[2].linlin(low, high, 0, 5)),
		// 	\pos, vals[1].linlin(low, high, 0.1, 0.85),
		// 	\pan, vals[3].linlin(low, high, -1, 1),
		// 	\sustain, time*vals[3].linlin(low, high, 0.01, 16),
		// 	\amp, vals[2].linlin(low, high, 0, 1)
		// ]);

		time.wait;
	}
});
)


Ndef(\nn).play;
Ndef(\nn).stop;

// ~b = Buffer.read(s, "D:/_Samples/EIGENE/Instrumente/Streicher/Orchestral Strings/Waves Chord Change/Ab/01_Abmj7-Fm6(Ab)-97bpm_TNOTR EP3 M06 Where does the truth lie.wav");
// ~b.play

Tdef(\sonify).play
Tdef(\sonify).stop
