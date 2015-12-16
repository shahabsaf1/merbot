do

  -- Returns the key (index) in the config.enabled_plugins table
  local function plugin_enabled(name)
    for k,v in pairs(_config.enabled_plugins) do
      if name == v then
        return k
      end
    end
    -- If not found
    return false
  end

  -- Returns true if file exists in plugins folder
  local function plugin_exists(name)
    for k,v in pairs(plugins_names()) do
      if name..'.lua' == v then
        return true
      end
    end
    return false
  end

  local function list_plugins(only_enabled)
    local text = ''
    local psum = 0
    for k, v in pairs(plugins_names()) do
      --  ✅ enabled, ❌ disabled
      local status = '❌'
      psum = psum+1
      pact = 0
      -- Check if is enabled
      for k2, v2 in pairs(_config.enabled_plugins) do
        if v == v2..'.lua' then
          status = '✅'
        end
        pact = pact+1
      end
      if not only_enabled or status == '✅' then
        -- get the name
        v = string.match (v, "(.*)%.lua")
        text = text..status..'  '..v..'\n'
      end
    end
    local text = text..'\n'..psum..'  plugins installed.\n✅  '
                ..pact..' enabled.\n❌  '..psum-pact..' disabled.'
    return text
  end

  local function reload_plugins()
    plugins = {}
    load_plugins()
    return list_plugins(true)
  end

  local function run(msg, matches)
    if is_mod(msg) then
      -- Show the available plugins
      if matches[1] == '!plugins' then
        return list_plugins()
      -- Re-enable a plugin for this chat
      elseif matches[1] == 'enable' and matches[3] == 'chat' then
        print("enable "..matches[2]..' on this chat')
        if not _config.disabled_plugin_on_chat then
          return 'There aren\'t any disabled plugins for this chat.'
        end
        if not _config.disabled_plugin_on_chat[get_receiver(msg)] then
          return 'There aren\'t any disabled plugins for this chat'
        end
        if not _config.disabled_plugin_on_chat[get_receiver(msg)][matches[2]] then
          return 'Plugin '..matches[2]..' is not disabled for this chat.'
        end
        _config.disabled_plugin_on_chat[get_receiver(msg)][matches[2]] = false
        save_config()
        return 'Plugin '..matches[2]..' is enabled again for this chat.'
      -- Disable a plugin on a chat
      elseif matches[1] == 'disable' and matches[3] == 'chat' then
        print('disable '..matches[2]..' on this chat')
        if not plugin_exists(matches[2]) then
          return 'Plugin '..matches[2]..' doesn\'t exists'
        end
        if not _config.disabled_plugin_on_chat then
          _config.disabled_plugin_on_chat = {}
        end
        if not _config.disabled_plugin_on_chat[get_receiver(msg)] then
          _config.disabled_plugin_on_chat[get_receiver(msg)] = {}
        end
        _config.disabled_plugin_on_chat[get_receiver(msg)][matches[2]] = true
        save_config()
        return 'Plugin '..matches[2]..' disabled for this chat'
      end
    end
    if is_sudo(msg) then
      -- Enable a plugin
      if matches[1] == 'enable' then
        print('enable: '..matches[2])
        print('checking if '..matches[2]..' exists')
        -- Check if plugin is enabled
        if plugin_enabled(matches[2]) then
          return 'Plugin '..matches[2]..' is enabled'
        end
        -- Checks if plugin exists
        if plugin_exists(matches[2]) then
          -- Add to the config table
          table.insert(_config.enabled_plugins, matches[2])
          print(matches[2]..' added to _config table')
          save_config()
          -- Reload the plugins
          return reload_plugins( )
        else
          return 'Plugin '..matches[2]..' does not exists'
        end
      -- Disable a plugin
      elseif matches[1] == 'disable' then
        print('disable: '..matches[2])
        -- Check if plugins exists
        if not plugin_exists(matches[2]) then
          return 'Plugin '..matches[2]..' does not exists'
        end
        local k = plugin_enabled(matches[2])
        -- Check if plugin is enabled
        if not k then
          return 'Plugin '..matches[2]..' not enabled'
        end
        -- Disable and reload
        table.remove(_config.enabled_plugins, k)
        save_config( )
        return reload_plugins(true)
      -- Reload all the plugins!
      elseif matches[1] == 'reload' then
        return reload_plugins(true)
      end
    end
  end

  return {
    description = 'Plugin to manage other plugins. Enable, disable or reload.',
    usage = {
      moderator = {
        '!plugins: list all plugins.',
        '!plugins enable [plugin] chat: re-enable plugin only this chat.',
        '!plugins disable [plugin] chat: disable plugin only this chat.'
      },
      sudo = {
        '!plugins enable [plugin]: enable plugin.',
        '!plugins disable [plugin]: disable plugin.',
        '!plugins reload: reloads all plugins.'
      },
    },
    patterns = {
      "^!plugins$",
      "^!plugins? (enable) ([%w_%.%-]+)$",
      "^!plugins? (disable) ([%w_%.%-]+)$",
      "^!plugins? (enable) ([%w_%.%-]+) (chat)$",
      "^!plugins? (disable) ([%w_%.%-]+) (chat)$",
      "^!plugins? (reload)$"
    },
    run = run,
    moderated = true
  }

end
