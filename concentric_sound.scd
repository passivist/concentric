(
s.waitForBoot{
	var c;
	c = Condition(false);

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
			[size, size+1, size+2, size+3] // outputs
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
		Splay.ar(SinOsc.ar(freqs)) * 0.05
	});

	SynthDef(\grain, {|out, buf=0, rate, pos, pan, amp, sustain|
		var env, sig;
		env = Env([0, 1, 1, 0], (1/[3, 3, 3]) * sustain).ar(2);
		sig = PlayBuf.ar(
			2, buf,
			rate * BufRateScale.kr(buf),
			startPos: pos * BufFrames.kr(buf)) * env;
		sig = Balance2.ar(sig[0], sig[1], pan) * 1;
		sig = HPF.ar(sig, 200).tanh;
		OffsetOut.ar(out, sig * amp);
	}).add;

	~size = 10*10;
	~nn = ~makeNN.(~size);

	~b = Buffer.read(s, "/home/pi/dev/concentric/_samples/RJK_Athmo_Cut_v2.wav");

	s.sync(c);
	" --- Buffer Loaded ---".postln;
	c.wait;

	OSCdef(\x, { |msg|
		msg = ~parseMsg.(msg);
		//msg.postln;
		~nn = ~updateNN.(~nn, msg);
	}, '/image');

	~logMax = 0 ! 4;
	~logMin = 1 ! 4;
	//~logPos = List.new;

	Tdef(\sonify, {
		var time, elapsedTime;
		var vals, longTermVals;
		var low, high;
		low = -1; high = 4.6;
		longTermVals = (0 ! 4);
		elapsedTime = 0;
		loop{
			vals = ~nn.next;
			// vals.postln;
			~logMin = ~logMin.collect{ |inval, i| if(vals[i] < inval) { vals[i] }{inval} };
			~logMax = ~logMax.collect{ |inval, i| if(vals[i] > inval) { vals[i] }{inval} };
			longTermVals = vals.collect{ |inval, i| switch(i,
				0, { (longTermVals[0] + inval.linlin(low, high, -0.0001, 0.0001)).wrap(0, 1) },
				1, { (longTermVals[1] + inval.linlin(low, high, -0.001, 0.001)).wrap(-1, 1)},
				2, { (longTermVals[2] + inval.linlin(low, high, -0.001, 0.001)).wrap(0.7, 4) },
				3, { (longTermVals[3] + inval.linlin(low, high, -0.01, 0.01)).wrap(0.2, 1)},
			) };
			longTermVals.postln;
			// time should not go unter 0.013 as thats about the upper limit for what ~nn.next takes to calculate (at a size of 10*10)
			time = vals[0].linlin(low, high, 0.015, 0.1);
			//Ndef(\nn).set(\freqs, longTermVals.linlin(-10, 10, 100, 1000));

			Synth(\grain, [
				\buf, ~b,
				\rate, 1,
				\pos, longTermVals[0],
				\pan, longTermVals[1],
				\sustain, time*longTermVals[2],
				\amp, longTermVals[3]
			]);

			elapsedTime = elapsedTime + time;

			if(elapsedTime > (60)){ ~nn = ~makeNN.(~size); elapsedTime = 0; "recreating NN".postln };

			// time.postln;
			time.wait;
		}
	});
}
)

~logMax.sort.last.postln;
~logMin.sort[0].postln;

Tdef(\sonify).play
Tdef(\sonify).stop

~logPos.asArray.plot

//
// Ndef(\nn).play;
// Ndef(\nn).stop;

"hallo".postln

~nn = ~makeNN.(~size);

~b.play

100.do { ~nn = ~makeNN.(~size); { 100.do { ~nn.next } }.bench }


{ 100.do { ~nn = ~makeNN.(~size); } }.bench
