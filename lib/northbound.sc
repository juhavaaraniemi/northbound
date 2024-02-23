// Northbound 0.1

Northbound {

	classvar <channelKeys;
	classvar <noiseFilters;
	classvar <noiseAmpEnvelopes;
	classvar <analogWaves;
	classvar <fmWaves;
	classvar <cymbalWaves;
	classvar <drumHeadWaves;
	classvar <toneAmpEnvelopes;
	classvar <clicks;

	var <globalParams;
	var <channelParams;
	var <channelGroup;
	var <channels;
	var <toneBus;
	var <noiseBus;
	var <clickBus;

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

				noiseAmpEnvelopes = (
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
						var pw = toneSpectra.linlin(0,100,0.5,1);
						Pulse.ar(freq: pitchEnv1, width: pw, mul: 0.5)
					}
				);

				fmWaves = (
					1: {arg pitchEnv1, pitchEnv2, dynFilterEnv;
						PMOsc.ar(carfreq: pitchEnv1, modfreq: pitchEnv2, pmindex: dynFilterEnv, mul: 0.5)
					},
					2: {arg pitchEnv1, pitchEnv2, dynFilterEnv;
						var mod = SinOscFB.ar(freq: pitchEnv2, feedback: dynFilterEnv*0.1, mul: pitchEnv1*dynFilterEnv);
						SinOsc.ar(pitchEnv1+mod, mul:0.5)
					}
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
								[ 0.20,1.00,1.80,0.20,2.20,0.85,2.00,0.60,0.30,2.00,0.30 ] // decays
								//nil
							]
						});
						Klank.ar(spec, Decay.ar(Impulse.ar(0), 0.004, 0.01),baseFreq/1.59,0,dynDecay);
					}
				);

				cymbalWaves = (
					1: {arg baseFreq, toneSpectra, dynDecay;
						var partials = 15;
						var spec;
						spec = Array.fill(2, {
							`[	// rez bank spec
								[1, 1.077652103, 1.215599552, 1.278099109, 1.309519787, 1.320529045, 1.358325822, 1.408275352, 1.530539896, 1.546569596, 1.558360996, 1.583876758, 1.662845324, 1.699431933, 1.704369164], // freqs
								[1.00,
									1.00,
									(toneSpectra.linlin(0,7.7,0,0.9)-toneSpectra.linlin(7.7,100,0,0.9)+0.1),
									(toneSpectra.linlin(0,15.4,0,0.9)-toneSpectra.linlin(15.4,100,0,0.9)+0.1),
									(toneSpectra.linlin(0,23.1,0,0.9)-toneSpectra.linlin(23.1,100,0,0.9)+0.1),
									(toneSpectra.linlin(0,30.8,0,0.9)-toneSpectra.linlin(30.8,100,0,0.9)+0.1),
									(toneSpectra.linlin(0,38.5,0,0.9)-toneSpectra.linlin(38.5,100,0,0.9)+0.1),
									(toneSpectra.linlin(0,46.2,0,0.9)-toneSpectra.linlin(46.2,100,0,0.9)+0.1),
									(toneSpectra.linlin(0,53.9,0,0.9)-toneSpectra.linlin(53.9,100,0,0.9)+0.1),
									(toneSpectra.linlin(0,61.6,0,0.9)-toneSpectra.linlin(61.6,100,0,0.6)+0.1),
									(toneSpectra.linlin(0,69.3,0,0.9)-toneSpectra.linlin(69.3,100,0,0.6)+0.1),
									(toneSpectra.linlin(0,77,0,0.9)-toneSpectra.linlin(77,100,0,0.6)+0.1),
									(toneSpectra.linlin(0,84.7,0,0.9)-toneSpectra.linlin(84.7,100,0,0.6)+0.1),
									(toneSpectra.linlin(0,92.4,0,0.9)-toneSpectra.linlin(92.4,100,0,0.6)+0.1),
									toneSpectra.linlin(0,100,0.1,1)], // amps
								//Array.fill(partials, { 1.0 + 4.0.rand }) // decays
								[1.00,0.95,0.9,0.85,0.8,0.75,0.7,0.65,0.6,0.55,0.5,0.45,0.4,0.35,0.3] // decays
							]
						});
						Klank.ar(spec, Decay.ar(Impulse.ar(0), 0.004, WhiteNoise.ar(0.02)),baseFreq,0,dynDecay);
					}
				);

				toneAmpEnvelopes = (
					//exp
					1: { arg attack, dynDecay, stopGate = 1;
						Env.perc(attack,dynDecay,1).kr(gate: stopGate, doneAction: 2)
					},
					//lin
					2: { arg attack, dynDecay, stopGate = 1;
						Env.linen(attack,0.01,dynDecay,1).kr(gate: stopGate, doneAction: 2)
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
						LFPulse.ar(freq: 100, width: 0.5, mul: 1)*vel
					}
				);

				noiseFilters.keysValuesDo{arg filtername, filterfunction;
					noiseAmpEnvelopes.keysValuesDo{arg envelopename, envelopefunction;
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
							var dynFilterEnv = XLine.kr(freq+(diff*vel),freq,dynDecay);

							var signal = SynthDef.wrap(
								filterfunction,
								prependArgs: [unfiltered, dynFilterEnv, noiseFilterResonance]
							);

							Out.ar(out, signal)
						}).add;
					};
				};

				analogWaves.keysValuesDo{arg wavename, wavefunction;
					toneAmpEnvelopes.keysValuesDo{arg envelopename, envelopefunction;
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
							//var dynFilterEnv = XLine.kr(freq+(diff*vel),freq,dynDecay);
							var dfEnv = Env(levels: [freq+(diff*vel),freq],times: [dynDecay],curve: -4);
							var dynFilterEnv = EnvGen.kr(dfEnv);

							var signal = BLowPass.ar(unfiltered, dynFilterEnv, 1);

							Out.ar(out,signal);
						}).add;
					};
				};

				fmWaves.keysValuesDo{arg wavename, wavefunction;
					toneAmpEnvelopes.keysValuesDo{arg envelopename, envelopefunction;
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
							out = 0;

							var amp = toneAmp.linlin(0,50,0,1);

							var dynDecay = toneDecay + ((toneDynDecay-toneDecay)*vel);

							var freq1 = tonePitch.midicps;
							var fLo1 = toneBend.linexp(-50,0,freq1/4,freq1);
							var fHi1 = toneBend.linexp(0,50,freq1,freq1*4);
							var diff1 = (fLo1-freq1)+(fHi1-freq1);
							var dynBendEnv1 = XLine.kr(freq1+(diff1*vel),freq1,toneBendTime);

							var fRatio = toneSpectra.linlin(0,100,0,10);
							var freq2 = fRatio*freq1;
							var fLo2 = toneBend.linexp(-50,0,freq2/4,freq2);
							var fHi2 = toneBend.linexp(0,50,freq2,freq2*4);
							var diff2 = (fLo2-freq2)+(fHi2-freq2);
							var dynBendEnv2 = XLine.kr(freq2+(diff2*vel),freq2,toneBendTime);

							var freq = toneFreq.linlin(0,50,0,24);
							var fHi = toneDynFilter.linlin(0,50,freq,24);
							var diff = fHi-freq;
							//var dynFilterEnv = XLine.kr(freq+(diff*vel),freq,dynDecay);
							var dfEnv = Env(levels: [freq+(diff*vel),freq],times: [dynDecay],curve: -4);
							var dynFilterEnv = EnvGen.kr(dfEnv);

							var wave = SynthDef.wrap(
								wavefunction,
								prependArgs: [dynBendEnv1, dynBendEnv2, dynFilterEnv]
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
					toneAmpEnvelopes.keysValuesDo{arg envelopename, envelopefunction;
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
							//var dynFilterEnv = XLine.kr(freq+(diff*vel),freq,dynDecay);
							var dfEnv = Env(levels: [freq+(diff*vel),freq],times: [dynDecay],curve: -4);
							var dynFilterEnv = EnvGen.kr(dfEnv);

							var signal = BLowPass4.ar(unfiltered, dynFilterEnv, 1);

							Out.ar(out,signal);
						}).add;
					};
				};

				cymbalWaves.keysValuesDo{arg wavename, wavefunction;
					toneAmpEnvelopes.keysValuesDo{arg envelopename, envelopefunction;
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
							//var dynFilterEnv = XLine.kr(freq+(diff*vel),freq,dynDecay);
							var dfEnv = Env(levels: [freq+(diff*vel),freq],times: [dynDecay],curve: -4);
							var dynFilterEnv = EnvGen.kr(dfEnv);

							var signal = BLowPass4.ar(unfiltered, dynFilterEnv, 1);

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
					// pan
					signal = Pan2.ar(signal,pan);

					Out.ar(out,signal);
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
			\clickType, 1,
			\clickAmp, 50,
			\distAmt, 2,
			\eqFreq, 500,
			\eqGain, 1,
			\pan, 0,
			\level, 0;
		]);

		channels = Dictionary.new;
		channelParams = Dictionary.new;
		toneBus = Dictionary.new;
		noiseBus = Dictionary.new;
		clickBus = Dictionary.new;
		channelKeys.do({ arg channelKey;
			channels[channelKey] = Group.new(channelGroup);
			channelParams[channelKey] = Dictionary.newFrom(globalParams);
			toneBus[channelKey] = Bus.audio(s, 1);
			noiseBus[channelKey] = Bus.audio(s, 1);
			clickBus[channelKey] = Bus.audio(s, 1);
			Synth("channelStrip", [\tone,toneBus[channelKey],\noise,noiseBus[channelKey],\click,clickBus[channelKey]],channels[channelKey]);
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