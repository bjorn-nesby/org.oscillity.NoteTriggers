--[[===============================================================================================
org.oscillity.NoteTriggers.xrnx/main.lua
===============================================================================================]]--

--[[

  A simple tool for demonstrating real-time triggering of notes 

--]]


--------------------------------------------------------------------------------------------------
-- misc variables 

--- the socket connection, nil if not established
local connection
local host = "127.0.0.1"
local port = 8000

--------------------------------------------------------------------------------------------------
-- establish a connection to the OSC server 

function create_connection()
  close_connection()
  local client, socket_error = 
    renoise.Socket.create_client(host, port, renoise.Socket.PROTOCOL_UDP)
	if (socket_error) then 
    connection = nil
    return false, "*** failed to establish connection"
	else
    connection = client
    return true
	end
end

--------------------------------------------------------------------------------------------------

function close_connection()
  if connection then 
    connection:close()
  end
end

--------------------------------------------------------------------------------------------------
-- trigger notes (selected instrument/track)
-- @param note_on (bool), true when note-on and false when note-off
-- @param note (int), the desired pitch, 0-120
-- @return bool, true when triggered

function trigger_instrument(note_on,note)
  
  if not connection then
    return false
  end

  -- use selected instrument / track index
  local instr = renoise.song().selected_instrument_index
  local track = renoise.song().selected_track_index

  -- use max. velocity 
  local velocity = 0x80

  local osc_vars = table.create()
  osc_vars:insert({tag = "i",value = instr})
  osc_vars:insert({tag = "i",value = track})
  osc_vars:insert({tag = "i",value = note})

  -- tell renoise to play the notes 
  local header = nil
  if (note_on) then
    header = "/renoise/trigger/note_on"
    osc_vars:insert({ tag = "i", value = velocity })
  else
    header = "/renoise/trigger/note_off"
  end

  local osc_msg = renoise.Osc.Message(header,osc_vars)
  connection:send(osc_msg)

  return true

end


--------------------------------------------------------------------------------------------------
-- @param indices: number[]

function trigger_notes(indices)
  for _,note_idx in ipairs(indices) do
    local triggered = trigger_instrument(true,note_idx)
    print("triggered note at ",note_idx," - result:",triggered)
  end
end 

--------------------------------------------------------------------------------------------------
-- @param indices: number[]

function release_notes(indices)
  print("release_notes",rprint(indices))
  for _,note_idx in ipairs(indices) do
    local triggered = trigger_instrument(false,note_idx)
    print("released note at ",note_idx," - result:",triggered)
  end
end 

--------------------------------------------------------------------------------------------------

function show_tool_dialog()

  local vb = renoise.ViewBuilder()

  local dialog_title = "NoteTriggers"
  local dialog_buttons = {"Close"};

  local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local dialog_content = vb:column {
    margin = DEFAULT_MARGIN,
    vb:column {
      style = "group",
      margin = DEFAULT_MARGIN,
      spacing = DEFAULT_MARGIN,
      vb:text {
        text = "Click these buttons to trigger some notes"
             .."\nNote: you need to enable the Renoise OSC server"
      },            
      vb:button{
        text = "Trigger notes 0,2,4",
        pressed = function()
          trigger_notes({0,2,4})
        end,
        released = function()
          release_notes({0,2,4})
        end,
      },
      vb:button{
        text = "Trigger notes 2,5,8,9,11",
        pressed = function()
          trigger_notes({2,5,8,9,11})
        end,
        released = function()
          release_notes({2,5,8,9,11})
        end,
      },
    },
  }

  -- establish connection 
  create_connection()
  
  -- NB: don't use modal dialogs in tools that trigger notes 
  -- (e.g. 'show_custom_prompt' will trigger only once closed)
  renoise.app():show_custom_dialog(dialog_title, dialog_content)

end

--------------------------------------------------------------------------------------------------
-- register menu entry
--------------------------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:NoteTriggers...",
  invoke = function() show_tool_dialog() end 
}

