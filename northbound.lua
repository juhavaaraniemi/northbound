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
  
  for i = 1,8 do
    params:add_group("SEQ CHANNEL "..i,48)
    for j = 1,16 do
      params:add{
        type = "number",
        id = "step"..i..j,
        name = "step "..j.." on",
        min = 0,
        max = 1,
        default = 0,
        action = function(value)
          if value == 1 then
            if params:get("prob"..i..j) == 0 then
              params:set("prob"..i..j,100)
            elseif params:get("vel"..i..j) == 0 then
              params:set("vel"..i..j,100)
            end
          end
        end
      }
      params:add{
        type = "number",
        id = "prob"..i..j,
        name = "step "..j.." probability",
        min = 0,
        max = 100,
        default = 100,
        action = function(value)
          if value == 0 then
            params:set("step"..i..j,0)
          end
          if params:get("step"..i..j) == 1 then
            --brightness[j][i] = math.ceil(value/100*15)
          end
        end
      }
      params:add{
        type = "number",
        id = "vel"..i..j,
        name = "step "..j.." velocity",
        min = 0,
        max = 127,
        default = 100,
        action = function(value)
          if value == 0 then
            params:set("step"..i..j,0)
          end
        end
      }
    end
  end
end

function init_grid_variables()
  global_alt = false
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

function init_param_actions()
  params:set_action("ui_channelSelect",
    function(value)
      for k,v in pairs(channel_params) do
        if tonumber(string.sub(k,3,3)) == value then
          print("ui_"..string.sub(k,4))
          params:set("ui_"..string.sub(k,4),v)
        end
      end
    end
  )
  params:set_action("ui_toneWaveType",
    function(value)
      Northbound.update_wave_options("ui_toneWave",value)
      store_param_values("toneWaveType",value)
    end
  )
end

function init()
  init_midi_devices()
  Northbound.add_params()
  add_parameters()
  init_ui_params()
  init_param_actions()
  init_grid_variables()
  --mftconf.load_conf(midi_ctrl_device,PATH.."mft_dd.mfs")
  --mftconf.refresh_values(midi_ctrl_device)
  clock.run(step)
  grid_redraw_metro = metro.init(grid_redraw_event,1/30,-1)
  grid_redraw_metro:start()
  redraw_metro = metro.init(redraw_event, 1/30, -1)
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
  step = 1
  while true do
    clock.sync(1/4)
    for ch=1,8 do
      if params:get("step"..ch..step) == 1 then
        --send params to engine
        set_params(ch,step)
        
        --if probability then trigger step
        if math.random(100) <= params:get("prob"..ch..step) then
          engine.trig(ch,params:get("vel"..ch..step)/127)
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
    ch, step = selected_step()
    if n == 1 then  
      params:delta("prob"..ch..step,d)
    elseif n == 2 then
      params:delta("vel"..ch..step,d)
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
  if params:get("step"..y..x) == 0 then
    params:set("step"..y..x,1)
  else
    params:set("step"..y..x,0)
  end
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
    --tab.print(plock)
    if plock[param][step] ~= nil then
      if string.sub(param,3,3) == ch then
        params:set("ui_"..string.sub(param,4),plock[param][step])
      end
    end
  end
end

--OK
function channel_params_to_ui(ch)
  for k,v in pairs(channel_params) do
    if tonumber(string.sub(k,3,3)) == ch then
      params:set("ui_"..string.sub(k,4),v)
    end
  end
end

--OK
function set_params(ch,step)
  for param, t in pairs(plock) do
    --if params exist for current ch
    if string.sub(param,3,3) == ch then
      --if plock for step exists send step params to engine
      if plock[param][step] ~= nil then
        params:set(param,plock[param][step])
      end
    --if plock exists for param but not for step then send channel params to engine
    else
      params:set(param,channel_params[param])
    end
  end
end

function store_param_values(pid,value)
  local eid = "ch"..params:get("ui_channelSelect")..pid
  if step_selected() then
    ch, step = selected_step()
    plock[eid] = {}
    plock[eid][step] = value
  else
    channel_params[eid] = value
    if plock[eid] == nil then
      params:set(eid,value)
    end
  end
end

function remove_plock()
  if step_selected() then
    -- this would need a number for finding last value
  end
end

function remove_all_plocks()
  if step_selected() then
    ch, step = selected_step()
    for param, t in pairs(plock) do
      plock[param][step] = nil
    end
  end
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


--
-- REDRAW FUNCTIONS
--
function grid_redraw()
  g:all(0)
  for x=1,16 do
    for y=1,8 do
      if params:get("step"..y..x) > 0 then
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
