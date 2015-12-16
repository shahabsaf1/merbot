do

  -- Checks if bot was disabled on specific chat
  local function is_channel_disabled(receiver)
	  if not _config.disabled_channels then
		  return false
	  end
	  if _config.disabled_channels[receiver] == nil then
		  return false
	  end
    return _config.disabled_channels[receiver]
  end

  local function enable_channel(receiver)
	  if not _config.disabled_channels then
		  _config.disabled_channels = {}
	  end
	  if _config.disabled_channels[receiver] == nil then
		  return 'Channel is not disabled'
	  end
	  _config.disabled_channels[receiver] = false
	  save_config()
	  return 'Channel re-enabled'
  end

  local function pre_process(msg)
	  -- If sender is a moderator then re-enable the channel
	  if is_mod(msg) then
	    if msg.text == '!channel enable' then
	      enable_channel(get_receiver(msg))
	    end
	  end
    if is_channel_disabled(get_receiver(msg)) then
    	msg.text = ''
    end
	  return msg
  end

  local function run(msg, matches)
	  -- Enable a channel
	  if matches[1] == 'enable' then
		  return enable_channel(get_receiver(msg))
	  end
	  -- Disable a channel
	  if matches[1] == 'disable' then
	    if not _config.disabled_channels then
		    _config.disabled_channels = {}
	    end
	    _config.disabled_channels[get_receiver(msg)] = true
	    save_config()
	    return 'Channel disabled'
	  end
  end

  return {
	  description = 'Plugin to manage channels. Enable or disable channel.',
	  usage = {
      moderator = {
		    ' !channel enable: enable current channel',
		    ' !channel disable: disable current channel'
      },
    },
	  patterns = {
		  "^!channel (enable)$",
		  "^!channel (disable)$"
    },
	  run = run,
    moderated = true,
	  pre_process = pre_process
  }

end
