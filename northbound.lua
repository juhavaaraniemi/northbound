-- Northbound 0.1

Northbound = include 'lib/northbound'
engine.name="Northbound"

function add_parameters()
  params:add_separator("NORTHBOUND")
  params:add_group("NORTHBOUND - ROUTING",2)
  params:add{
    type = "number",
    id = "midi_in_device",
    name = "midi in device",
    min = 1,
    max = 16,
    default = 1,
    action = function(value)
      --note_off_all()
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
end

function init_midi_devices()
  midi_in_device = midi.connect(1)
  midi_in_device.event = midi_event
end
  

function init()
  init_midi_devices()
  add_parameters()
  Northbound.add_params()
end

function midi_event(data)
  local msg = midi.to_msg(data)
  if msg.ch == params:get("midi_in_channel") then
    if msg.type == "note_on" then
      print(msg.note..","..msg.vel/127)
      engine.trig(msg.note-35,msg.vel/127)
    end
  end
end

function key(n,z)
  if z == 1 then
    if n == 2 then
      engine.trig(1,1)
    end
  end
end
