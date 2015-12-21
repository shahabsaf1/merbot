-- data saved to moderation.json

do

  -- make sure to set with value that not higher than stats.lua
  local NUM_MSG_MAX = 4  -- Max number of messages per TIME_CHECK seconds
  local TIME_CHECK = 4

  local function is_user_whitelisted(id)
    return redis:get('whitelist:user#id'..id) or false
  end

  local function is_chat_whitelisted(id)
    return redis:get('whitelist:chat#id'..id) or false
  end

  local function kick_user(user_id, chat_id)
    if user_id == tostring(our_id) then
      send_msg('chat#id'..chat_id, 'I won\'t kick myself!', ok_cb,  true)
    else
      chat_del_user('chat#id'..chat_id, 'user#id'..user_id, ok_cb, true)
    end
  end

  local function ban_user(user_id, chat_id)
    -- Save to redis
    redis:set('banned:'..chat_id..':'..user_id, true)
    -- Kick from chat
    kick_user(user_id, chat_id)
  end

  local function superban_user(user_id, chat_id)
    redis:set('superbanned:'..user_id, true)
    kick_user(user_id, chat_id)
  end

  local function is_super_banned(user_id)
      return redis:get('superbanned:'..user_id) or false
  end

  local function unban_user(user_id, chat_id)
    redis:del('banned:'..chat_id..':'..user_id)
  end

  local function superunban_user(user_id, chat_id)
    redis:del('superbanned:'..user_id)
    return 'User '..user_id..' unbanned'
  end

  local function is_banned(user_id, chat_id)
    return redis:get('banned:'..chat_id..':'..user_id) or false
  end

  local function action_by_id(extra, success, result)
    if success == 1 then
      local matches = extra.matches
      local chat_id = result.id
      local receiver = 'chat#id'..chat_id
      local group_member = false
      for k,v in pairs(result.members) do
        if matches[2] == tostring(v.id) then
          group_member = true
          local full_name = (v.first_name or '')..' '..(v.last_name or '')
          if matches[1] == 'ban' then
            ban_user(matches[2], chat_id)
            send_large_msg(receiver, full_name..' ['..matches[2]..'] banned', ok_cb,  true)
          elseif matches[1] == 'superban' then
            superban_user(matches[2], chat_id)
            send_large_msg(receiver, full_name..' ['..matches[2]..'] globally banned!', ok_cb, true)
          elseif matches[1] == 'kick' then
            kick_user(matches[2], chat_id)
          end
        end
      end
      if matches[1] == 'unban' then
        if is_banned(matches[2], chat_id) then
          unban_user(matches[2], chat_id)
          send_large_msg(receiver, 'User with ID ['..matches[2]..'] is unbanned.')
        else
          send_large_msg(receiver, 'No user with ID '..matches[2]..' in (super)ban list.')
        end
      elseif matches[1] == 'superunban' then
        if is_super_banned(matches[2]) then
          superunban_user(matches[2], chat_id)
          send_large_msg(receiver, 'User with ID ['..matches[2]..'] is globally unbanned.')
        else
          send_large_msg(receiver, 'No user with ID '..matches[2]..' in (super)ban list.')
        end
      end
      if not group_member then
        send_large_msg(receiver, 'No user with ID '..matches[2]..' in this group.')
      end
    end
  end

  local function action_by_reply(extra, success, result)
    local msg = result
    local receiver = get_receiver(msg)
    local chat_id = msg.to.id
    local user_id = msg.from.id
    local user = 'user#id'..msg.from.id
    local full_name = (msg.from.first_name or '')..' '..(msg.from.last_name or '')
    if is_chat_msg(msg) and not is_sudo(msg) then
      if extra.match == 'kick' then
        chat_del_user(receiver, user, ok_cb, false)
      elseif extra.match == 'ban' then
        ban_user(user_id, chat_id)
        send_msg(receiver, 'User '..user_id..' banned', ok_cb,  true)
      elseif extra.match == 'superban' then
        superban_user(user_id, chat_id)
        send_large_msg(receiver, full_name..' ['..user_id..'] globally banned!')
      elseif extra.match == 'unban' then
        unban_user(user_id, chat_id)
        send_msg(receiver, 'User '..user_id..' unbanned', ok_cb,  true)
      elseif extra.match == 'superunban' then
        superunban_user(user_id, chat_id)
        send_large_msg(receiver, full_name..' ['..user_id..'] globally unbanned!')
      end
    else
      return 'Use This in Your Groups'
    end
  end

  local function resolve_username(extra, success, result)
    local msg = extra.msg
    local receiver = get_receiver(msg)
    local chat_id = msg.to.id
    if result ~= false then
      local user_id = result.id
      local user = 'user#id'..result.id
      local username = result.username
      if is_chat_msg(msg) then
        -- check if sudo users
        local is_sudoers = false
        for v,sudoer in pairs(_config.sudo_users) do
          if sudoer == user_id then
            is_sudoers = true
          end
        end
        if not is_sudoers then
          if extra.match == 'kick' then
            chat_del_user(receiver, user, ok_cb, false)
          elseif extra.match == 'ban' then
            ban_user(user_id, chat_id)
            send_msg(receiver, 'User @'..username..' banned', ok_cb,  true)
          elseif extra.match == 'superban' then
            superban_user(user_id, chat_id)
            send_msg(receiver, 'User @'..username..' ['..user_id..'] globally banned!', ok_cb,  true)
          elseif extra.match == 'unban' then
            unban_user(user_id, chat_id)
            send_msg(receiver, 'User @'..username..' unbanned', ok_cb,  true)
          elseif extra.match == 'superunban' then
            superunban_user(user_id, chat_id)
            send_msg(receiver, 'User @'..username..' ['..user_id..'] globally unbanned!', ok_cb,  true)
          end
        end
      else
        return 'Use This in Your Groups.'
      end
    else
      send_large_msg(receiver, 'No user @'..extra.user..' in this group.')
    end
  end

  local function pre_process(msg)

    local user_id = msg.from.id
    local chat_id = msg.to.id
    local receiver = get_receiver(msg)
    local user = 'user#id'..user_id

    -- ANTI FLOOD
    local post_count = 'floodc:'..user_id..':'..chat_id
    redis:incr(post_count)
    if msg.from.type == 'user' then
      local post_count = 'user:'..user_id..':floodc'
      local msgs = tonumber(redis:get(post_count) or 0)
      local text = 'User '..user_id..' is flooding'
      if msgs > NUM_MSG_MAX and not is_sudo(msg) then
        local data = load_data(_config.moderation.data)
        local anti_flood_stat = data[tostring(chat_id)]['settings']['anti_flood']
        if anti_flood_stat == 'kick' then
          send_large_msg(receiver, text)
          kick_user(user_id, chat_id)
          msg = nil
        elseif anti_flood_stat == 'ban' then
          send_large_msg(receiver, text)
          ban_user(user_id, chat_id)
          send_msg(receiver, 'User '..user_id..' banned', ok_cb,  true)
          msg = nil
        end
      end
      redis:setex(post_count, TIME_CHECK, msgs+1)
    end

    -- SERVICE MESSAGE
    if msg.action and msg.action.type then
      local action = msg.action.type
      -- Check if banned user joins chat
      if action == 'chat_add_user' or action == 'chat_add_user_link' then
        local user_id
        if msg.action.link_issuer then
          user_id = msg.from.id
        else
	        user_id = msg.action.user.id
        end
        print('Checking invited user '..user_id)
        if is_super_banned(user_id) or is_banned(user_id, chat_id) then
          print('User is banned!')
          kick_user(user_id, chat_id)
        end
      end
      -- No further checks
      return msg
    end

    -- BANNED USER TALKING
    if is_chat_msg(msg) then
      if is_super_banned(user_id) then
        print('SuperBanned user talking!')
        superban_user(user_id, chat_id)
        msg.text = ''
      end
      if is_banned(user_id, chat_id) then
        print('Banned user talking!')
        ban_user(user_id, chat_id)
        msg.text = ''
      end
    end

    -- WHITELIST
    -- Allow all sudo users even if whitelist is allowed
    if redis:get('whitelist:enabled') and not is_sudo(msg) then
      print('Whitelist enabled and not sudo')
      -- Check if user or chat is whitelisted
      if not is_user_whitelisted(user_id) then
        print('User '..user..' not whitelisted')
        if is_chat_msg(msg) then
          if not is_chat_whitelisted(chat_id) then
            print ('Chat '..chat_id..' not whitelisted')
          else
            print ('Chat '..chat_id..' whitelisted :)')
          end
        end
      else
        print('User '..user_id..' allowed :)')
      end

      if not is_user_whitelisted(user_id) then
        msg.text = ''
      end

    else
      print('Whitelist not enabled or is sudo')
    end

    return msg
  end

  local function run(msg, matches)

    vardump(msg)

    local receiver = get_receiver(msg)
    local user = 'user#id'..(matches[2] or '')

    if is_chat_msg(msg) then
      if matches[1] == 'kickme' then
        if is_sudo(msg) or is_admin(msg) then
          return 'I won\'t kick an admin!'
        elseif is_mod(msg) then
          return 'I won\'t kick a moderator!'
        else
          kick_user(msg.from.id, msg.to.id)
        end
      end
      if is_mod(msg) then
        if matches[1] == 'kick' then
          if msg.reply_id then
            msgr = get_message(msg.reply_id, action_by_reply, {msg=msg, match=matches[1]})
          elseif string.match(matches[2], '^%d+$') then
            chat_info(receiver, action_by_id, {msg=msg, matches=matches})
          elseif string.match(matches[2], '^@.+$') then
            msgr = res_user(string.gsub(matches[2], '@', ''), resolve_username, {msg=msg, match=matches[1]})
          end
        elseif matches[1] == 'ban' then
          if msg.reply_id then
            msgr = get_message(msg.reply_id, action_by_reply, {msg=msg, match=matches[1]})
          elseif string.match(matches[2], '^%d+$') then
            chat_info(receiver, action_by_id, {msg=msg, matches=matches})
          elseif string.match(matches[2], '^@.+$') then
            msgr = res_user(string.gsub(matches[2], '@', ''), resolve_username, {msg=msg, match=matches[1]})
          end
        elseif matches[1] == 'banlist' then
          local text = 'Ban list for '..msg.to.title..' ['..msg.to.id..']:\n\n'
          for k,v in pairs(redis:keys('banned:'..msg.to.id..':*')) do
            text = text..k..'. '..v..'\n'
          end
          return string.gsub(text, 'banned:'..msg.to.id..':', '')
        elseif matches[1] == 'unban' then
          if msg.reply_id then
            msgr = get_message(msg.reply_id, action_by_reply, {msg=msg, match=matches[1]})
          elseif string.match(matches[2], '^%d+$') then
            chat_info(receiver, action_by_id, {msg=msg, matches=matches})
          elseif string.match(matches[2], '^@.+$') then
            msgr = res_user(string.gsub(matches[2], '@', ''), resolve_username, {msg=msg, match=matches[1]})
          end
        end
        if matches[1] == 'antiflood' then
          local data = load_data(_config.moderation.data)
          local settings = data[tostring(msg.to.id)]['settings']
          if matches[2] == 'kick' then
            if settings.anti_flood ~= 'kick' then
              settings.anti_flood = 'kick'
              save_data(_config.moderation.data, data)
            end
              return 'Anti flood protection already enabled.\nFlooder will be kicked.'
            end
          if matches[2] == 'ban' then
            if settings.anti_flood ~= 'ban' then
              settings.anti_flood = 'ban'
              save_data(_config.moderation.data, data)
            end
              return 'Anti flood  protection already enabled.\nFlooder will be banned.'
            end
          if matches[2] == 'disable' then
            if settings.anti_flood == 'no' then
              return 'Anti flood  protection is not enabled.'
            else
              settings.anti_flood = 'no'
              save_data(_config.moderation.data, data)
              return 'Anti flood  protection has been disabled.'
            end
          end
        end
        if matches[1] == 'whitelist' then
          if matches[2] == 'enable' then
            redis:set('whitelist:enabled', true)
            return 'Enabled whitelist'
          elseif matches[2] == 'disable' then
            redis:del('whitelist:enabled')
            return 'Disabled whitelist'
          elseif matches[2] == 'user' then
            redis:set('whitelist:user#id'..matches[3], true)
            return 'User '..matches[3]..' whitelisted'
          elseif matches[2] == 'delete' and matches[3] == 'user' then
            redis:del('whitelist:user#id'..matches[4])
            return 'User '..matches[4]..' removed from whitelist'
          elseif matches[2] == 'chat' then
            redis:set('whitelist:chat#id'..msg.to.id, true)
            return 'Chat '..msg.to.id..' whitelisted'
          elseif matches[2] == 'delete' and matches[3] == 'chat' then
            redis:del('whitelist:chat#id'..msg.to.id)
            return 'Chat '..msg.to.id..' removed from whitelist'
          end
        end
      end
      if is_admin(msg) then
        if matches[1] == 'superban' then
          if msg.reply_id then
            msgr = get_message(msg.reply_id, action_by_reply, {msg=msg, match=matches[1]})
          elseif string.match(matches[2], '^%d+$') then
            chat_info(receiver, action_by_id, {msg=msg, matches=matches})
          elseif string.match(matches[2], '^@.+$') then
            msgr = res_user(string.gsub(matches[2], '@', ''), resolve_username, {msg=msg, match=matches[1]})
          end
        elseif matches[1] == 'superunban' then
          if msg.reply_id then
            msgr = get_message(msg.reply_id, action_by_reply, {msg=msg, match=matches[1]})
          elseif string.match(matches[2], '^%d+$') then
            chat_info(receiver, action_by_id, {msg=msg, matches=matches})
          elseif string.match(matches[2], '^@.+$') then
            msgr = res_user(string.gsub(matches[2], '@', ''), resolve_username, {msg=msg, match=matches[1]})
          end
        end
      end
    else
      print '>>> This is not a chat group.'
    end
  end

  return {
    description = 'Plugin to manage bans, kicks and white/black lists.',
    usage = {
      user = {
        '!kickme : Kick yourself out of this group.'
      },
      admin = {
        '!superban : If type in reply, will ban user globally.',
        '!superban <user_id>/@<username> : Kick user_id/username from all chat and kicks it if joins again',
        '!superunban : If type in reply, will unban user globally.',
        '!superunban <user_id>/@<username> : Unban user_id/username globally.'
      },
      moderator = {
        '!antiflood kick : Enable flood protection. Flooder will be kicked.',
        '!antiflood ban : Enable flood protection. Flooder will be banned.',
        '!antiflood disable : Disable flood protection',
        '!ban : If type in reply, will ban user from chat group.',
        '!ban <user_id>/<@username>: Kick user from chat and kicks it if joins chat again',
        '!banlist : List users banned from chat group.',
        '!unban : If type in reply, will unban user from chat group.',
        '!unban <user_id>/<@username>: Unban user',
        '!kick : If type in reply, will kick user from chat group.',
        '!kick <user_id>/<@username>: Kick user from chat group',
        '!whitelist chat: Allow everybody on current chat to use the bot when whitelist mode is enabled',
        '!whitelist delete chat: Remove chat from whitelist',
        '!whitelist delete user <user_id>: Remove user from whitelist',
        '!whitelist <enable>/<disable>: Enable or disable whitelist mode',
        '!whitelist user <user_id>: Allow user to use the bot when whitelist mode is enabled'
      },
    },
    patterns = {
      '^!(antiflood) (.*)$',
      '^!(ban) (.*)$',
      '^!(ban)$',
      '^!(banlist)$',
      '^!(unban) (.*)$',
      '^!(unban)$',
      '^!(kick) (.+)$',
      '^!(kick)$',
      '^!(kickme)$',
      '^!!tgservice (.+)$',
      '^!(whitelist) (chat)$',
      '^!(whitelist) (delete) (chat)$',
      '^!(whitelist) (delete) (user) (%d+)$',
      '^!(whitelist) (disable)$',
      '^!(whitelist) (enable)$',
      '^!(whitelist) (user) (%d+)$',
      '^!(superban)$',
      '^!(superban) (.*)$',
      '^!(superunban)$',
      '^!(superunban) (.*)$'
    },
    run = run,
    pre_process = pre_process
  }

end
