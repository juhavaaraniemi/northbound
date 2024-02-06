-- Northbound 0.1

local Northbound = {}
local MusicUtil = require "musicutil"

local ControlSpec = require "controlspec"
local Formatters = require "formatters"

local options = {}
options.noiseFilter = {"LP12", "LP24", "HP12", "HP24","BP6", "BP12"}
options.noiseAmpEnvelope = {"Exp", "Lin", "Gate"}
options.wave = {"Sine","Tri","Saw","Square","Pulse","Cymbal"}
options.toneAmpEnvelope = {"Exp", "Lin"}

local specs = {}
specs.freq = ControlSpec.new(20, 20000, "exp", 0, 100, "Hz")
specs.attack = ControlSpec.new(0.0, 3.0, "lin", 0, 0.01, "s")
specs.decay = ControlSpec.new(0.1, 10.0, "lin", 0, 0.5, "s")
specs.amp = ControlSpec.new(0, 1, "lin", 0, 1, "")
specs.bendTime = ControlSpec.new(0.00, 10.00, "lin", 0.1, 0.5, "")
specs.filterFreq = ControlSpec.new(20, 20000, "exp", 0, 20000, "Hz")
specs.filterResonance = ControlSpec.new(0, 20, "lin", 1, 0, "")
specs.mix = ControlSpec.new(0, 100, "lin", 1, 50, "%")
specs.dist = ControlSpec.new(0, 100, "lin", 1, 0, "")
specs.gain = ControlSpec.new(-40, 40, "lin", 0, 0, "")
specs.pan = ControlSpec.PAN
specs.level = ControlSpec.new(-60, 10, "lin", 0, 0, "dB")
specs.pitch = ControlSpec.new(0, 127, "lin", 1, 60, "st")
specs.spectra = ControlSpec.new(0, 99, "lin", 1, 0, "")
specs.dynFilter = ControlSpec.new(-50, 50, "lin", 1, 0, "")

local function bipolar_to_freq(value)
  value = util.linlin(-9,9,-3,3,value)
  if value == 0 then
    return 1
  elseif value < 0 then
    return -1/value
  else
    return 1*value
  end
end

function Northbound.add_params()
  params:add_separator("NORTHBOUND")
  for i=1,8 do
    params:add_group("CHANNEL "..i,30)
    params:add_separator("Tone")
    params:add{type = "option", id = i.."toneWaveType", name = "Wave", options = options.wave, 1, action=function(value) engine.toneWaveType(i,value) end}
    params:add{type = "option", id = i.."toneAmpEnvelope", name = "Amp Envelope", options = options.toneAmpEnvelope, 1, action=function(value) engine.toneAmpEnvelope(i,value) end}
    params:add{type = "control", id = i.."tonePitch", name = "Pitch", controlspec = specs.pitch, action=function(value) engine.tonePitch(i,value) end}
    params:add{type = "control", id = i.."toneSpectra", name = "Spectra", controlspec = specs.spectra, action=function(value) engine.toneSpectra(i,value) end}
    params:add{type = "control", id = i.."toneAttack", name = "Attack", controlspec = specs.attack, action=function(value) engine.toneAttack(i,value) end}
    params:add{type = "control", id = i.."toneDecay", name = "Decay (min vel)", controlspec = specs.decay, action=function(value) engine.toneDecay(i,value) end}
    params:add{type = "control", id = i.."toneDynDecay", name = "Decay (max vel)", controlspec = specs.decay, action=function(value) engine.toneDynDecay(i,value) end}
    params:add{type = "control", id = i.."toneAmp", name = "Amp", controlspec = specs.amp, action=function(value) engine.toneAmp(i,value) end}
    params:add{type = "control", id = i.."toneFilterFreq", name = "Filter Freq", controlspec = specs.filterFreq, action=function(value) engine.toneFilterFreq(i,value) end}
    params:add{type = "control", id = i.."toneDynFilter", name = "Dynamic Filter", controlspec = specs.dynFilter, action=function(value) engine.toneDynFilter(i,value) end}
    params:add{type = "control", id = i.."toneBend", name = "Bend", controlspec = specs.dynFilter, action=function(value) engine.toneBend(i,value) end}
    params:add{type = "control", id = i.."toneBendTime", name = "Bend Time", controlspec = specs.bendTime, action=function(value) engine.toneBendTime(i,value) end}
    params:add_separator("Noise")
    params:add{type = "option", id = i.."noiseFilterType", name = "Filter Type", options = options.noiseFilter, 1, action=function(value) engine.noiseFilterType(i,value) end}
    params:add{type = "option", id = i.."noiseAmpEnvelope", name = "Amp Envelope", options = options.noiseAmpEnvelope, 1, action=function(value) engine.noiseAmpEnvelope(i,value) end}
    params:add{type = "control", id = i.."noiseAttack", name = "Attack", controlspec = specs.attack, action=function(value) engine.noiseAttack(i,value) end}
    params:add{type = "control", id = i.."noiseDecay", name = "Decay (min vel)", controlspec = specs.decay, action=function(value) engine.noiseDecay(i,value) end}
    params:add{type = "control", id = i.."noiseDynDecay", name = "Decay (max vel)", controlspec = specs.decay, action=function(value) engine.noiseDynDecay(i,value) end}
    params:add{type = "control", id = i.."noiseAmp", name = "Amp", controlspec = specs.amp, action=function(value) engine.noiseAmp(i,value) end}
    params:add{type = "control", id = i.."noiseFilterFreq", name = "Filter Freq", controlspec = specs.filterFreq, action=function(value) engine.noiseFilterFreq(i,value) end}
    params:add{type = "control", id = i.."noiseDynFilter", name = "Dynamic Filter", controlspec = specs.dynFilter, action=function(value) engine.noiseDynFilter(i,value) end}
    params:add{type = "control", id = i.."noiseFilterResonance", name = "Noise Filter Resonance", controlspec = specs.filterResonance, action=function(value) engine.noiseFilterResonance(i,value) end}
    params:add_separator("Mix")
    params:add{type = "control", id = i.."mix", name = "Tone/Noise Mix", controlspec = specs.mix, action=function(value) engine.mix(i,value) end}
    params:add{type = "control", id = i.."distAmt", name = "Distortion Amount", controlspec = specs.dist, action=function(value) engine.distAmt(i,value) end}
    params:add{type = "control", id = i.."eqFreq", name = "Eq Freq", controlspec = specs.freq, action=function(value) engine.eqFreq(i,value) end}
    params:add{type = "control", id = i.."eqGain", name = "Eq Gain", controlspec = specs.gain, action=function(value) engine.eqGain(i,value) end}
    params:add{type = "control", id = i.."pan", name = "Pan", controlspec = specs.pan, action=function(value) engine.pan(i,value) end}
    params:add{type = "control", id = i.."level", name = "Level", controlspec = specs.level, action=function(value) engine.level(i,value) end}
  end
  
  params:bang()
  
  params:add_group("TRIGGERS",8)
  for i=1,8 do
    params:add {type="binary",id=i.."channel",name="channel "..i,behavior="toggle",
      action=function()
        engine.trig(i,1)
      end
    }
  end
end

return Northbound