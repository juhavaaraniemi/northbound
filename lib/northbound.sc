// Northbound 0.1

Northbound {

	classvar <channelKeys;
	classvar <noiseFilters;
	classvar <ampEnvelopes;
	classvar <analogWaves;
	classvar <fmWaves;
	classvar <cymbalWaves;
	classvar <drumHeadWaves;
	classvar <clicks;

	var <globalParams;
	var <channelParams;
	var <channelGroup;
	var <channels;
	var <toneBus;
	var <noiseBus;
	var <clickBus;
	var <reverbBus;

	*initClass {
		// 8 channels of drum voices
		channelKeys = [ \1, \2, \3, \4, \5, \6, \7, \8];
		StartUp.add {
			var s = Server.default;

			s.waitForBoot {

				noiseFilters = (
					1: { arg in, dynFilterEnv, noiseFilterResonance;
						BLowPass.ar(in, dynFilterEnv, noiseFilterResonance.linexp(0, 20, 1, 0.05))
					},
					2: { arg in, dynFilterEnv, noiseFilterResonance;
						BLowPass4.ar(in, dynFilterEnv, noiseFilterResonance.linexp(0, 20, 1, 0.05))
					},
					3: { arg in, dynFilterEnv, noiseFilterResonance;
						BHiPass.ar(in, dynFilterEnv, noiseFilterResonance.linexp(0, 20, 1, 0.05))
					},
					4: { arg in, dynFilterEnv, noiseFilterResonance;
						BHiPass4.ar(in, dynFilterEnv, noiseFilterResonance.linexp(0, 20, 1, 0.05))
					},
					5: { arg in, dynFilterEnv, noiseFilterResonance;
						BBandPass.ar(in, dynFilterEnv, noiseFilterResonance.linexp(0, 20, 0.5, 0.05))
					},
					6: { arg in, dynFilterEnv, noiseFilterResonance;
						BBandPass.ar(in, dynFilterEnv, noiseFilterResonance.linexp(0, 20, 0.125, 0.05))
					}
				);

				ampEnvelopes = (
					//exp
					1: { arg attack, dynDecay, stopGate = 1;
						Env.perc(attack,dynDecay,1).kr(gate: stopGate, doneAction: 2)
					},
					//lin
					2: { arg attack, dynDecay, stopGate = 1;
						Env.linen(attack,0.01,dynDecay,1).kr(gate: stopGate, doneAction: 2)
					},
					//gate
					3: { arg attack, dynDecay, stopGate = 1;
						Env.linen(attack,dynDecay,0.01,1).kr(gate: stopGate, doneAction: 2)
					}
				);

				analogWaves = (
					//sine
					1: {arg pitchEnv1, pitchEnv2;
						Mix.ar([SinOsc.ar(freq: pitchEnv1, mul: 0.25),
							SinOsc.ar(freq: pitchEnv2, mul: 0.25)])
					},
					//triangle
					2: {arg pitchEnv1, pitchEnv2;
						Mix.ar([DPW3Tri.ar(freq: pitchEnv1, mul: 0.25),
							DPW3Tri.ar(freq: pitchEnv2, mul: 0.25)])
					},
					//saw
					3: {arg pitchEnv1, pitchEnv2;
						Mix.ar([SawDPW.ar(freq: pitchEnv1, mul: 0.25),
							SawDPW.ar(freq: pitchEnv2, mul: 0.25)])
					},
					//square
					4: {arg pitchEnv1, pitchEnv2;
						Mix.ar([Pulse.ar(freq: pitchEnv1, width: 0.5, mul: 0.25),
							Pulse.ar(freq: pitchEnv2, width: 0.5, mul: 0.25)])
					},
					//pulse
					5: {arg pitchEnv1, pitchEnv2, toneSpectra;
						var pw = toneSpectra.linlin(0,100,0.5,0.95);
						Pulse.ar(freq: pitchEnv1, width: pw, mul: 0.5)
					}
				);

				fmWaves = (
					1: {arg pitchEnv1, dynFilterEnv, fRatio3, fRatio2, index3, index2, index1, feedback;
						var limit = 18000;
						var osc3 = LPF.ar(SinOsc.ar(freq: pitchEnv1*fRatio3, phase: feedback*LocalIn.ar(1,1)),limit);
						var fb = LocalOut.ar(osc3);
						var osc2 = LPF.ar(SinOsc.ar(freq: pitchEnv1*fRatio2, phase: index3*osc3),limit);
						var osc1 = SinOsc.ar(freq: pitchEnv1, phase: index2*osc2)*index1*dynFilterEnv;
						osc1;
					},
					2: {arg pitchEnv1, dynFilterEnv, fRatio3, fRatio2, index3, index2, index1, feedback;
						var limit = 18000;
						var osc3 = LPF.ar(SinOsc.ar(freq: pitchEnv1*fRatio3, phase: feedback*LocalIn.ar(1,1)),limit);
						var fb = LocalOut.ar(osc3);
						var osc2 = LPF.ar(SinOsc.ar(freq: pitchEnv1*fRatio2),limit);
						var osc1 = SinOsc.ar(freq: pitchEnv1, phase: (index2*osc2)+(index3*osc3))*index1;
						osc1;
					},
					3: {arg pitchEnv1, dynFilterEnv, fRatio3, fRatio2, index3, index2, index1, feedback;
						var limit = 18000;
						var osc3 = LPF.ar(SinOsc.ar(freq: pitchEnv1*fRatio3, phase: feedback*LocalIn.ar(1,1)),limit);
						var fb = LocalOut.ar(osc3);
						var osc2 = LPF.ar(SinOsc.ar(freq: pitchEnv1*fRatio2, phase: index3*osc3, mul: 0.5),limit)*index2;
						var osc1 = SinOsc.ar(freq: pitchEnv1, phase: index3*osc3, mul: 0.5)*index1;
						osc1+osc2;
					},
					4: {arg pitchEnv1, dynFilterEnv, fRatio3, fRatio2, index3, index2, index1, feedback;
						var limit = 18000;
						var osc3 = LPF.ar(SinOsc.ar(freq: pitchEnv1*fRatio3, phase: feedback*LocalIn.ar(1,1)),limit);
						var fb = LocalOut.ar(osc3);
						var osc2 = LPF.ar(SinOsc.ar(freq: pitchEnv1*fRatio2, phase: index3*osc3, mul: 0.5),limit)*index2;
						var osc1 = SinOsc.ar(freq: pitchEnv1, mul: 0.5)*index1;
						osc1+osc2;
					},
					5: {arg pitchEnv1, dynFilterEnv, fRatio3, fRatio2, index3, index2, index1, feedback;
						var limit = 18000;
						var osc3 = LPF.ar(SinOsc.ar(freq: pitchEnv1*fRatio3, phase: feedback*LocalIn.ar(1,1)),limit, mul: 0.33)*index3;
						var fb = LocalOut.ar(osc3);
						var osc2 = LPF.ar(SinOsc.ar(freq: pitchEnv1*fRatio2, phase: index3*osc3, mul: 0.33),limit)*index2;
						var osc1 = SinOsc.ar(freq: pitchEnv1, mul: 0.33)*index1;
						osc1+osc2+osc3;
					};
				);

				drumHeadWaves = (
					1: {arg baseFreq, toneSpectra, dynDecay;
						var partials = 6;
						var spec;
						spec = Array.fill(2, {
							`[	// rez bank spec
								[ 0.96,1.98,3.00,4.00,5.04,6.13], // freqs
								[ 1.00,
									1.00,
									(toneSpectra.linlin(0,25,0,0.9)-toneSpectra.linlin(25,100,0,0.9)+0.1),
									(toneSpectra.linlin(0,50,0,0.9)-toneSpectra.linlin(50,100,0,0.9)+0.1),
									(toneSpectra.linlin(0,75,0,0.9)-toneSpectra.linlin(75,100,0,0.9)+0.1),
									toneSpectra.linlin(0,100,0.1,1)],
								//amps
								[ 0.20,1.00,1.80,0.20,2.20,0.85 ] // decays
								//nil
							]
						});
						Klank.ar(spec, Decay.ar(Impulse.ar(0), 0.004, 0.01),baseFreq,0,dynDecay);
					},
					2: {arg baseFreq, toneSpectra, dynDecay;
						var partials = 9;
						var spec;
						spec = Array.fill(2, {
							`[	// rez bank spec
								[ 1.00,1.59,1.83,2.28,2.49,2.89,3.06,3.48,3.69 ], // freqs
								[ 1.00,
									1.00,
									(toneSpectra.linlin(0,14,0,0.9)-toneSpectra.linlin(14,100,0,0.9)+0.1),
									(toneSpectra.linlin(0,28,0,0.9)-toneSpectra.linlin(28,100,0,0.9)+0.1),
									(toneSpectra.linlin(0,42,0,0.9)-toneSpectra.linlin(42,100,0,0.9)+0.1),
									(toneSpectra.linlin(0,59,0,0.9)-toneSpectra.linlin(59,100,0,0.9)+0.1),
									(toneSpectra.linlin(0,73,0,0.9)-toneSpectra.linlin(73,100,0,0.9)+0.1),
									(toneSpectra.linlin(0,87,0,0.9)-toneSpectra.linlin(87,100,0,0.9)+0.1),
									toneSpectra.linlin(0,100,0.1,1)],
								//amps
								[ 0.20,1.00,1.80,0.20,2.20,0.85,2.00,0.60,0.30 ] // decays
								//nil
							]
						});
						Klank.ar(spec, Decay.ar(Impulse.ar(0), 0.004, 0.01),baseFreq/1.59,0,dynDecay);
					}
				);

				cymbalWaves = (
					1: {arg baseFreq, toneSpectra, toneFreq, dynDecay;
						var partials = 15;
						var spec;
						spec = Array.fill(2, {
							`[	// rez bank spec
								[1/toneFreq,
									1.077652103/toneFreq,
									1.215599552/toneFreq,
									1.278099109/toneFreq,
									1.309519787/toneFreq,
									1.320529045/toneFreq,
									1.358325822/toneFreq,
									1.408275352/toneFreq,
									1.530539896*toneFreq,
									1.546569596*toneFreq,
									1.558360996*toneFreq,
									1.583876758*toneFreq,
									1.662845324*toneFreq,
									1.699431933*toneFreq,
									1.704369164*toneFreq], // freqs
								nil,
								nil]
						});
						Klank.ar(spec, Decay.ar(Impulse.ar(0), 0.002, WhiteNoise.ar(0.012)),baseFreq,0,dynDecay);
					},
					2: {arg baseFreq, toneSpectra, toneFreq, dynDecay;
						var partials = 15;
						var spec;
						spec = Array.fill(2, {
							`[	// rez bank spec
								[1.000000000/toneFreq,
									1.073024212/toneFreq,
									1.142100270/toneFreq,
									1.160871339/toneFreq,
									1.161489100/toneFreq,
									1.333246288/toneFreq,
									1.463654217/toneFreq,
									1.512770094/toneFreq,
									1.514042228/toneFreq,
									2.206357270*toneFreq,
									2.381918485*toneFreq,
									2.425064303*toneFreq,
									2.471757350*toneFreq,
									2.506663174*toneFreq,
									2.625599981*toneFreq], // freqs
								nil,
								nil]
						});
						Klank.ar(spec, Decay.ar(Impulse.ar(0), 0.002, WhiteNoise.ar(0.012)),baseFreq,0,dynDecay);
					}
				);

				clicks = (
					1: { arg vel;
						WhiteNoise.ar(mul: 0.5)*vel
					},
					2: { arg vel;
						PinkNoise.ar(mul: 0.5)*vel
					},
					3: { arg vel;
						BrownNoise.ar(mul: 0.5)*vel
					},
					4: { arg vel;
						SinOsc.ar(freq: 100, mul: 1)*vel
					},
					5: { arg vel;
						LFTri.ar(freq: 100, mul: 1)*vel
					},
					6: { arg vel;
						LFPulse.ar(freq: 100, width: 0.9, mul: 1)*vel
					}
				);

				noiseFilters.keysValuesDo{arg filtername, filterfunction;
					ampEnvelopes.keysValuesDo{arg envelopename, envelopefunction;
						var synthdefname = "noise" ++ filtername.asString ++ envelopename.asString;

						SynthDef.new(synthdefname, {
							arg vel = 1.00,
							noiseFilterType = 1,
							noiseFilterResonance = 0,
							noiseFreq = 25,
							noiseDynFilter = 0,
							noiseAmpEnvelope = 1,
							noiseAttack = 0.01,
							noiseDecay = 0.5,
							noiseDynDecay = 0.5,
							noiseAmp = 50,
							out = 0;

							var amp = noiseAmp.linlin(0,50,0,1);

							var noise = WhiteNoise.ar();

							var dynDecay = noiseDecay + ((noiseDynDecay-noiseDecay)*vel);

							var ampEnvelope = SynthDef.wrap(
								envelopefunction,
								prependArgs: [noiseAttack,dynDecay]
							);

							var unfiltered = noise * ampEnvelope * amp * vel * 0.5;

							var freq = noiseFreq.linexp(0,50,20,20000);
							var fLo = noiseDynFilter.linexp(-50,0,20,freq);
							var fHi = noiseDynFilter.linexp(0,50,freq,20000);
							var diff = (fLo-freq)+(fHi-freq);
							var dfEnv = Env(levels: [freq+(diff*vel),freq],times: [dynDecay],curve: -4);
							var dynFilterEnv = EnvGen.kr(dfEnv);

							var signal = SynthDef.wrap(
								filterfunction,
								prependArgs: [unfiltered, dynFilterEnv, noiseFilterResonance]
							);

							Out.ar(out, signal)
						}).add;
					};
				};

				analogWaves.keysValuesDo{arg wavename, wavefunction;
					ampEnvelopes.keysValuesDo{arg envelopename, envelopefunction;
						var synthdefname = "tone1" ++ wavename.asString ++ envelopename.asString;
						SynthDef(synthdefname,{
							arg vel = 1.00,
							toneWave = 1,
							toneSpectra = 50,
							toneFreq = 50,
							toneDynFilter = 0,
							toneAmpEnvelope = 1,
							toneAttack = 0.01,
							toneDecay = 0.5,
							toneDynDecay = 0.5,
							tonePitch = 60,
							toneBend = 0,
							toneBendTime = 0.5,
							toneAmp = 50,
							out = 0;

							var amp = toneAmp.linlin(0,50,0,1);

							var freq1 = tonePitch.midicps;
							var fLo1 = toneBend.linexp(-50,0,freq1/4,freq1);
							var fHi1 = toneBend.linexp(0,50,freq1,freq1*4);
							var diff1 = (fLo1-freq1)+(fHi1-freq1);
							var dynBendEnv1 = XLine.kr(freq1+(diff1*vel),freq1,toneBendTime);

							var freq2 = 2.pow((toneSpectra-50)/120)*freq1;
							var fLo2 = toneBend.linexp(-50,0,freq2/4,freq2);
							var fHi2 = toneBend.linexp(0,50,freq2,freq2*4);
							var diff2 = (fLo2-freq2)+(fHi2-freq2);
							var dynBendEnv2 = XLine.kr(freq2+(diff2*vel),freq2,toneBendTime);


							var wave = SynthDef.wrap(
								wavefunction,
								prependArgs: [dynBendEnv1, dynBendEnv2, toneSpectra]
							);

							var dynDecay = toneDecay + ((toneDynDecay-toneDecay)*vel);

							var ampEnvelope = SynthDef.wrap(
								envelopefunction,
								prependArgs: [toneAttack,dynDecay]
							);

							var unfiltered = wave * ampEnvelope * amp * vel;

							var freq = toneFreq.linexp(0,50,freq1,20000);
							var fHi = toneDynFilter.linexp(0,50,freq,20000);
							var diff = fHi-freq;
							var dfEnv = Env(levels: [freq+(diff*vel),freq],times: [dynDecay],curve: -4);
							var dynFilterEnv = EnvGen.kr(dfEnv);

							var signal = BLowPass.ar(unfiltered, dynFilterEnv, 1);

							Out.ar(out,signal);
						}).add;
					};
				};

				fmWaves.keysValuesDo{arg wavename, wavefunction;
					ampEnvelopes.keysValuesDo{arg envelopename, envelopefunction;
						var synthdefname = "tone2" ++ wavename.asString ++ envelopename.asString;
						SynthDef(synthdefname,{
							arg vel = 1.00,
							toneWave = 1,
							toneSpectra = 50,
							toneFreq = 50,
							toneDynFilter = 0,
							toneAmpEnvelope = 1,
							toneAttack = 0.01,
							toneDecay = 0.5,
							toneDynDecay = 0.5,
							tonePitch = 60,
							toneBend = 0,
							toneBendTime = 0.5,
							toneAmp = 50,
							fmRatio1 = 1,
							fmRatio2 = 1,
							fmRatio3 = 1,
							fmIndex1 = 1,
							fmIndex2 = 2,
							fmIndex3 = 3,
							fmFeedback = 0,
							out = 0;

							var amp = toneAmp.linlin(0,50,0,1);

							var dynDecay = toneDecay + ((toneDynDecay-toneDecay)*vel);

							var freq1 = tonePitch.midicps;
							var fLo1 = toneBend.linexp(-50,0,freq1/4,freq1);
							var fHi1 = toneBend.linexp(0,50,freq1,freq1*4);
							var diff1 = (fLo1-freq1)+(fHi1-freq1);
							var dynBendEnv1 = XLine.kr(freq1+(diff1*vel),freq1,toneBendTime);

							var freq = toneFreq.linlin(0,50,0.0,1.0);
							var fHi = toneDynFilter.linlin(0,50,freq,1.0);
							var diff = fHi-freq;
							var dfEnv = Env(levels: [freq+(diff*vel),freq],times: [dynDecay],curve: -4);
							var dynFilterEnv = EnvGen.kr(dfEnv);

							var wave = SynthDef.wrap(
								wavefunction,
								prependArgs: [dynBendEnv1, dynFilterEnv, fmRatio3, fmRatio2, fmIndex3, fmIndex2, fmIndex1, fmFeedback]
							);

							var ampEnvelope = SynthDef.wrap(
								envelopefunction,
								prependArgs: [toneAttack,dynDecay]
							);

							var signal = wave * ampEnvelope * amp * vel;

							Out.ar(out,signal);
						}).add;
					};
				};

				drumHeadWaves.keysValuesDo{arg wavename, wavefunction;
					ampEnvelopes.keysValuesDo{arg envelopename, envelopefunction;
						var synthdefname = "tone3" ++ wavename.asString ++ envelopename.asString;
						SynthDef(synthdefname,{
							arg vel = 1.00,
							toneWave = 1,
							toneSpectra = 50,
							toneFreq = 50,
							toneDynFilter = 0,
							toneAmpEnvelope = 1,
							toneAttack = 0.01,
							toneDecay = 0.5,
							toneDynDecay = 0.5,
							tonePitch = 60,
							toneBend = 0,
							toneBendTime = 0.5,
							toneAmp = 50,
							out = 0;

							var amp = toneAmp.linlin(0,50,0,1);

							var dynDecay = toneDecay + ((toneDynDecay-toneDecay)*vel);

							var baseFreq = tonePitch.midicps;

							var wave = SynthDef.wrap(
								wavefunction,
								prependArgs: [baseFreq, toneSpectra, dynDecay]
							);

							var ampEnvelope = SynthDef.wrap(
								envelopefunction,
								prependArgs: [toneAttack,dynDecay]
							);

							var unfiltered = wave * ampEnvelope * amp * vel;

							var freq = toneFreq.linexp(0,50,baseFreq,20000);
							var fHi = toneDynFilter.linexp(0,50,freq,20000);
							var diff = fHi-freq;
							var dfEnv = Env(levels: [freq+(diff*vel),freq],times: [dynDecay],curve: -4);
							var dynFilterEnv = EnvGen.kr(dfEnv);

							var signal = BLowPass4.ar(unfiltered, dynFilterEnv, 1);

							Out.ar(out,signal);
						}).add;
					};
				};

				cymbalWaves.keysValuesDo{arg wavename, wavefunction;
					ampEnvelopes.keysValuesDo{arg envelopename, envelopefunction;
						var synthdefname = "tone4" ++ wavename.asString ++ envelopename.asString;
						SynthDef(synthdefname,{
							arg vel = 1.00,
							toneWave = 1,
							toneSpectra = 50,
							toneFreq = 50,
							toneDynFilter = 0,
							toneAmpEnvelope = 1,
							toneAttack = 0.01,
							toneDecay = 0.5,
							toneDynDecay = 0.5,
							tonePitch = 60,
							toneBend = 0,
							toneBendTime = 0.5,
							toneAmp = 50,
							out = 0;

							var amp = toneAmp.linlin(0,50,0,1);

							var dynDecay = toneDecay + ((toneDynDecay-toneDecay)*vel);

							var baseFreq = tonePitch.midicps;

							var freq = toneFreq.linlin(0,50,0.8,1.2);

							var wave = SynthDef.wrap(
								wavefunction,
								prependArgs: [baseFreq, toneSpectra, freq, dynDecay]
							);

							var ampEnvelope = SynthDef.wrap(
								envelopefunction,
								prependArgs: [toneAttack,dynDecay]
							);

							var signal = wave * ampEnvelope * amp * vel;

							//var freq = toneFreq.linexp(0,50,baseFreq,20000);
							//var fHi = toneDynFilter.linexp(0,50,freq,20000);
							//var diff = fHi-freq;
							//var dfEnv = Env(levels: [freq+(diff*vel),freq],times: [dynDecay],curve: -4);
							//var dynFilterEnv = EnvGen.kr(dfEnv);

							//var signal = BLowPass4.ar(unfiltered, dynFilterEnv, 1);

							Out.ar(out,signal);
						}).add;
					};
				};

				clicks.keysValuesDo{arg clickname, clickfunction;
					var synthdefname = "click" ++ clickname.asString;
					SynthDef(synthdefname,{
						arg vel = 1.00,
						clickAmp = 50,
						out = 0;

						var amp = clickAmp.linlin(0,50,0,1);

						var pulse = SynthDef.wrap(
							clickfunction,
							prependArgs: [vel]
						);

						var env = Env.perc(0.00,0.03).kr(doneAction: 2);
						var signal = pulse * env * amp * vel;
						Out.ar(out,signal);
					}).add;
				};

				//master bus
				SynthDef("channelStrip",{
					arg noise,
					tone,
					click,
					distAmt = 2,
					eqFreq = 500,
					eqGain = 1,
					pan = 0,
					level = 0,
					reverbSend = 0,
					send = 0,
					out = 0;

					var toneSignal = In.ar(tone);
					var noiseSignal = In.ar(noise);
					var clickSignal = In.ar(click);

					// mix
					//var signal = SelectX.ar(mix/100,[toneSignal,noiseSignal]);
					var signal = Mix.ar([noiseSignal,toneSignal,clickSignal]);
					// distortion
					signal=SineShaper.ar(signal,1.0,1+(10/(1+(2.7182**((50-distAmt)/8))))).softclip;
					//signal = tanh(signal).softclip;
					// eq
					signal = BPeakEQ.ar(signal,eqFreq,1,eqGain/2);
					// level
					signal = signal*level.dbamp*0.6;
					//reverb
					Out.ar(send,signal*reverbSend.linlin(0,100,0,1));
					//signal = signal*(1-reverbMix);
					// pan
					signal = Pan2.ar(signal,pan);

					Out.ar(out,signal);
				}).add;

				//reverb
				SynthDef("reverb", {

					arg in, out = 0;
					var dry, preProcess, wet, predelay = 0.015;

					dry = In.ar(in);
					preProcess = tanh(BHiShelf.ar(in: dry, freq: 1000, rs: 1, db: -6, mul: 1.5, add: 0));
					preProcess = DelayN.ar(in: preProcess, maxdelaytime: predelay, delaytime: predelay);
					preProcess = preProcess * 0.55;
					wet = tanh(FreeVerb.ar(in: preProcess, mix: 1, room: 0.7, damp: 0.35, mul: 1.8));
					//wet = tanh(FreeVerb2.ar(in: preProcess, in2: preProcess, mix: 1, room: 0.7, damp: 0.35, mul: 1.8));
					//wet = (wet * 0.935);

					Out.ar(out, wet!2);

				}).add;
			}
		}
	}

	*new {
		^super.new.init;
	}

	init {

		var s = Server.default;

		channelGroup = Group.new(s);

		globalParams = Dictionary.newFrom([
			\noiseFilterType, 1,
			\noiseFilterResonance, 0,
			\noiseFreq, 25,
			\noiseDynFilter, 0,
			\noiseAmpEnvelope, 1,
			\noiseAttack, 0.01,
			\noiseDecay, 0.5,
			\noiseDynDecay, 0.5,
			\noiseAmp, 50,
			\toneWaveType, 1,
			\toneWave, 1,
			\toneSpectra, 50,
			\toneFreq, 50,
			\toneDynFilter, 0,
			\toneAmpEnvelope, 1,
			\toneAttack, 0.01,
			\toneDecay, 0.5,
			\toneDynDecay, 0.5,
			\tonePitch, 60,
			\toneBend, 0,
			\toneBendTime, 0.5,
			\toneAmp, 50,
			\fmRatio1, 1,
			\fmRatio2, 1,
			\fmRatio3, 1,
			\fmIndex1, 1,
			\fmIndex2, 1,
			\fmIndex3, 1,
			\fmFeedback, 0,
			\clickType, 1,
			\clickAmp, 50,
			\distAmt, 2,
			\eqFreq, 500,
			\eqGain, 1,
			\pan, 0,
			\level, 0,
			\reverbSend, 0;
		]);

		channels = Dictionary.new;
		channelParams = Dictionary.new;
		toneBus = Dictionary.new;
		noiseBus = Dictionary.new;
		clickBus = Dictionary.new;
		reverbBus = Bus.audio(s, 1);
		Synth("reverb",[\in,reverbBus],channelGroup);
		channelKeys.do({ arg channelKey;
			channels[channelKey] = Group.new(channelGroup);
			channelParams[channelKey] = Dictionary.newFrom(globalParams);
			toneBus[channelKey] = Bus.audio(s, 1);
			noiseBus[channelKey] = Bus.audio(s, 1);
			clickBus[channelKey] = Bus.audio(s, 1);
			Synth("channelStrip", [\tone,toneBus[channelKey],\noise,noiseBus[channelKey],\click,clickBus[channelKey],\send,reverbBus],channels[channelKey]);
		});
	}

	playVoice { arg channelKey, vel;
		channels[channelKey].set(\stopGate, -1.05);

		Synth.new("tone"++channelParams[channelKey][\toneWaveType].asInteger++channelParams[channelKey][\toneWave].asInteger++channelParams[channelKey][\toneAmpEnvelope].asInteger,[\out, toneBus[channelKey], \vel, vel] ++ channelParams[channelKey].getPairs, channels[channelKey]);

		Synth.new("noise"++channelParams[channelKey][\noiseFilterType].asInteger++channelParams[channelKey][\noiseAmpEnvelope].asInteger,[\out, noiseBus[channelKey], \vel, vel] ++ channelParams[channelKey].getPairs, channels[channelKey]);

		Synth.new("click"++channelParams[channelKey][\clickType].asInteger,[\out, clickBus[channelKey], \vel, vel] ++ channelParams[channelKey].getPairs, channels[channelKey]);
	}

	trigger { arg channelKey, vel;
		if( channelKey == 'all',{
			channelKeys.do({ arg cK;
				this.playVoice(cK, vel);
			});
		},
		{
			this.playVoice(channelKey, vel);
		});
	}

	adjustVoice { arg channelKey, paramKey, paramValue;
		channels[channelKey].set(paramKey, paramValue);
		channelParams[channelKey][paramKey] = paramValue
	}

	setParam { arg channelKey, paramKey, paramValue;
		if( channelKey == 'all',{
			channelKeys.do({ arg cK;
				this.adjustVoice(cK, paramKey, paramValue);
			});
		},
		{
			this.adjustVoice(channelKey, paramKey, paramValue);
		});
	}

	freeAllNotes {
		channelGroup.set(\stopGate, -1.05);
	}

	free {
		channelGroup.free;
	}

}
