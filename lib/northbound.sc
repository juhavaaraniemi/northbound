// Northbound 0.1

Northbound {

	classvar <channelKeys;
	classvar <noiseFilters;
	classvar <noiseAmpEnvelopes;
	classvar <waves;
	classvar <toneAmpEnvelopes;

	var <globalParams;
	var <channelParams;
	var <channelGroup;
	var <channels;
	var <toneBus;
	var <noiseBus;

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
						Mix.ar([LFTri.ar(freq: toneFreq*pitchEnv, mul: 0.25),
							LFTri.ar(freq: toneFreq2*pitchEnv, mul: 0.25)])
					},
					3: {arg pitchEnv = 1, toneFreq = 200, toneSpectra = 0;
						var toneFreq2 = 2.pow(toneSpectra/120)*toneFreq;
						Mix.ar([LFSaw.ar(freq: toneFreq*pitchEnv, mul: 0.25),
							LFSaw.ar(freq: toneFreq2*pitchEnv, mul: 0.25)])
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
					6: {arg pitchEnv = 1, toneFreq = 800, toneSpectra = 0;
						var toneFreq2 = toneSpectra.linexp(0,99,254.3,627.2);
						var osc1 = Pulse.ar(205.3,0.5,0.15);
						var osc2 = Pulse.ar(369.6,0.5,0.15);
						var osc3 = Pulse.ar(304.4,0.5,0.15);
						var osc4 = Pulse.ar(522.7,0.5,0.15);
						var osc5 = Pulse.ar(toneFreq,0.5,0.15); // 359.4-1149.9 Hz, default: 800 Hz
						var osc6 = Pulse.ar(toneFreq2,0.5,0.15); // 254.3-627.2 Hz, default: 540 Hz
						var osc = Mix.ar([osc1,osc2,osc3,osc4,osc5,osc6]);
						var band1 = BPF.ar(osc,3440);
						var band2 = BPF.ar(osc,7100);
						var filterOsc = Mix.ar([band1,band2]);
						HPF.ar(filterOsc,10500,mul: 8)
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

				//master bus
				SynthDef("channelStrip",{
					arg mix = 50,
					noise,
					tone,
					distAmt = 2,
					eqFreq = 500,
					eqGain = 1,
					pan = 0,
					level = 0,
					out = 0;

					var toneSignal = In.ar(tone);
					var noiseSignal = In.ar(noise);

					// mix
					var signal = SelectX.ar(mix/100,[toneSignal,noiseSignal]);
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
		channelKeys.do({ arg channelKey;
			channels[channelKey] = Group.new(channelGroup);
			channelParams[channelKey] = Dictionary.newFrom(globalParams);
			toneBus[channelKey] = Bus.audio(s, 1);
			noiseBus[channelKey] = Bus.audio(s, 1);
			Synth("channelStrip", [\tone,toneBus[channelKey],\noise,noiseBus[channelKey]],channels[channelKey]);
		});
	}

	playVoice { arg channelKey, vel;
		channels[channelKey].set(\stopGate, -1.05);

		Synth.new("tone"++channelParams[channelKey][\toneWaveType].asInteger++channelParams[channelKey][\toneAmpEnvelope].asInteger,[\out, toneBus[channelKey], \vel, vel] ++ channelParams[channelKey].getPairs, channels[channelKey]);

		Synth.new("noise"++channelParams[channelKey][\noiseFilterType].asInteger++channelParams[channelKey][\noiseAmpEnvelope].asInteger,[\out, noiseBus[channelKey], \vel, vel] ++ channelParams[channelKey].getPairs, channels[channelKey]);
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