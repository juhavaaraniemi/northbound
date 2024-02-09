// Northbound 0.1

Northbound {

	classvar <channelKeys;
	classvar <noiseFilters;
	classvar <noiseAmpEnvelopes;
	classvar <waves;
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
					1: { arg in, dynFilterEnv, noiseFilterResonance = 0;
						BLowPass.ar(in, dynFilterEnv, noiseFilterResonance.linexp(0, 20, 1, 0.05))
					},
					2: { arg in, dynFilterEnv, noiseFilterResonance = 0;
						BLowPass4.ar(in, dynFilterEnv, noiseFilterResonance.linexp(0, 20, 1, 0.05))
					},
					3: { arg in, dynFilterEnv, noiseFilterResonance = 0;
						BHiPass.ar(in, dynFilterEnv, noiseFilterResonance.linexp(0, 20, 1, 0.05))
					},
					4: { arg in, dynFilterEnv, noiseFilterResonance = 0;
						BHiPass4.ar(in, dynFilterEnv, noiseFilterResonance.linexp(0, 20, 1, 0.05))
					},
					5: { arg in, dynFilterEnv, noiseFilterResonance = 0;
						BBandPass.ar(in, dynFilterEnv, noiseFilterResonance.linexp(0, 20, 1, 0.5))
					},
					6: { arg in, dynFilterEnv, noiseFilterResonance = 0;
						BBandPass.ar(in, dynFilterEnv, noiseFilterResonance.linexp(0, 20, 1, 0.125))
					}
				);

				noiseAmpEnvelopes = (
					1: { arg vel, noiseAttack=0.01, noiseDecay=0.4, noiseDynDecay=1, stopGate = 1;
						var diff = noiseDynDecay-noiseDecay;
						Env.perc(noiseAttack,noiseDecay+(diff*vel),1).kr(gate: stopGate, doneAction: 2)
					},
					2: { arg vel, noiseAttack=0.01, noiseDecay=0.4, noiseDynDecay=1, stopGate = 1;
						var diff = noiseDynDecay-noiseDecay;
						Env.linen(noiseAttack,0.01,noiseDecay+(diff*vel),1).kr(gate: stopGate, doneAction: 2)
					},
					3: { arg vel, noiseAttack=0.01, noiseDecay=0.4, noiseDynDecay=1, stopGate = 1;
						var diff = noiseDynDecay-noiseDecay;
						Env.linen(noiseAttack,noiseDecay+(diff*vel),0.01,1).kr(gate: stopGate, doneAction: 2)
					}
				);

				waves = (
					1: {arg pitchEnv = 1, toneFreq = 200, toneSpectra = 0;
						var toneFreq2 = 2.pow(toneSpectra/120)*toneFreq;
						Mix.ar([SinOsc.ar(freq: toneFreq*pitchEnv, mul: 0.25),
							SinOsc.ar(freq: toneFreq2*pitchEnv, mul: 0.25)])
					},
					2: {arg pitchEnv = 1, toneFreq = 200, toneSpectra = 0;
						var toneFreq2 = 2.pow(toneSpectra/120)*toneFreq;
						Mix.ar([DPW3Tri.ar(freq: toneFreq*pitchEnv, mul: 0.25),
							DPW3Tri.ar(freq: toneFreq2*pitchEnv, mul: 0.25)])
					},
					3: {arg pitchEnv = 1, toneFreq = 200, toneSpectra = 0;
						var toneFreq2 = 2.pow(toneSpectra/120)*toneFreq;
						Mix.ar([SawDPW.ar(freq: toneFreq*pitchEnv, mul: 0.25),
							SawDPW.ar(freq: toneFreq2*pitchEnv, mul: 0.25)])
					},
					4: {arg pitchEnv = 1, toneFreq = 200, toneSpectra = 0;
						var toneFreq2 = 2.pow(toneSpectra/120)*toneFreq;
						Mix.ar([Pulse.ar(freq: toneFreq*pitchEnv, width: 0.5, mul: 0.25),
							Pulse.ar(freq: toneFreq2*pitchEnv, width: 0.5, mul: 0.25)])
					},
					5: {arg pitchEnv = 1, toneFreq = 200, toneSpectra = 0;
						var pw = toneSpectra.linlin(0,99,0.5,0.99);
						Pulse.ar(freq: toneFreq*pitchEnv, width: pw, mul: 0.5)
					},
					//cymbal
					6: {arg pitchEnv = 1, toneFreq = 200, toneSpectra = 0;
						var partials = 15;
						var spec;
						spec = Array.fill(2, {
							`[	// rez bank spec
								[ 1,
									1.546569596,
									1.558360996,
									1.278099109,
									1.309519787,
									1.704369164,
									1.077652103,
									1.408275352,
									1.320529045,
									1.215599552,
									1.662845324,
									1.530539896,
									1.699431933,
									1.583876758,
									1.358325822], // freqs
								nil, // amps
								//Array.fill(partials, { 1.0 + 4.0.rand }) // decays
								[1.00,0.95,0.9,0.85,0.8,0.75,0.7,0.65,0.6,0.55,0.5,0.45,0.4,0.35,0.3] // decays
							]
						});
						Klank.ar(spec, Decay.ar(Impulse.ar(0), 0.004, WhiteNoise.ar(0.05)),toneFreq,0,5);
					},
					//drumhead
					7: {arg pitchEnv = 1, toneFreq = 200, toneSpectra = 0;
						var partials = 15;
						var spec;
						spec = Array.fill(2, {
							`[	// rez bank spec
								[ 1.00,1.59,2.14,2.30,2.65,2.92,3.16,3.50,3.60,3.65,4.06 ], // freqs
								[ 1.00,1.00,0.30,1.00,0.50,0.45,0.70,0.40,0.20,0.40,0.20 ], // amps
								[ 0.10,3.00,2.00,0.20,2.40,1.85,2.90,0.20,0.20,1.00,0.20 ] // decays
							]
						});
						Klank.ar(spec, Decay.ar(Impulse.ar(0), 0.004, 0.01),toneFreq,0,1);
					}
				);

				toneAmpEnvelopes = (
					1: { arg vel, toneAttack=0.01, toneDecay=0.4, toneDynDecay=1, stopGate = 1;
						var diff = toneDynDecay-toneDecay;
						Env.perc(toneAttack,toneDecay+(diff*vel),1).kr(gate: stopGate, doneAction: 2)
					},
					2: { arg vel, toneAttack=0.01, toneDecay=0.4, toneDynDecay=1, stopGate = 1;
						var diff = toneDynDecay-toneDecay;
						Env.linen(toneAttack,0.01,toneDecay+(diff*vel),1).kr(gate: stopGate, doneAction: 2)
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
						LFPulse.ar(freq: 100, width: 0.1, mul: 1)*vel
					},
					5: { arg vel;
						LFPulse.ar(freq: 100, width: 0.3, mul: 1)*vel
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
							noiseAmp = 0.5,
							noiseFilterFreq = 1000,
							noiseDynFilter = 0,
							noiseDynFilterTime = 0.5,
							out = 0;

							var noise = WhiteNoise.ar();

							var ampEnvelope = SynthDef.wrap(
								envelopefunction,
								prependArgs: [vel]
							);

							var unfiltered = noise * ampEnvelope * noiseAmp * vel * 0.5;

							var dynFilterExpRange = 2.pow(noiseDynFilter/12);
							var dynFilterFreq = Clip.kr(dynFilterExpRange*noiseFilterFreq,20,20000);
							var dynFilterDiff = dynFilterFreq-noiseFilterFreq;
							var dynFilterEnv = XLine.kr(noiseFilterFreq+(dynFilterDiff*vel),noiseFilterFreq,noiseDynFilterTime);

							var signal = SynthDef.wrap(
								filterfunction,
								prependArgs: [unfiltered, dynFilterEnv]
							);

							Out.ar(out, signal)
						}).add;
					};
				};

				waves.keysValuesDo{arg wavename, wavefunction;
					toneAmpEnvelopes.keysValuesDo{arg envelopename, envelopefunction;
						var synthdefname = "tone" ++ wavename.asString ++ envelopename.asString;
						SynthDef(synthdefname,{
							arg vel = 1.00,
							toneAmp = 1.0,
							tonePitch = 50,
							toneSpectra = 0,
							toneBend = 0,
							toneBendTime = 0.5,
							toneFilterFreq = 1000,
							toneDynFilter = 0,
							toneDynFilterTime = 0.5,
							out = 0;

							var toneFreq = tonePitch.midicps;
							var dynBendExpRange = 2.pow(toneBend/12);
							var dynBendFreq = Clip.kr(dynBendExpRange*toneFreq,20,20000);
							var dynBendDiff = (dynBendFreq-toneFreq)/toneFreq;
							var dynBendEnv = XLine.kr(1+(dynBendDiff*vel),1,toneBendTime);

							var wave = SynthDef.wrap(
								wavefunction,
								prependArgs: [dynBendEnv, toneFreq, toneSpectra]
							);

							var ampEnvelope = SynthDef.wrap(
								envelopefunction,
								prependArgs: [vel]
							);

							var unfiltered = wave * ampEnvelope * toneAmp * vel;

							var dynFilterExpRange = 2.pow(toneDynFilter/12);
							var dynFilterFreq = Clip.kr(dynFilterExpRange*toneFilterFreq,20,20000);
							var dynFilterDiff = dynFilterFreq-toneFilterFreq;
							var dynFilterEnv = XLine.kr(toneFilterFreq+(dynFilterDiff*vel),toneFilterFreq,toneDynFilterTime);

							var signal = BLowPass.ar(unfiltered, dynFilterEnv, 1);

							Out.ar(out,signal);
						}).add;
					};
				};

				clicks.keysValuesDo{arg clickname, clickfunction;
					var synthdefname = "click" ++ clickname.asString;
					SynthDef(synthdefname,{
						arg vel = 1.00,
						clickAmp = 1.0,
						out = 0;

						var pulse = SynthDef.wrap(
							clickfunction,
							prependArgs: [vel]
						);

						var env = Env.perc(0.00,0.03,clickAmp).kr(doneAction: 2);
						var signal = pulse * env;
						Out.ar(out,signal);
					}).add;
				};

				//master bus
				SynthDef("channelStrip",{
					arg mix = 50,
					noise,
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
					var signal = SelectX.ar(mix/100,[toneSignal,noiseSignal]);
					signal = Mix.ar([signal,clickSignal]);
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
			\noiseAmp, 1.0,
			\noiseFilterType, 1,
			\noiseFilterFreq, 1000,
			\noiseDynFilter, 0,
			\noiseDynFilterTime, 0.5,
			\noiseFilterResonance, 0,
			\noiseAmpEnvelope, 1,
			\noiseAttack, 0.01,
			\noiseDecay, 0.5,
			\noiseDynDecay, 0.5,
			\toneAmp, 1.0,
			\toneWaveType, 1,
			\tonePitch, 60,
			\toneSpectra, 0,
			\toneBend, 0,
			\toneBendTime, 0.5,
			\toneFilterFreq, 1000,
			\toneDynFilter, 0,
			\toneDynFilterTime, 0.5,
			\toneAmpEnvelope, 1,
			\toneAttack, 0.01,
			\toneDecay, 0.5,
			\toneDynDecay, 0.5,
			\clickType, 1,
			\clickAmp, 1.0,
			\mix, 50,
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

		Synth.new("tone"++channelParams[channelKey][\toneWaveType].asInteger++channelParams[channelKey][\toneAmpEnvelope].asInteger,[\out, toneBus[channelKey], \vel, vel] ++ channelParams[channelKey].getPairs, channels[channelKey]);

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