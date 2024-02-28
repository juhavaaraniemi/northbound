-- Northbound 0.1

local Northbound = {}
local MusicUtil = require "musicutil"

local ControlSpec = require "controlspec"
local Formatters = require "formatters"

local options = {}
options.noiseFilter = {"LP12", "LP24", "HP12", "HP24","BP6", "BP12"}
options.noiseAmpEnvelope = {"Exp", "Lin", "Gate"}
options.waveType = {"Analog","FM","Drumhead","Cymbal"}
options.analogWaves = {"Sine","Tri","Saw","Square","Pulse"}
options.fmWaves = {"Alg 1","Alg 2","Alg 3","Alg 4","Alg 5"}
options.drumheadWaves = {"Bass Drum","Snare"}
options.cymbalWaves = {"Cymbal 1"}
options.toneAmpEnvelope = {"Exp", "Lin"}
options.click = {"White Noise","Pink Noise","Brown Noise","Pulse 1","Pulse 2","Pulse 3"}

local specs = {}
specs.eqFreq = ControlSpec.new(20, 20000, "exp", 0, 400, "Hz")
specs.freq = ControlSpec.new(0, 50, "lin", 1, 25, "")
specs.attack = ControlSpec.new(0.0, 3.0, "lin", 0, 0.01, "s")
specs.decay = ControlSpec.new(0.1, 10.0, "lin", 0, 0.5, "s")
specs.amp = ControlSpec.new(0, 50, "lin", 0, 50, "")
specs.filterResonance = ControlSpec.new(0, 20, "lin", 1, 0, "")
specs.mix = ControlSpec.new(0, 100, "lin", 1, 50, "%")
specs.dist = ControlSpec.new(0, 100, "lin", 1, 0, "")
specs.gain = ControlSpec.new(-40, 40, "lin", 0, 0, "")
specs.pan = ControlSpec.PAN
specs.level = ControlSpec.new(-60, 10, "lin", 0, 0, "dB")
specs.pitch = ControlSpec.new(0, 127, "lin", 0.5, 60, "st")
specs.spectra = ControlSpec.new(0, 100, "lin", 1, 50, "")
specs.noiseDynFilter = ControlSpec.new(-50, 50, "lin", 1, 0, "")
specs.toneDynFilter = ControlSpec.new(0, 50, "lin", 1, 0, "")
specs.bend = ControlSpec.new(-50, 50, "lin", 1, 0, "")

local function reset_channel(ch)
  for i=1,params.count do
    local p = params:lookup_param(i)
    local d = 0
    if string.sub(p.id,1,1) == tostring(ch) then
      print(p.id)
      if p.t == 3 then
        d = p.controlspec.default
      elseif p.t == 2 then
        d = p.default
      end
      params:set(p.id,d)
    end
  end
end

local function copy_channel(ch)
  local t = params:get(ch.."targetChannel")
  for i=1,params.count do
    local p = params:lookup_param(i)

    if string.sub(p.id,1,1) == tostring(ch) then
      local tp = t..string.sub(p.id,2,string.len(p.id))
      print(tp)
      if p.t == 3 or p.t == 2 then
        params:set(tp,params:get(p.id))
      end
    end
  end
end

