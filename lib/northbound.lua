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
options.drumheadWaves = {"Bass Drum","Snare","Side stick"}
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
specs.pitch = ControlSpec.new(0, 127, "lin", 1, 60, "st")
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

  --individual channels
  for i=1,8 do
    params:add_group("CHANNEL "..i,45)

    params:add_separator("ch"..i.."noise","Noise")
    params:add{type = "option", id = "ch"..i.."noiseFilterType", name = "Filter Type", options = options.noiseFilter, 1, action=function(value) engine.noiseFilterType(i,value) end}
    params:add{type = "control", id = "ch"..i.."noiseFilterResonance", name = "Noise Filter Resonance", controlspec = specs.filterResonance, action=function(value) engine.noiseFilterResonance(i,value) end}
    params:add{type = "control", id = "ch"..i.."noiseFreq", name = "Freq", controlspec = specs.freq, action=function(value) engine.noiseFreq(i,value) end}
    params:add{type = "control", id = "ch"..i.."noiseDynFilter", name = "Dynamic Filter", controlspec = specs.noiseDynFilter, action=function(value) engine.noiseDynFilter(i,value) end}
    params:add{type = "option", id = "ch"..i.."noiseAmpEnvelope", name = "Amp Envelope", options = options.ampEnvelope, 1, action=function(value) engine.noiseAmpEnvelope(i,value) end}
    params:add{type = "control", id = "ch"..i.."noiseAttack", name = "Attack", controlspec = specs.attack, action=function(value) engine.noiseAttack(i,value) end}
    params:add{type = "control", id = "ch"..i.."noiseDecay", name = "Decay (min vel)", controlspec = specs.decay, action=function(value) engine.noiseDecay(i,value) end}
    params:add{type = "control", id = "ch"..i.."noiseDynDecay", name = "Decay (max vel)", controlspec = specs.decay, action=function(value) engine.noiseDynDecay(i,value) end}
    
    params:add_separator("ch"..i.."tone","Tone")
    params:add{type = "option", id = "ch"..i.."toneWaveType", name = "Wave Type", options = options.waveType, 1, 
      action=function(value)
        engine.toneWaveType(i,value)
        local wave = params:lookup_param("ch"..i.."toneWave")
        if value == 1 then
          wave.options = options.analogWaves
          wave.count = #options.analogWaves
          wave.selected = 1
          params:hide("ch"..i.."fmRatio1")
          params:hide("ch"..i.."fmRatio2")
          params:hide("ch"..i.."fmRatio3")
          params:hide("ch"..i.."fmIndex1")
          params:hide("ch"..i.."fmIndex2")
          params:hide("ch"..i.."fmIndex3")
          params:hide("ch"..i.."fmFeedback")
          params:show("ch"..i.."toneSpectra")
          params:show("ch"..i.."toneFreq")
        elseif value == 2 then
          wave.options = options.fmWaves
          wave.count = #options.fmWaves
          wave.selected = 1
          params:show("ch"..i.."fmRatio1")
          params:show("ch"..i.."fmRatio2")
          params:show("ch"..i.."fmRatio3")
          params:show("ch"..i.."fmIndex1")
          params:show("ch"..i.."fmIndex2")
          params:show("ch"..i.."fmIndex3")
          params:show("ch"..i.."fmFeedback")
          params:hide("ch"..i.."toneSpectra")
          params:hide("ch"..i.."toneFreq")
        elseif value == 3 then
          wave.options = options.drumheadWaves
          wave.count = #options.drumheadWaves
          wave.selected = 1
          params:hide("ch"..i.."fmRatio1")
          params:hide("ch"..i.."fmRatio2")
          params:hide("ch"..i.."fmRatio3")
          params:hide("ch"..i.."fmIndex1")
          params:hide("ch"..i.."fmIndex2")
          params:hide("ch"..i.."fmIndex3")
          params:hide("ch"..i.."fmFeedback")
          params:show("ch"..i.."toneSpectra")
          params:show("ch"..i.."toneFreq")
        elseif value == 4 then
          wave.options = options.cymbalWaves
          wave.count = #options.cymbalWaves
          wave.selected = 1
          params:hide("ch"..i.."fmRatio1")
          params:hide("ch"..i.."fmRatio2")
          params:hide("ch"..i.."fmRatio3")
          params:hide("ch"..i.."fmIndex1")
          params:hide("ch"..i.."fmIndex2")
          params:hide("ch"..i.."fmIndex3")
          params:hide("ch"..i.."fmFeedback")
          params:show("ch"..i.."toneSpectra")
          params:show("ch"..i.."toneFreq")
        end
        engine.toneWave(i,1)
        _menu.rebuild_params()
      end}
    
    params:add{type = "option", id = "ch"..i.."toneWave", name = "Wave", options = options.analogWaves, 1, action=function(value) engine.toneWave(i,value) end}

    --fm
    params:add{type = "option", id = "ch"..i.."fmRatio1", name = "Fm Ratio 1", options = options.ratios, action=function(value) engine.fmRatio1(i,options.ratios[value]) end}
    params:add{type = "option", id = "ch"..i.."fmRatio2", name = "Fm Ratio 2", options = options.ratios, action=function(value) engine.fmRatio2(i,options.ratios[value]) end}
    params:add{type = "option", id = "ch"..i.."fmRatio3", name = "Fm Ratio 3", options = options.ratios, action=function(value) engine.fmRatio3(i,options.ratios[value]) end}
    params:add{type = "control", id = "ch"..i.."fmIndex1", name = "Fm Index 1", controlspec = specs.fmIndex, action=function(value) engine.fmIndex1(i,value) end}
    params:add{type = "control", id = "ch"..i.."fmIndex2", name = "Fm Index 2", controlspec = specs.fmIndex, action=function(value) engine.fmIndex2(i,value) end}
    params:add{type = "control", id = "ch"..i.."fmIndex3", name = "Fm Index 3", controlspec = specs.fmIndex, action=function(value) engine.fmIndex3(i,value) end}
    params:add{type = "control", id = "ch"..i.."fmFeedback", name = "Fm Feedback", controlspec = specs.fmFeedback, action=function(value) engine.fmFeedback(i,value) end}
    
    --analog
    params:add{type = "control", id = "ch"..i.."toneSpectra", name = "Spectra", controlspec = specs.spectra, action=function(value) engine.toneSpectra(i,value) end}
    params:add{type = "control", id = "ch"..i.."toneFreq", name = "Freq", controlspec = specs.freq, action=function(value) engine.toneFreq(i,value) end}
    params:add{type = "control", id = "ch"..i.."toneDynFilter", name = "Dynamic Filter", controlspec = specs.toneDynFilter, action=function(value) engine.toneDynFilter(i,value) end}
    
    --common
    params:add{type = "option", id = "ch"..i.."toneAmpEnvelope", name = "Amp Envelope", options = options.ampEnvelope, 1, action=function(value) engine.toneAmpEnvelope(i,value) end}
    params:add{type = "control", id = "ch"..i.."toneAttack", name = "Attack", controlspec = specs.attack, action=function(value) engine.toneAttack(i,value) end}
    params:add{type = "control", id = "ch"..i.."toneDecay", name = "Decay (min vel)", controlspec = specs.decay, action=function(value) engine.toneDecay(i,value) end}
    params:add{type = "control", id = "ch"..i.."toneDynDecay", name = "Decay (max vel)", controlspec = specs.decay, action=function(value) engine.toneDynDecay(i,value) end}
    params:add{type = "control", id = "ch"..i.."tonePitch", name = "Pitch", controlspec = specs.pitch, action=function(value) engine.tonePitch(i,value) end}
    params:add{type = "control", id = "ch"..i.."toneBend", name = "Bend", controlspec = specs.bend, action=function(value) engine.toneBend(i,value) end}
    params:add{type = "control", id = "ch"..i.."toneBendTime", name = "Bend Time", controlspec = specs.decay, action=function(value) engine.toneBendTime(i,value) end}
    
    params:add_separator("ch"..i.."click","Click")
    params:add{type = "option", id = "ch"..i.."clickType", name = "Click Type", options = options.click, 1, action=function(value) engine.clickType(i,value) end}
    params:add{type = "control", id = "ch"..i.."clickAmp", name = "Amp", controlspec = specs.amp, action=function(value) engine.clickAmp(i,value) end}
    
    params:add_separator("ch"..i.."mix","Mix")
    params:add{type = "control", id = "ch"..i.."noiseAmp", name = "Noise Amp", controlspec = specs.amp, action=function(value) engine.noiseAmp(i,value) end}
    params:add{type = "control", id = "ch"..i.."toneAmp", name = "Tone Amp", controlspec = specs.amp, action=function(value) engine.toneAmp(i,value) end}
    params:add{type = "control", id = "ch"..i.."distAmt", name = "Distortion Amount", controlspec = specs.dist, action=function(value) engine.distAmt(i,value) end}
    params:add{type = "control", id = "ch"..i.."eqFreq", name = "Eq Freq", controlspec = specs.eqFreq, action=function(value) engine.eqFreq(i,value) end}
    params:add{type = "control", id = "ch"..i.."eqGain", name = "Eq Gain", controlspec = specs.gain, action=function(value) engine.eqGain(i,value) end}
    params:add{type = "control", id = "ch"..i.."pan", name = "Pan", controlspec = specs.pan, action=function(value) engine.pan(i,value) end}
    params:add{type = "control", id = "ch"..i.."level", name = "Level", controlspec = specs.level, action=function(value) engine.level(i,value) end}
    params:add{type = "control", id = "ch"..i.."reverb", name = "Reverb", controlspec = specs.reverb, action=function(value) engine.reverbSend(i,value) end}
    
    params:add_separator("ch"..i.."actions","Actions")
    params:add {type="binary",id="ch"..i.."reset",name="Reset channel",behavior="trigger",action=function() reset_channel(i) end}
    params:add {type="binary",id="ch"..i.."copy",name="Copy channel to destination",behavior="trigger",action=function() copy_channel(i) end}
    params:add {type="number",id="ch"..i.."targetChannel",name="Copy destination channel",min=1,max=8,default=1}
  end
  
  params:bang()
end

function Northbound.update_wave_options(wave_param,value)
  local wave = params:lookup_param(wave_param)
  if value == 1 then
    wave.options = options.analogWaves
    wave.count = #options.analogWaves
  elseif value == 2 then
    wave.options = options.fmWaves
    wave.count = #options.fmWaves
  elseif value == 3 then
    wave.options = options.drumheadWaves
    wave.count = #options.drumheadWaves
  elseif value == 4 then
    wave.options = options.cymbalWaves
    wave.count = #options.cymbalWaves
  end
  wave.selected = 1
end



return Northbound
