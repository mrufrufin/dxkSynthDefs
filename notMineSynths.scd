
//adapted from ryan brown's sc-users 2007-08-25, retrieved from the synthdefpool repo
//reintroduced use of baseFreq and redefined time to remove time scaling

SynthDef(\cymbal808_ryan, {|out=0, freq = 300, time = 0.25, amp=0.1|


	var freqs = freq * [ 1, 1.4823959094229, 1.800048697346, 2.545458972486, 2.6322863403944, 3.9552471390309 ];
	var signal, pulseEnv;
	
	pulseEnv = EnvGen.ar(Env.new([1.0, 0.6], [time], [-0.5]));
	signal = Mix.new(LFPulse.ar(freqs * 4.09));
	signal = (BinaryOpUGen('==', signal, 6.0) * 0.6) + (BinaryOpUGen('==', signal, 2.0) * 0.2) + (BinaryOpUGen('==', signal, 1.0) * 0.9); // XOR
 	signal = (signal * pulseEnv) + (Mix.new(LFPulse.ar(freqs, width:0.55)) * 0.9);
	signal = RLPF.ar(signal, 7000, 0.6);
 	signal = RHPF.ar(signal, 6800, 1.5);
	signal = RHPF.ar(signal, 6800, 1.5);
	signal = RHPF.ar(signal, 1200, 1.5);
	signal = signal + FreeVerb.ar(signal);
	signal = signal * EnvGen.ar(Env.new([0, 1, 0.4, 0, 0], [0.002, time, 0.05, 0.5], [0, -0.5, 0, -50]), doneAction:2);
	signal = [signal, DelayN.ar(signal, 0.005, 0.005)];
	OffsetOut.ar(out, signal*4*amp);
}).add;


//fm-gong from http://varioussmallfires.blogspot.ca/2012/01/supercollider-gong.html
//but with some tweaks for panning, etc and matrixing variables
SynthDef("vsfFmGong", {|freq = 100, amp = 1, dr = 1, out = 0, pan = 0| 

	var modsig, modf = freq * [1.16, 3.14, 1.005];
	var idx = [[0.01, 0.3],[0.01,0.38], [0.01, 0.5]] * modf;
	var idxscaler = Array.fill(idx.size, {|i| idx[i][1] - idx[i][0]});
	var modenv = Array.newClear(modf.size);
	var ampenv, carsig, lfo, output;

	lfo = SinOsc.ar(3, 0, XLine.kr(freq*0.005, freq*0.05, dr));

	modenv[0] = EnvGen.kr(
		Env(levels: [0,1,1,0], times: [0.75*dr, 0.24*dr, 0.01*dr]),
		doneAction: 2);

	modenv[1] = EnvGen.kr(
		Env(levels: [0,1,0], times: [0.02*dr, 0.98*dr]),
		doneAction: 2);

	modenv[2] = EnvGen.kr(
		Env(levels: [ 0, 0.3, 1, 0.5, 0], times: [0.15 * dr, 0.15 *dr, 0.45*dr, 0.25*dr]),
		doneAction: 2);

	// Exp curve...
	ampenv = EnvGen.kr(
		Env(levels: [ 0, 1, 0.001], times: [0.002, dr - 0.002], curve: \exp),
		doneAction: 2);

	modsig = Mix.new(SinOsc.ar(modf) * ((idx + idxscaler)*modenv));
	carsig = SinOsc.ar(freq + lfo + modsig)*modf.size.reciprocal;
	output = carsig * ampenv * amp;
	output = Pan2.ar(output, pan);
	Out.ar(out, output);

}).add;

//Detuned Synth Pad by coreyker from sccode.org http://sccode.org/1-4YS
//in turn taken from http://www.attackmagazine.com/technique/synth-secrets/detuned-pad/
//added amp, pan (instead of original Splay), changed some variables to args (lfo/lop/detune)

SynthDef(\coreyDesyp, {|gate = 1, freq = 440, lfofreq = 3, lopfreq = 800, rq = 0.5,
	detune1 = 12, detune2 = 8, amp = 1, pan = 0, out = 0|
	var env = EnvGen.ar(Env.adsr(1e-8, 1e-6, 0.75, 0.125, amp), gate, doneAction:2);
	var nvoices1 = 5, nvoices2 = 7;

	var osc1 = {
		var m = 2**(detune1/1200).rand2;
		var lfo = SinOsc.ar(lfofreq.rand).range(0,1);
		DelayC.ar(LFSaw.ar(m * freq/2), 0.02, freq.reciprocal.rand * lfo);
	}.dup(nvoices1);

	var osc2 = {
		var m = 2**(detune2/1200).rand2;
		var lfo = SinOsc.ar(lfofreq.rand).range(0,1);
		DelayC.ar(LFSaw.ar(m * freq), 0.02, freq.reciprocal.rand * lfo);
	}.dup(nvoices2);

	var output = BLowPass4.ar(osc1, lopfreq, rq) + osc2 / 4;
	output = Pan2.ar(output*env, pan);
	Out.ar(out, output);
}).add;

// abstracted out from 08091500Acid309 by_otophilia
SynthDef("otoClap", {	|rel = 0.3, hip1 = 600, bp1 = 2000, brq1 = 3, hip2 = 1000, bp2 = 1200, brq2 = 0.7, ampn2 = 0.7, out = 0, pan = 0, amp = 1|
		var env1, env2, output, noise1, noise2;
		var env1lvl, env1time, env1curve;
		var env2lvl, env2time, env2curve;

		env1lvl = [0, 1, 0, 1, 0, 1, 0, 1, 0];
		env1time = [0.001, 0.013, 0, 0.01, 0, 0.01, 0, 0.03];
		env1curve = [0, -3, 0, -3, 0, -3, 0, -4];
		env2lvl = [0,1,0];
		env2time = [0.02, rel];
		env2curve = [0, -4];
		
	    env1 = EnvGen.ar(Env.new(env1lvl, env1time, env1curve)); //attack
     	env2 = EnvGen.ar(Env.new(env2lvl, env2time, env2curve), doneAction:2); //release
		
		noise1 = WhiteNoise.ar(env1);
		noise1 = HPF.ar(noise1, hip1);
		noise1 = BPF.ar(noise1, bp1, brq1);
		
		noise2 = WhiteNoise.ar(env2);
		noise2 = HPF.ar(noise2, hip2);
		noise2 = BPF.ar(noise2, bp2, brq2, ampn2);
		
		output = noise1 + noise2;
		output = output.softclip * amp;
		output = Pan2.ar(output, pan);
		
		Out.ar(out, output);
	}).add;