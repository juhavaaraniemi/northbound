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
            brightness[j][i] = math.ceil(value/100*15)
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
  alt = {}
  brightness = {}
  for x = 1,16 do
    counter[x] = {}
    alt[x] = {}
    brightness[x] = {}
    for y = 1,8 do
      counter[x][y] = nil
      alt[x][y] = false
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
  
  params:add_group("NORTHBOUND UI PARAMS",43)
  
  params:add_number("ui_channelSelect","Channel Select",1,8,1)
  
  for i=1,params.count do
    local p = params:lookup_param(i)
    
    if string.sub(p.id,1,3) == "ch1" then
      local pid = string.sub(p.id,4)
      
      if p.t == 0 then
        params:add_separator("ui_"..pid,p.name)
      elseif p.t == 2 then
        params:add_option("ui_"..pid,p.name,p.options,p.default)
        params:set_action("ui_"..pid,
          function(value)
            local eid = "ch"..params:get("ui_channelSelect")..pid
            for x=1,16 do
              for y=1,8 do
                if alt[x][y] then
                  step_params[y][x][eid] = value
                  active_plocks[eid] = true
                  print("step_params"..step_params[y][x][eid])
                end
              end
            end
            if not global_alt then
              channel_params[eid]= value
              print("channel_params:"..channel_params[eid])
              params:set(eid,value)
            end
          end
          )
      elseif p.t == 3 then
        params:add_control("ui_"..pid,p.name,p.controlspec)
        params:set_action("ui_"..pid,
          function(value)
            local eid = "ch"..params:get("ui_channelSelect")..pid
            for x=1,16 do
              for y=1,8 do
                if alt[x][y] then
                  step_params[y][x][eid] = value
                  active_plocks[eid] = true
                  print("step_params"..step_params[y][x][eid])
                end
              end
            end
            if not global_alt then
              channel_params[eid]= value
              print("channel_params:"..channel_params[eid])
              params:set(eid,value)
            end
          end
          )
      end
      
    end
    -- create channel value store
    if string.sub(p.id,1,2) == "ch" then
      if p.t == 2 or p.t == 3 or p.t == 5 then
        channel_params[p.id] = params:get(p.id)
      end
    end

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

  end
end

function init_step_params()
  step_params = {}
  active_plocks = {}
  for ch=1,8 do
    step_params[ch] = {}
    for step=1,16 do
      step_params[ch][step] = {}
    end
  end
end

function init()
  init_midi_devices()
  Northbound.add_params()
  add_parameters()
  init_ui_params()
  init_step_params()
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
    for i=1,8 do
      if params:get("step"..i..step) == 1 then
        if math.random(100) <= params:get("prob"..i..step) then

          --set parameters for step
          if next(step_params[i][step]) == nil then
            for k,v in pairs(active_plocks) do
              if tonumber(string.sub(k,3,3)) == i then
                print("here")
                params:set(k,channel_params[k])
              end
            end
          else
            for k,v in pairs(step_params[i][step]) do
              --print(string.sub(k,3,3))
              if tonumber(string.sub(k,3,3)) == i then
                print("should be happening")
                params:set(k,v)
              end
            end
          end
          engine.trig(i,params:get("vel"..i..step)/127)
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
      engine.trig(1,1)
    end
  end
end

function enc(n,d)
  for x=1,16 do
    for y=1,8 do
      if alt[x][y] then
        if n == 1 then  
          params:delta("prob"..y..x,d)
        elseif n == 2 then
          params:delta("vel"..y..x,d)
        end
      end
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
  grid_dirty = true
end

function long_press(x,y)
  clock.sleep(0.25)
  alt[x][y] = true
  global_alt = true
  counter[x][y] = nil
  grid_dirty = true
end

function long_release(x,y)
  alt[x][y] = false
  global_alt = false
  grid_dirty = true
end


--
-- HELPER FUNCTIONS
--
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function shallow_copy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
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
