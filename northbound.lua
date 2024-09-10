-- Northbound 0.1

--
-- LIBRARIES
--
Northbound = include 'lib/northbound'
engine.name="Northbound"
package.loaded["mftconf/lib/mftconf"] = nil
mftconf = require "mftconf/lib/mftconf"


--
-- VARIABLES
--
g = grid.connect()
grid_dirty = true
screen_dirty = true
PATH = _path.data.."northbound/"


--
-- INIT FUNCTIONS
--
function add_parameters()
  params:add_separator("NORTHBOUND")
  params:add_group("ROUTING",3)
  params:add{
    type = "number",
    id = "midi_in_device",
    name = "midi in device",
    min = 1,
    max = 16,
    default = 1,
    action = function(value)
      midi_in_device.event = nil
      midi_in_device = midi.connect(value)
      midi_in_device.event = midi_event
    end
  }
  params:add{
    type="number",
    id="midi_in_channel",
    name="midi in channel",
    min=1,
    max=16,
    default=1
  }
  params:add{
    type = "number",
    id = "midi_ctrl_device",
    name = "midi ctrl device",
    min = 1,
    max = 4,
    default = 2,
    action = function(value)
      midi_ctrl_device = midi.connect(value)
    end
  }
end

function init_grid_variables()
  counter = {}
  alt_x = nil
  alt_y = nil
  brightness = {}
  for x = 1,16 do
    counter[x] = {}
    brightness[x] = {}
    for y = 1,8 do
      counter[x][y] = nil
      brightness[x][y] = 15
    end
  end  
end


function init_midi_devices()
  midi_in_device = midi.connect(1)
  midi_in_device.event = midi_event
  midi_ctrl_device = midi.connect(2)
end

function init_ui_params()
  channel_params = {}
  plock = {}
  params:add_group("NORTHBOUND UI PARAMS",43)
  params:add_number("ui_channelSelect","Channel Select",1,8,1)
  
  --create ui params
  for i=1,params.count do
    local p = params:lookup_param(i)
    
    if string.sub(p.id,1,3) == "ch1" then
      local pid = string.sub(p.id,4)

      if p.t == 0 then
        params:add_separator("ui_"..pid,p.name)
      elseif p.t == 2 then
        params:add_option("ui_"..pid,p.name,p.options,p.default)
        params:set_action("ui_"..pid,function(value) store_param_values(pid,value) end)
      elseif p.t == 3 then
        params:add_control("ui_"..pid,p.name,p.controlspec)
        params:set_action("ui_"..pid,function(value) store_param_values(pid,value) end)
      end
    end
    
    -- create channel value store
    if string.sub(p.id,1,2) == "ch" then
      if p.t == 2 or p.t == 3 or p.t == 5 then
        channel_params[p.id] = params:get(p.id)
      end
    end
  end
end

function init_triggers()
  trig = {}
  local step
  local ch
  for step = 1,16 do
    trig[step] = {}
    for ch = 1,8 do
      trig[step][ch] = {}
      trig[step][ch]["on"] = 0
      trig[step][ch]["prob"] = 100
      trig[step][ch]["vel"] = 100
    end
  end
end

function init_ui_trigger_params()
  params:add_group("NORTHBOUND TRIGS",5)
  params:add_number("trig_step","Trig Step",1,16,1)
  params:add_number("trig_channel","Trig Channel",1,8,1)
  params:add_number("trig_on","Trig On",0,1,0)
  params:add_number("trig_prob","Trig Probability",0,100,100)
  params:add_number("trig_vel","Trig Velocity",0,127,100)
  
  params:set_action("trig_step",
    function(value)
      params:set("trig_on",trig[value][params:get("trig_channel")]["on"])
      params:set("trig_prob",trig[value][params:get("trig_channel")]["prob"])
      params:set("trig_vel",trig[value][params:get("trig_channel")]["vel"])
    end
  )
  params:set_action("trig_channel",
    function(value)
      params:set("trig_on",trig[params:get("trig_channel")][value]["on"])
      params:set("trig_prob",trig[params:get("trig_channel")][value]["prob"])
      params:set("trig_vel",trig[params:get("trig_channel")][value]["vel"])
    end
  )
  params:set_action("trig_on",
    function(value)
      trig[params:get("trig_step")][params:get("trig_channel")]["on"] = value
    end
  )
  params:set_action("trig_prob",
    function(value)
      trig[params:get("trig_step")][params:get("trig_channel")]["prob"] = value
    end
  )
  params:set_action("trig_vel",
    function(value)
      trig[params:get("trig_step")][params:get("trig_channel")]["vel"] = value
    end
  )
  
