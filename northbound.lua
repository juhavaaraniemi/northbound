-- Northbound 0.1

--
-- LIBRARIES
--
Northbound = include 'lib/northbound'
engine.name="Northbound"


--
-- VARIABLES
--
g = grid.connect()
grid_dirty = true


--
-- INIT FUNCTIONS
--
function add_parameters()
  params:add_separator("NORTHBOUND")
  params:add_group("ROUTING",2)
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

function read_params()
  param_select = {}
  for i=1,params.count do
    local p = params:lookup_param(i)
    if p.t == 3 or p.t == 5 or p.t == 1 or p.t == 2 then
      table.insert(param_select,p.id)
      --param_select[p.id] = p.name
      --print(p.name)
    end
  end
end

function init_plocks()
  params:add_group("PLOCKS",20)
  for i=1,20 do
    params:add{
      type = "option",
      id = i.."plock",
      name = "plock "..i,
      options = param_select,
      default = 1,
      action = function(value)
      end
    }
  end
end


function init_grid_variables()
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
end
  
function init()
  init_midi_devices()
  Northbound.add_params()
  --read_params()
  --init_plocks()
  add_parameters()
  init_grid_variables()
  clock.run(step)
  grid_redraw_metro = metro.init(grid_redraw_event,1/30,-1)
  grid_redraw_metro:start()
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
  counter[x][y] = nil
  grid_dirty = true
end

function long_release(x,y)
  alt[x][y] = false
  grid_dirty = true
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
        --g:led(x,y,10)
      end
    end
  end
  g:refresh()
end
