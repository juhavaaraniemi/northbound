-- Northbound 0.1

local Northbound = {}
local MusicUtil = require "musicutil"

local ControlSpec = require "controlspec"
local Formatters = require "formatters"

local options = {}
options.noiseFilter = {"LP12","LP24","HP12","HP24","BP6","BP12"}
options.ampEnvelope = {"Exp","Lin","Gate"}
options.waveType = {"Analog","FM","Drumhead","Cymbal"}
options.analogWaves = {"Sine","Tri","Saw","Square","Pulse"}
options.fmWaves = {"Alg 1","Alg 2","Alg 3","Alg 4","Alg 5"}
options.drumheadWaves = {"Bass Drum","Snare"}
options.cymbalWaves = {"Cymbal 1","Cymbal 2"}
options.click = {"White Noise","Pink Noise","Brown Noise","Pulse 1","Pulse 2","Pulse 3"}
options.ratios = {0.51,0.71,0.78,0.87,1.00,1.41,1.57,1.73,2.00,2.82,3.00,3.14,3.46,4.00,4.24,4.71,5.00,5.19,5.65,6.00,6.28,6.92,7.00,7.07,7.85,8.00,8.48,8.65,9.00,9.42,9.89,10.00,10.38,10.99,11.00,11.30,12.00,12.11,12.56,12.72,13.00,13.84,14.00,14.10,14.13,15.00,15.55,15.57,15.70,16.96,17.27,17.30,18.37,18.84,19.03,19.78,20.41,20.76,21.20,21.98,22.49,23.55,24.22,25.95}

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
specs.pitch = ControlSpec.new(0, 127.5, "lin", 0.5, 60, "st")
specs.spectra = ControlSpec.new(0, 100, "lin", 1, 50, "")
specs.noiseDynFilter = ControlSpec.new(-50, 50, "lin", 1, 0, "")
specs.toneDynFilter = ControlSpec.new(0, 50, "lin", 1, 0, "")
specs.bend = ControlSpec.new(-50, 50, "lin", 1, 0, "")
specs.fmRatio = ControlSpec.new(0, 26, "lin", 1, 0, "")
specs.fmIndex = ControlSpec.new(0, 1, "lin", 0, 1, "")
specs.fmFeedback = ControlSpec.new(0, 10, "lin", 0, 0, "")
specs.reverb = ControlSpec.new(0, 100, "lin", 1, 0, "")

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
  params:add_separator("NORTHBOUND ENGINE")

  --common for midi mapping
  params:add_group("COMMON",47)
  --channel select for common
  params:add{type = "number", id = "channelSelect", name = "Channel Select", min = 1, max = 8, default = 1,
    action=function(value) 
      params:set("noiseFilterType",params:get(value.."noiseFilterType"))
      params:set("noiseFilterResonance",params:get(value.."noiseFilterResonance"))
      params:set("noiseFreq",params:get(value.."noiseFreq"))
      params:set("noiseDynFilter",params:get(value.."noiseDynFilter"))
      params:set("noiseAmpEnvelope",params:get(value.."noiseAmpEnvelope"))
      params:set("noiseAttack",params:get(value.."noiseAttack"))
      params:set("noiseDecay",params:get(value.."noiseDecay"))
      params:set("noiseDynDecay",params:get(value.."noiseDynDecay"))
      params:set("toneWaveType",params:get(value.."toneWaveType"))
      params:set("analogWaves",params:get(value.."analogWaves"))
      params:set("fmWaves",params:get(value.."fmWaves"))
      params:set("drumheadWaves",params:get(value.."drumheadWaves"))
      params:set("cymbalWaves",params:get(value.."cymbalWaves"))
      params:set("fmRatio1",params:get(value.."fmRatio1"))
      params:set("fmRatio2",params:get(value.."fmRatio2"))
      params:set("fmRatio3",params:get(value.."fmRatio3"))
      params:set("fmIndex1",params:get(value.."fmIndex1"))
      params:set("fmIndex2",params:get(value.."fmIndex2"))
      params:set("fmIndex3",params:get(value.."fmIndex3"))
      params:set("fmFeedback",params:get(value.."fmFeedback"))
      params:set("toneSpectra",params:get(value.."toneSpectra"))
      params:set("toneFreq",params:get(value.."toneFreq"))
      params:set("toneDynFilter",params:get(value.."toneDynFilter"))
      params:set("toneAmpEnvelope",params:get(value.."toneAmpEnvelope"))
      params:set("toneAttack",params:get(value.."toneAttack"))
      params:set("toneDecay",params:get(value.."toneDecay"))
      params:set("toneDynDecay",params:get(value.."toneDynDecay"))
      params:set("tonePitch",params:get(value.."tonePitch"))
      params:set("toneBendTime",params:get(value.."toneBendTime"))
      params:set("clickType",params:get(value.."clickType"))
      params:set("clickAmp",params:get(value.."clickAmp"))
      params:set("noiseAmp",params:get(value.."noiseAmp"))
      params:set("toneAmp",params:get(value.."toneAmp"))
      params:set("distAmt",params:get(value.."distAmt"))
      params:set("eqFreq",params:get(value.."eqFreq"))
      params:set("eqGain",params:get(value.."eqGain"))
      params:set("pan",params:get(value.."pan"))
      params:set("level",params:get(value.."level"))
      params:set("reverb",params:get(value.."reverb"))
      
    end}
  
  params:add_separator("Noise")
  params:add{type = "option", id = "noiseFilterType", name = "Filter Type", options = options.noiseFilter, 1, action=function(value) params:set(params:get("channelSelect").."noiseFilterType",value) end}
  params:add{type = "control", id = "noiseFilterResonance", name = "Noise Filter Resonance", controlspec = specs.filterResonance, action=function(value) params:set(params:get("channelSelect").."noiseFilterResonance",value) end}
  params:add{type = "control", id = "noiseFreq", name = "Freq", controlspec = specs.freq, action=function(value) params:set(params:get("channelSelect").."noiseFreq",value) end}
  params:add{type = "control", id = "noiseDynFilter", name = "Dynamic Filter", controlspec = specs.noiseDynFilter, action=function(value) params:set(params:get("channelSelect").."noiseDynFilter",value) end}
  params:add{type = "option", id = "noiseAmpEnvelope", name = "Amp Envelope", options = options.ampEnvelope, 1, action=function(value) params:set(params:get("channelSelect").."noiseAmpEnvelope",value) end}
  params:add{type = "control", id = "noiseAttack", name = "Attack", controlspec = specs.attack, action=function(value) params:set(params:get("channelSelect").."noiseAttack",value) end}
  params:add{type = "control", id = "noiseDecay", name = "Decay (min vel)", controlspec = specs.decay, action=function(value) params:set(params:get("channelSelect").."noiseDecay",value) end}
  params:add{type = "control", id = "noiseDynDecay", name = "Decay (max vel)", controlspec = specs.decay, action=function(value) params:set(params:get("channelSelect").."noiseDynDecay",value) end}
  
  params:add_separator("Tone")
  params:add{type = "option", id = "toneWaveType", name = "Wave Type", options = options.waveType, 1, 
    action=function(value) 
      params:set(params:get("channelSelect").."toneWaveType",value)
      if value == 1 then
        params:show("analogWaves")
        params:set("analogWaves",1)
        params:hide("fmWaves")
        params:hide("drumheadWaves")
        params:hide("cymbalWaves")
        params:hide("fmWaves")
        params:hide("fmRatio1")
        params:hide("fmRatio2")
        params:hide("fmRatio3")
        params:hide("fmIndex1")
        params:hide("fmIndex2")
        params:hide("fmIndex3")
        params:hide("fmFeedback")
        params:show("toneSpectra")
        params:show("toneFreq")
      elseif value == 2 then
        params:show("fmWaves")
        params:set("fmWaves",1)
        params:hide("analogWaves")
        params:hide("drumheadWaves")
        params:hide("cymbalWaves")
        params:show("fmRatio1")
        params:show("fmRatio2")
        params:show("fmRatio3")
        params:show("fmIndex1")
        params:show("fmIndex2")
        params:show("fmIndex3")
        params:show("fmFeedback")
        params:hide("toneSpectra")
        params:hide("toneFreq")
      elseif value == 3 then
        params:show("drumheadWaves")
        params:set("drumheadWaves",1)
        params:hide("analogWaves")
        params:hide("fmWaves")
        params:hide("cymbalWaves")
        params:hide("fmWaves")
        params:hide("fmRatio1")
        params:hide("fmRatio2")
        params:hide("fmRatio3")
        params:hide("fmIndex1")
        params:hide("fmIndex2")
        params:hide("fmIndex3")
        params:hide("fmFeedback")
        params:show("toneSpectra")
        params:show("toneFreq")
      elseif value == 4 then
        params:show("cymbalWaves")
        params:set("cymbalWaves",1)
        params:hide("analogWaves")
        params:hide("fmWaves")
        params:hide("drumheadWaves")
        params:hide("fmWaves")
        params:hide("fmRatio1")
        params:hide("fmRatio2")
        params:hide("fmRatio3")
        params:hide("fmIndex1")
        params:hide("fmIndex2")
        params:hide("fmIndex3")
        params:hide("fmFeedback")
        params:show("toneSpectra")
        params:show("toneFreq")
      end
      _menu.rebuild_params()
      --params:set(params:get("channelSelect").."toneWave",1)
    end}
  params:add{type = "option", id = "analogWaves", name = "Wave", options = options.analogWaves, 1, action=function(value) params:set(params:get("channelSelect").."analogWaves",value) end}
  params:add{type = "option", id = "fmWaves", name = "Wave", options = options.fmWaves, 1, action=function(value) params:set(params:get("channelSelect").."fmWaves",value) end}
  params:add{type = "option", id = "drumheadWaves", name = "Wave", options = options.drumheadWaves, 1, action=function(value) params:set(params:get("channelSelect").."drumheadWaves",value) end}
  params:add{type = "option", id = "cymbalWaves", name = "Wave", options = options.cymbalWaves, 1, action=function(value) params:set(params:get("channelSelect").."cymbalWaves",value) end}

  --fm
  params:add{type = "option", id = "fmRatio1", name = "Fm Ratio 1", options = options.ratios, action=function(value) params:set(params:get("channelSelect").."fmRatio1",value) end}
  params:add{type = "option", id = "fmRatio2", name = "Fm Ratio 2", options = options.ratios, action=function(value) params:set(params:get("channelSelect").."fmRatio2",value) end}
  params:add{type = "option", id = "fmRatio3", name = "Fm Ratio 3", options = options.ratios, action=function(value) params:set(params:get("channelSelect").."fmRatio3",value) end}
  params:add{type = "control", id = "fmIndex1", name = "Fm Index 1", controlspec = specs.fmIndex, action=function(value) params:set(params:get("channelSelect").."fmIndex1",value) end}
  params:add{type = "control", id = "fmIndex2", name = "Fm Index 2", controlspec = specs.fmIndex, action=function(value) params:set(params:get("channelSelect").."fmIndex2",value) end}
  params:add{type = "control", id = "fmIndex3", name = "Fm Index 3", controlspec = specs.fmIndex, action=function(value) params:set(params:get("channelSelect").."fmIndex3",value) end}
  params:add{type = "control", id = "fmFeedback", name = "Fm Feedback", controlspec = specs.fmFeedback, action=function(value) params:set(params:get("channelSelect").."fmFeedback",value) end}
  
  --analog
  params:add{type = "control", id = "toneSpectra", name = "Spectra", controlspec = specs.spectra, action=function(value) params:set(params:get("channelSelect").."toneSpectra",value) end}
  params:add{type = "control", id = "toneFreq", name = "Freq", controlspec = specs.freq, action=function(value) params:set(params:get("channelSelect").."toneFreq",value) end}
  params:add{type = "control", id = "toneDynFilter", name = "Dynamic Filter", controlspec = specs.toneDynFilter, action=function(value) params:set(params:get("channelSelect").."toneDynFilter",value) end}
  
  --common
  params:add{type = "option", id = "toneAmpEnvelope", name = "Amp Envelope", options = options.ampEnvelope, 1, action=function(value) params:set(params:get("channelSelect").."toneAmpEnvelope",value) end}
  params:add{type = "control", id = "toneAttack", name = "Attack", controlspec = specs.attack, action=function(value) params:set(params:get("channelSelect").."toneAttack",value) end}
  params:add{type = "control", id = "toneDecay", name = "Decay (min vel)", controlspec = specs.decay, action=function(value) params:set(params:get("channelSelect").."toneDecay",value) end}
  params:add{type = "control", id = "toneDynDecay", name = "Decay (max vel)", controlspec = specs.decay, action=function(value) params:set(params:get("channelSelect").."toneDynDecay",value) end}
  params:add{type = "control", id = "tonePitch", name = "Pitch", controlspec = specs.pitch, action=function(value) params:set(params:get("channelSelect").."tonePitch",value) end}
  params:add{type = "control", id = "toneBendTime", name = "Bend Time", controlspec = specs.decay, action=function(value) params:set(params:get("channelSelect").."toneBendTime",value) end}
  
  params:add_separator("Click")
  params:add{type = "option", id = "clickType", name = "Click Type", options = options.click, 1, action=function(value) params:set(params:get("channelSelect").."clickType",value) end}
  params:add{type = "control", id = "clickAmp", name = "Amp", controlspec = specs.amp, action=function(value) params:set(params:get("channelSelect").."clickAmp",value) end}
  
  params:add_separator("Mix")
  params:add{type = "control", id = "noiseAmp", name = "Noise Amp", controlspec = specs.amp, action=function(value) params:set(params:get("channelSelect").."noiseAmp",value) end}
  params:add{type = "control", id = "toneAmp", name = "Tone Amp", controlspec = specs.amp, action=function(value) params:set(params:get("channelSelect").."toneAmp",value) end}
  params:add{type = "control", id = "distAmt", name = "Distortion Amount", controlspec = specs.dist, action=function(value) params:set(params:get("channelSelect").."distAmt",value) end}
  params:add{type = "control", id = "eqFreq", name = "Eq Freq", controlspec = specs.eqFreq, action=function(value) params:set(params:get("channelSelect").."eqFreq",value) end}
  params:add{type = "control", id = "eqGain", name = "Eq Gain", controlspec = specs.gain, action=function(value) params:set(params:get("channelSelect").."eqGain",value) end}
  params:add{type = "control", id = "pan", name = "Pan", controlspec = specs.pan, action=function(value) params:set(params:get("channelSelect").."pan",value) end}
  params:add{type = "control", id = "level", name = "Level", controlspec = specs.level, action=function(value) params:set(params:get("channelSelect").."level",value) end}
  params:add{type = "control", id = "reverb", name = "Reverb", controlspec = specs.reverb, action=function(value) params:set(params:get("channelSelect").."reverb",value) end}
  params:add_separator("Actions")
  params:add {type="binary",id="reset",name="Reset channel",behavior="trigger",action=function() reset_channel(params:get("channelSelect")) end}
  params:add {type="binary",id="copy",name="Copy channel to destination",behavior="trigger",action=function() copy_channel(params:get("channelSelect")) end}
  params:add {type="number",id="targetChannel",name="Copy destination channel",min=1,max=8,default=1}
  
  --individual channels
  for i=1,8 do
    params:add_group("CHANNEL "..i,48)

    params:add_separator("Noise")
    params:add{type = "option", id = i.."noiseFilterType", name = "Filter Type", options = options.noiseFilter, 1, action=function(value) engine.noiseFilterType(i,value) end}
    params:add{type = "control", id = i.."noiseFilterResonance", name = "Noise Filter Resonance", controlspec = specs.filterResonance, action=function(value) engine.noiseFilterResonance(i,value) end}
    params:add{type = "control", id = i.."noiseFreq", name = "Freq", controlspec = specs.freq, action=function(value) engine.noiseFreq(i,value) end}
    params:add{type = "control", id = i.."noiseDynFilter", name = "Dynamic Filter", controlspec = specs.noiseDynFilter, action=function(value) engine.noiseDynFilter(i,value) end}
    params:add{type = "option", id = i.."noiseAmpEnvelope", name = "Amp Envelope", options = options.ampEnvelope, 1, action=function(value) engine.noiseAmpEnvelope(i,value) end}
    params:add{type = "control", id = i.."noiseAttack", name = "Attack", controlspec = specs.attack, action=function(value) engine.noiseAttack(i,value) end}
    params:add{type = "control", id = i.."noiseDecay", name = "Decay (min vel)", controlspec = specs.decay, action=function(value) engine.noiseDecay(i,value) end}
    params:add{type = "control", id = i.."noiseDynDecay", name = "Decay (max vel)", controlspec = specs.decay, action=function(value) engine.noiseDynDecay(i,value) end}
    
    params:add_separator("Tone")
    params:add{type = "option", id = i.."toneWaveType", name = "Wave Type", options = options.waveType, 1, 
      action=function(value) 
        engine.toneWaveType(i,value)
        if value == 1 then
          params:show(i.."analogWaves")
          params:set(i.."analogWaves",1)
          params:hide(i.."fmWaves")
          params:hide(i.."drumheadWaves")
          params:hide(i.."cymbalWaves")
          params:hide(i.."fmWaves")
          params:hide(i.."fmRatio1")
          params:hide(i.."fmRatio2")
          params:hide(i.."fmRatio3")
          params:hide(i.."fmIndex1")
          params:hide(i.."fmIndex2")
          params:hide(i.."fmIndex3")
          params:hide(i.."fmFeedback")
          params:show(i.."toneSpectra")
          params:show(i.."toneFreq")
        elseif value == 2 then
          params:show(i.."fmWaves")
          params:set(i.."fmWaves",1)
          params:hide(i.."analogWaves")
          params:hide(i.."drumheadWaves")
          params:hide(i.."cymbalWaves")
          params:show(i.."fmRatio1")
          params:show(i.."fmRatio2")
          params:show(i.."fmRatio3")
          params:show(i.."fmIndex1")
          params:show(i.."fmIndex2")
          params:show(i.."fmIndex3")
          params:show(i.."fmFeedback")
          params:hide(i.."toneSpectra")
          params:hide(i.."toneFreq")
        elseif value == 3 then
          params:show(i.."drumheadWaves")
          params:set(i.."drumheadWaves",1)
          params:hide(i.."analogWaves")
          params:hide(i.."fmWaves")
          params:hide(i.."cymbalWaves")
          params:hide(i.."fmWaves")
          params:hide(i.."fmRatio1")
          params:hide(i.."fmRatio2")
          params:hide(i.."fmRatio3")
          params:hide(i.."fmIndex1")
          params:hide(i.."fmIndex2")
          params:hide(i.."fmIndex3")
          params:hide(i.."fmFeedback")
          params:show(i.."toneSpectra")
          params:show(i.."toneFreq")
        elseif value == 4 then
          params:show(i.."cymbalWaves")
          params:set(i.."cymbalWaves",1)
          params:hide(i.."analogWaves")
          params:hide(i.."fmWaves")
          params:hide(i.."drumheadWaves")
          params:hide(i.."fmWaves")
          params:hide(i.."fmRatio1")
          params:hide(i.."fmRatio2")
          params:hide(i.."fmRatio3")
          params:hide(i.."fmIndex1")
          params:hide(i.."fmIndex2")
          params:hide(i.."fmIndex3")
          params:hide(i.."fmFeedback")
          params:show(i.."toneSpectra")
          params:show(i.."toneFreq")
        end
        engine.toneWave(i,1)
        _menu.rebuild_params()
      end}
    params:add{type = "option", id = i.."analogWaves", name = "Wave", options = options.analogWaves, 1, action=function(value) engine.toneWave(i,value) end}
    params:add{type = "option", id = i.."fmWaves", name = "Wave", options = options.fmWaves, 1, action=function(value) engine.toneWave(i,value) end}
    params:add{type = "option", id = i.."drumheadWaves", name = "Wave", options = options.drumheadWaves, 1, action=function(value) engine.toneWave(i,value) end}
    params:add{type = "option", id = i.."cymbalWaves", name = "Wave", options = options.cymbalWaves, 1, action=function(value) engine.toneWave(i,value) end}

    --fm
    params:add{type = "option", id = i.."fmRatio1", name = "Fm Ratio 1", options = options.ratios, action=function(value) engine.fmRatio1(i,options.ratios[value]) end}
    params:add{type = "option", id = i.."fmRatio2", name = "Fm Ratio 2", options = options.ratios, action=function(value) engine.fmRatio2(i,options.ratios[value]) end}
    params:add{type = "option", id = i.."fmRatio3", name = "Fm Ratio 3", options = options.ratios, action=function(value) engine.fmRatio3(i,options.ratios[value]) end}
    params:add{type = "control", id = i.."fmIndex1", name = "Fm Index 1", controlspec = specs.fmIndex, action=function(value) engine.fmIndex1(i,value) end}
    params:add{type = "control", id = i.."fmIndex2", name = "Fm Index 2", controlspec = specs.fmIndex, action=function(value) engine.fmIndex2(i,value) end}
    params:add{type = "control", id = i.."fmIndex3", name = "Fm Index 3", controlspec = specs.fmIndex, action=function(value) engine.fmIndex3(i,value) end}
    params:add{type = "control", id = i.."fmFeedback", name = "Fm Feedback", controlspec = specs.fmFeedback, action=function(value) engine.fmFeedback(i,value) end}
    
    --analog
    params:add{type = "control", id = i.."toneSpectra", name = "Spectra", controlspec = specs.spectra, action=function(value) engine.toneSpectra(i,value) end}
    params:add{type = "control", id = i.."toneFreq", name = "Freq", controlspec = specs.freq, action=function(value) engine.toneFreq(i,value) end}
    params:add{type = "control", id = i.."toneDynFilter", name = "Dynamic Filter", controlspec = specs.toneDynFilter, action=function(value) engine.toneDynFilter(i,value) end}
    
    --common
    params:add{type = "option", id = i.."toneAmpEnvelope", name = "Amp Envelope", options = options.ampEnvelope, 1, action=function(value) engine.toneAmpEnvelope(i,value) end}
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
    params:add{type = "control", id = i.."reverb", name = "Reverb", controlspec = specs.reverb, action=function(value) engine.reverbSend(i,value) end}
    params:add_separator("Actions")
    params:add {type="binary",id=i.."reset",name="Reset channel",behavior="trigger",action=function() reset_channel(i) end}
    params:add {type="binary",id=i.."copy",name="Copy channel to destination",behavior="trigger",action=function() copy_channel(i) end}
    params:add {type="number",id=i.."targetChannel",name="Copy destination channel",min=1,max=8,default=1}
  end
  
  params:bang()
end

return Northbound