function Northbound.add_params()
  params:add_separator("NORTHBOUND")
  for i=1,8 do
    params:add_group("CHANNEL "..i,40)

    params:add_separator("Noise")
    params:add{type = "option", id = i.."noiseFilterType", name = "Filter Type", options = options.noiseFilter, 1, action=function(value) engine.noiseFilterType(i,value) end}
    params:add{type = "control", id = i.."noiseFilterResonance", name = "Noise Filter Resonance", controlspec = specs.filterResonance, action=function(value) engine.noiseFilterResonance(i,value) end}
    params:add{type = "control", id = i.."noiseFreq", name = "Freq", controlspec = specs.freq, action=function(value) engine.noiseFreq(i,value) end}
    params:add{type = "control", id = i.."noiseDynFilter", name = "Dynamic Filter", controlspec = specs.noiseDynFilter, action=function(value) engine.noiseDynFilter(i,value) end}
    params:add{type = "option", id = i.."noiseAmpEnvelope", name = "Amp Envelope", options = options.noiseAmpEnvelope, 1, action=function(value) engine.noiseAmpEnvelope(i,value) end}
    params:add{type = "control", id = i.."noiseAttack", name = "Attack", controlspec = specs.attack, action=function(value) engine.noiseAttack(i,value) end}
    params:add{type = "control", id = i.."noiseDecay", name = "Decay (min vel)", controlspec = specs.decay, action=function(value) engine.noiseDecay(i,value) end}
    params:add{type = "control", id = i.."noiseDynDecay", name = "Decay (max vel)", controlspec = specs.decay, action=function(value) engine.noiseDynDecay(i,value) end}
    
    params:add_separator("Tone")
    params:add{type = "option", id = i.."toneWaveType", name = "Wave Type", options = options.waveType, 1, 
      action=function(value) 
        engine.toneWaveType(i,value)
        if value == 1 then
          params:show(i.."analogWaves")
          params:hide(i.."fmWaves")
          params:hide(i.."drumheadWaves")
          params:hide(i.."cymbalWaves")
          params:set(i.."analogWaves",1)
        elseif value == 2 then
          params:show(i.."fmWaves")
          params:hide(i.."analogWaves")
          params:hide(i.."drumheadWaves")
          params:hide(i.."cymbalWaves")
          params:set(i.."fmWaves",1)
        elseif value == 3 then
          params:show(i.."drumheadWaves")
          params:hide(i.."analogWaves")
          params:hide(i.."fmWaves")
          params:hide(i.."cymbalWaves")
          params:set(i.."drumheadWaves",1)
        elseif value == 4 then
          params:show(i.."cymbalWaves")
          params:hide(i.."analogWaves")
          params:hide(i.."fmWaves")
          params:hide(i.."drumheadWaves")
          params:set(i.."cymbalWaves",1)
        end
        engine.toneWave(i,1)
        _menu.rebuild_params()
      end}
    params:add{type = "option", id = i.."analogWaves", name = "Wave", options = options.analogWaves, 1, action=function(value) engine.toneWave(i,value) end}
    params:add{type = "option", id = i.."fmWaves", name = "Wave", options = options.fmWaves, 1, action=function(value) engine.toneWave(i,value) end}
    params:add{type = "option", id = i.."drumheadWaves", name = "Wave", options = options.drumheadWaves, 1, action=function(value) engine.toneWave(i,value) end}
    params:add{type = "option", id = i.."cymbalWaves", name = "Wave", options = options.cymbalWaves, 1, action=function(value) engine.toneWave(i,value) end}
    params:add{type = "control", id = i.."toneSpectra", name = "Spectra", controlspec = specs.spectra, action=function(value) engine.toneSpectra(i,value) end}
    params:add{type = "control", id = i.."toneFreq", name = "Freq", controlspec = specs.freq, action=function(value) engine.toneFreq(i,value) end}
    params:add{type = "control", id = i.."toneDynFilter", name = "Dynamic Filter", controlspec = specs.toneDynFilter, action=function(value) engine.toneDynFilter(i,value) end}
    params:add{type = "option", id = i.."toneAmpEnvelope", name = "Amp Envelope", options = options.toneAmpEnvelope, 1, action=function(value) engine.toneAmpEnvelope(i,value) end}
    params:add{type = "control", id = i.."toneAttack", name = "Attack", controlspec = specs.attack, action=function(value) engine.toneAttack(i,value) end}
    params:add{type = "control", id = i.."toneDecay", name = "Decay (min vel)", controlspec = specs.decay, action=function(value) engine.toneDecay(i,value) end}
    params:add{type = "control", id = i.."toneDynDecay", name = "Decay (max vel)", controlspec = specs.decay, action=function(value) engine.toneDynDecay(i,value) end}
    params:add{type = "control", id = i.."tonePitch", name = "Pitch", controlspec = specs.pitch, action=function(value) engine.tonePitch(i,value) end}
    params:add{type = "control", id = i.."toneBend", name = "Bend", controlspec = specs.bend, action=function(value) engine.toneBend(i,value) end}
    params:add{type = "control", id = i.."toneBendTime", name = "Bend Time", controlspec = specs.decay, action=function(value) engine.toneBendTime(i,value) end}
    
    params:add_separator("Click")
    params:add{type = "option", id = i.."clickType", name = "Click Type", options = options.click, 1, action=function(value) engine.clickType(i,value) end}
    params:add{type = "control", id = i.."clickAmp", name = "Amp", controlspec = specs.amp, action=function(value) engine.clickAmp(i,value) end}
    params:add_separator("Mix")
    params:add{type = "control", id = i.."noiseAmp", name = "Noise Amp", controlspec = specs.amp, action=function(value) engine.noiseAmp(i,value) end}
    params:add{type = "control", id = i.."toneAmp", name = "Tone Amp", controlspec = specs.amp, action=function(value) engine.toneAmp(i,value) end}
    params:add{type = "control", id = i.."distAmt", name = "Distortion Amount", controlspec = specs.dist, action=function(value) engine.distAmt(i,value) end}
    params:add{type = "control", id = i.."eqFreq", name = "Eq Freq", controlspec = specs.eqFreq, action=function(value) engine.eqFreq(i,value) end}
    params:add{type = "control", id = i.."eqGain", name = "Eq Gain", controlspec = specs.gain, action=function(value) engine.eqGain(i,value) end}
    params:add{type = "control", id = i.."pan", name = "Pan", controlspec = specs.pan, action=function(value) engine.pan(i,value) end}
    params:add{type = "control", id = i.."level", name = "Level", controlspec = specs.level, action=function(value) engine.level(i,value) end}
    params:add_separator("Actions")
    params:add {type="binary",id=i.."reset",name="Reset channel",behavior="trigger",action=function() reset_channel(i) end}
    params:add {type="binary",id=i.."copy",name="Copy channel to destination",behavior="trigger",action=function() copy_channel(i) end}
    params:add {type="number",id=i.."targetChannel",name="Copy destination channel",min=1,max=8,default=1}
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