end

function init_param_actions()
  params:set_action("ui_channelSelect",
    function(value)
      for k,v in pairs(channel_params) do
        if tonumber(string.sub(k,3,3)) == value then
          params:set("ui_"..string.sub(k,4),v)
        end
      end
    end
  )
  params:set_action("ui_toneWaveType",
    function(value)
      Northbound.update_wave_options("ui_toneWave",value)
      store_param_values("toneWaveType",value)
      if value == 2 then
        params:show("ui_fmRatio1")
        params:show("ui_fmRatio2")
        params:show("ui_fmRatio3")
        params:show("ui_fmIndex1")
        params:show("ui_fmIndex2")
        params:show("ui_fmIndex3")
        params:show("ui_fmFeedback")
        params:hide("ui_toneSpectra")
        params:hide("ui_toneFreq")
      else
        params:hide("ui_fmRatio1")
        params:hide("ui_fmRatio2")
        params:hide("ui_fmRatio3")
        params:hide("ui_fmIndex1")
        params:hide("ui_fmIndex2")
        params:hide("ui_fmIndex3")
        params:hide("ui_fmFeedback")
        params:show("ui_toneSpectra")
        params:show("ui_toneFreq")
      end
      if value == 3 or value == 4 then
        params:hide("ui_toneBend")
        params:hide("ui_toneBendTime")
      else
        params:show("ui_toneBend")
        params:show("ui_toneBendTime")
      end
      _menu.rebuild_params()
    end
  )
  params:bang()
end

function init()
  init_midi_devices()
  Northbound.add_params()
  add_parameters()
  init_ui_params()
  init_triggers()
  init_ui_trigger_params()
  init_param_actions()
  init_grid_variables()
  init_pset_callbacks()
  --mftconf.load_conf(midi_ctrl_device,PATH.."mft_dd.mfs")
  --mftconf.refresh_values(midi_ctrl_device)
  clock.run(step)
  grid_redraw_metro = metro.init(grid_redraw_event,1/30,-1)
  grid_redraw_metro:start()
  redraw_metro = metro.init(redraw_event, 1/30, -1)
end


--
-- CALLBACK FUNCTIONS
--
function init_pset_callbacks()
  params.action_write = function(filename,name)
    print("finished writing '"..filename.."' as '"..name.."'")
    local channel_params_file = PATH..name.."_ch_params.data"
    local plock_file = PATH..name.."_plock.data"
    tab.save(channel_params, channel_params_file)
    tab.save(plock, plock_file)
  end
  
  params.action_read = function(filename)
    print("finished reading '"..filename.."'")
    local pset_file = io.open(filename, "r")
    if pset_file then
      io.input(pset_file)
      local pset_name = string.sub(io.read(), 4, -1)
      io.close(pset_file)
      local channel_params_file = PATH..pset_name.."_ch_params.data"
      local plock_file = PATH..pset_name.."_plock.data"
      channel_params = tab.load(channel_params_file)
      plock = tab.load(plock_file)
      params:set("ui_channelSelect",1)
      grid_dirty = true
    end
  end
end


--
-- CLOCK FUNCTIONS
--
function grid_redraw_event()
  if grid_dirty then
    grid_redraw()
    grid_dirty = false
  end
end

function redraw_event()
  if screen_dirty then
    redraw()
    screen_dirty = false
  end
end


--
-- STEP SEQUENCER
--
function step()
  local step = 1
  while true do
    clock.sync(1/4)
    local ch
    for ch=1,8 do
      if trig[step][ch]["on"] == 1 then
        --send params to engine
        set_params(ch,step)
        
        --if probability then trigger step
        if math.random(100) <= trig[step][ch]["prob"] then
          engine.trig(ch,trig[step][ch]["vel"]/127)
        end
      end
    end
    step = step + 1
    if step > 16 then
      step = 1
    end
  end
end


--
-- MIDI FUNCTIONS
--
function midi_event(data)
  local msg = midi.to_msg(data)
  if msg.ch == params:get("midi_in_channel") then
    if msg.type == "note_on" then
      print(msg.note..","..msg.vel/127)
      engine.trig(msg.note-35,msg.vel/127)
    end
  end
end


--
-- UI FUNCTIONS
--
function key(n,z)
  if z == 1 then
    if n == 2 then
      remove_plock()
    elseif n == 3 then
      remove_all_plocks()
    end
  end
end

function enc(n,d)
  if step_selected() then
    local ch
    local step
    ch, step = selected_step()
    if n == 1 then  
      --params:delta("prob"..ch..step,d)
    elseif n == 2 then
      --params:delta("vel"..ch..step,d)
    end
  end
  grid_dirty = true
end

function g.key(x,y,z)
  if z == 1 then
    counter[x][y] = clock.run(long_press,x,y)
  elseif z == 0 then
    if counter[x][y] then
      clock.cancel(counter[x][y])
      short_press(x,y)
    else
      long_release(x,y)
    end
  end
end

function short_press(x,y)
  flip_trig_state(x,y)
  params:set("ui_channelSelect",y)
  grid_dirty = true
end

function long_press(x,y)
  clock.sleep(0.25)
  alt_x = x
  alt_y = y
  counter[x][y] = nil
  params:set("ui_channelSelect",y)
  step_params_to_ui(x,y)
  grid_dirty = true
end

function long_release(x,y)
  alt_x = nil
  alt_y = nil
  params:set("ui_channelSelect",y)
  channel_params_to_ui(y)
  grid_dirty = true
end


--
-- HELPER FUNCTIONS
--
function step_params_to_ui(step,ch)
  for param, t in pairs(plock) do
    if plock[param][step] ~= nil then
      if tonumber(string.sub(param,3,3)) == ch then
        params:set("ui_"..string.sub(param,4),plock[param][step])
      end
    end
  end
end

function channel_params_to_ui(ch)
  for k,v in pairs(channel_params) do
    if tonumber(string.sub(k,3,3)) == ch then
      params:set("ui_"..string.sub(k,4),v)
    end
  end
end

function set_params(ch,step)
  for param, t in pairs(plock) do
    --if params exist for current ch
    if tonumber(string.sub(param,3,3)) == ch then
      --if plock for step exists send step params to engine
      if plock[param][step] ~= nil then
        params:set(param,plock[param][step])
      --if plock exists for param but not for step then send channel params to engine
      else
        params:set(param,channel_params[param])
      end
    end
  end
end

function store_param_values(pid,value)
  local eid = "ch"..params:get("ui_channelSelect")..pid
  if step_selected() then
    local ch
    local step 
    ch,step = selected_step()
    if plock[eid] ~= nil then
      plock[eid][step] = value
    else
      plock[eid] = {}
      plock[eid][step] = value
    end  
  else
    channel_params[eid] = value
    if plock[eid] == nil then
      params:set(eid,value)
    end
  end
end

function flip_trig_state(x,y)
  if trig[x][y]["on"] == 0 then
    trig[x][y]["on"] = 1
  else
    trig[x][y]["on"] = 0
  end
  params:set("trig_step",x)
  params:set("trig_channel",y)
  params:set("trig_on",trig[x][y]["on"])
end

function remove_plock()
  if step_selected() then
    -- this would need a number for finding last value
  end
end

function remove_all_plocks()
  if step_selected() then
    local ch
    local step
    ch, step = selected_step()
    for param, t in pairs(plock) do
      plock[param][step] = nil
    end
  end
  cleanup_plock()
end

function step_selected()
  if alt_x ~= nil and alt_y ~= nil then
    return true
  else 
    return false
  end
end

function selected_step()
  return alt_y, alt_x
end

function cleanup_plock()
  for param, t in pairs(plock) do
    if next(plock[param]) == nil then
      plock[param] = nil
    end
  end
end


--
-- REDRAW FUNCTIONS
--
function grid_redraw()
  g:all(0)
  for x=1,16 do
    for y=1,8 do
      if trig[x][y]["on"] == 1 then
        g:led(x,y,brightness[x][y])
      end
    end
  end
  g:refresh()
end

function redraw()
  screen.clear()
  screen.level(15)
  --screen.move(0,11)
  --screen.text("audio: "..params:string("audio"))
  --screen.move(0,18)
  --screen.text("midi: "..params:string("midi"))
  screen.move(0,28)
  --screen.text("last: "..last_param_name)
  screen.move(0,35)
  --screen.text("value: "..last_param_value)
  screen.move(0,46)
  --screen.text("transpose y: "..params:get("ytranspose"))
  --screen.move(0,53)
  --screen.text("root note: "..musicutil.note_num_to_name(params:get("root_note"), false))
  --screen.move(0,60)
  --screen.text("scale: "..scale_names[params:get("scale")])
  screen.update()
end
