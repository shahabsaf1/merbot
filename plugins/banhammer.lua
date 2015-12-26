-- data saved to moderation.json

do

  -- make sure to set with value that not higher than stats.lua
  local NUM_MSG_MAX = 4  -- Max number of messages per TIME_CHECK seconds
  local TIME_CHECK = 4
  local NO_KICK = 'I will not kick myself, sudoers, admins or moderators!'
  local NO_BAN = 'I will not ban myself, sudoers, admins or moderators!'
  local NO_SUPERBAN = 'I will not superban myself, sudoers, admins or moderators!'

  local function kick_user(user_id, chat_id)
    -- check if user was kicked in the last TIME_CHECK seconds
    if not redis:get('kicked:'..chat_id..':'..user_id) or false then
      if user_id == tostring(our_id) then
        send_large_msg('chat#id'..chat_id, 'I won\'t kick myself!')
      else
        chat_del_user('chat#id'..chat_id, 'user#id'..user_id, ok_cb, true)
      end
    end
    -- set for TIME_CHECK seconds that user have been kicked
    redis:setex('kicked:'..chat_id..':'..user_id, TIME_CHECK, 'true')
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

  local function unban_user(user_id, chat_id)
    redis:del('banned:'..chat_id..':'..user_id)
  end

  local function superunban_user(user_id, chat_id)
    redis:del('superbanned:'..user_id)
    return 'User '..user_id..' unbanned'
  end

  local function action_by_id(extra, success, result)
    if success == 1 then
      local matches = extra.matches
      local chat_id = result.id
      local group_member = false
      for k,v in pairs(result.members) do
        if matches[2] == tostring(v.id) then
          group_member = true
          local full_name = (v.first_name or '')..' '..(v.last_name or '')
          if matches[1] == 'ban' then
            if is_mod(matches[2], chat_id) then
              send_large_msg('chat#id'..chat_id, NO_BAN)
            else
              ban_user(matches[2], chat_id)
              send_large_msg('chat#id'..chat_id, full_name..' ['..matches[2]..'] banned')
            end
          elseif matches[1] == 'superban' then
            if is_mod(matches[2], chat_id) then
              send_large_msg('chat#id'..chat_id, NO_SUPERBAN)
            else
              superban_user(matches[2], chat_id)
              send_large_msg('chat#id'..chat_id, full_name..' ['..matches[2]..'] globally banned!')
            end
          elseif matches[1] == 'kick' then
            if is_mod(matches[2], chat_id) then
              send_large_msg('chat#id'..chat_id, NO_KICK)
            else
              kick_user(matches[2], chat_id)
            end
          end
        end
      end
      if matches[1] == 'unban' then
        if is_banned(matches[2], chat_id) then
          unban_user(matches[2], chat_id)
          send_large_msg('chat#id'..chat_id, 'User with ID ['..matches[2]..'] is unbanned.')
        else
          send_large_msg('chat#id'..chat_id, 'No user with ID '..matches[2]..' in (super)ban list.')
        end
      elseif matches[1] == 'superunban' then
        if is_super_banned(matches[2]) then
          superunban_user(matches[2], chat_id)
          send_large_msg('chat#id'..chat_id, 'User with ID ['..matches[2]..'] is globally unbanned.')
        else
          send_large_msg('chat#id'..chat_id, 'No user with ID '..matches[2]..' in (super)ban list.')
        end
      end
      if not group_member then
        send_large_msg('chat#id'..chat_id, 'No user with ID '..matches[2]..' in this group.')
      end
    end
  end

  local function action_by_reply(extra, success, result)
    local chat_id = result.to.id
    local user_id = result.from.id
    local full_name = (result.from.first_name or '')..' '..(result.from.last_name or '')
    if is_chat_msg(result) then
      if extra.match == 'kick' then
        if is_mod(user_id, chat_id) then
          send_large_msg('chat#id'..chat_id, NO_KICK)
        else
          kick_user(user_id, chat_id)
        end
      elseif extra.match == 'ban' then
        if is_mod(user_id, chat_id) then
          send_large_msg('chat#id'..chat_id, NO_BAN)
        else
          ban_user(user_id, chat_id)
        end
      elseif extra.match == 'superban' then
        if is_mod(user_id, chat_id) then
          send_large_msg('chat#id'..chat_id, NO_SUPERBAN)
        else
          superban_user(user_id, chat_id)
          send_large_msg('chat#id'..chat_id, full_name..' ['..user_id..'] globally banned!')
        end
      elseif extra.match == 'unban' then
        unban_user(user_id, chat_id)
        send_large_msg('chat#id'..chat_id, 'User '..user_id..' unbanned')
      elseif extra.match == 'superunban' then
        superunban_user(user_id, chat_id)
        send_large_msg('chat#id'..chat_id, full_name..' ['..user_id..'] globally unbanned!')
      elseif extra.match == 'whitelist' then
        redis:set('whitelist:user#id'..user_id, true)
        send_large_msg('chat#id'..chat_id, full_name..' ['..user_id..'] whitelisted')
      elseif extra.match == 'unwhitelist' then
        redis:del('whitelist:user#id'..user_id)
        send_large_msg('chat#id'..chat_id, full_name..' ['..user_id..'] removed from whitelist')
      end
    else
      return 'Use This in Your Groups'
    end
  end

  local function resolve_username(extra, success, result)
    local chat_id = extra.msg.to.id
    if result ~= false then
      local user_id = result.id
      local username = result.username
      if is_chat_msg(extra.msg) then
        if extra.match == 'kick' then
          if is_mod(user_id, chat_id) then
            send_large_msg('chat#id'..chat_id, NO_KICK)
          else
            kick_user(user_id, chat_id)
          end
        elseif extra.match == 'ban' then
          if is_mod(user_id, chat_id) then
            send_large_msg('chat#id'..chat_id, NO_BAN)
          else
            ban_user(user_id, chat_id)
            send_large_msg('chat#id'..chat_id, 'User @'..username..' banned')
          end
        elseif extra.match == 'superban' then
          if is_mod(user_id, chat_id) then
            send_large_msg('chat#id'..chat_id, NO_SUPERBAN)
          else
            superban_user(user_id, chat_id)
            send_large_msg('chat#id'..chat_id, 'User @'..username..' ['..user_id..'] globally banned!')
          end
        elseif extra.match == 'unban' then
          unban_user(user_id, chat_id)
          send_large_msg('chat#id'..chat_id, 'User @'..username..' unbanned', ok_cb,  true)
        elseif extra.match == 'superunban' then
          superunban_user(user_id, chat_id)
          send_large_msg('chat#id'..chat_id, 'User @'..username..' ['..user_id..'] globally unbanned!')
        end
      else
        return 'Use This in Your Groups.'
      end
    else
      send_large_msg('chat#id'..chat_id, 'No user '..string.gsub(extra.msg.text, '^.- ', '')..' in this group.')
    end
  end

  local function trigger_anti_splooder(user_id, chat_id, splooder)
    local data = load_data(_config.moderation.data)
    local anti_spam_stat = data[tostring(chat_id)]['settings']['anti_flood']
    if anti_spam_stat == 'kick' then
      kick_user(user_id, chat_id)
      send_large_msg('chat#id'..chat_id, 'User '..user_id..' is '..splooder)
    elseif anti_spam_stat == 'ban' then
      ban_user(user_id, chat_id)
      send_large_msg('chat#id'..chat_id, 'User '..user_id..' is '..splooder..'. Banned')
    end
    msg = nil
  end

  local function pre_process(msg)

    local user_id = msg.from.id
    local chat_id = msg.to.id

    -- ANTI SPAM
    if msg.from.type == 'user' and msg.text and not is_mod(user_id, chat_id) then
      local _nl, ctrl_chars = string.gsub(msg.text, '%c', '')
      -- if string length more than 2048 or control characters is more than 50
      if string.len(msg.text) > 2048 or ctrl_chars > 50 then
        local _c, chars = string.gsub(msg.text, '%a', '')
        local _nc, non_chars = string.gsub(msg.text, '%A', '')
        -- if non characters is bigger than characters
        if non_chars > chars then
          local splooder = 'spamming'
          trigger_anti_splooder(user_id, chat_id, splooder)
        end
      end
    end

    -- ANTI FLOOD
    local post_count = 'floodc:'..user_id..':'..chat_id
    redis:incr(post_count)
    if msg.from.type == 'user' and not is_mod(user_id, chat_id) then
      local post_count = 'user:'..user_id..':floodc'
      local msgs = tonumber(redis:get(post_count) or 0)
      if msgs > NUM_MSG_MAX then
        local splooder = 'flooding'
        trigger_anti_splooder(user_id, chat_id, splooder)
      end
      redis:setex(post_count, TIME_CHECK, msgs+1)
    end

    -- SERVICE MESSAGE
    if msg.action and msg.action.type then
      local action = msg.action.type
      -- Check if banned user joins chat
      if action == 'chat_add_user' or action == 'chat_add_user_link' then
        if msg.action.link_issuer then
          user_id = msg.from.id
        else
	        user_id = msg.action.user.id
        end
        print('>>> banhammer : Checking invited user '..user_id)
        if is_super_banned(user_id) or is_banned(user_id, chat_id) then
          print('>>> banhammer : '..user_id..' is (super)banned from '..chat_id)
          kick_user(user_id, chat_id)
        end
      end
      -- No further checks
      return msg
    end

    -- BANNED USER TALKING
    if is_chat_msg(msg) then
      if is_super_banned(user_id) then
        print('>>> banhammer : SuperBanned user talking!')
        superban_user(user_id, chat_id)
        msg.text = ''
      elseif is_banned(user_id, chat_id) then
        print('>>> banhammer : Banned user talking!')
        ban_user(user_id, chat_id)
        msg.text = ''
      end
    end

    -- WHITELIST
    -- Allow all sudo users even if whitelist is allowed
    if redis:get('whitelist:enabled') and not is_sudo(user_id) then
      print('>>> banhammer : Whitelist enabled and not sudo')
      -- Check if user or chat is whitelisted
      local allowed = redis:get('whitelist:user#id'..user_id) or false
      if not allowed then
        print('>>> banhammer : User '..user_id..' not whitelisted')
        if is_chat_msg(msg) then
          allowed = redis:get('whitelist:chat#id'..chat_id) or false
          if not allowed then
            print ('Chat '..chat_id..' not whitelisted')
          else
            print ('Chat '..chat_id..' whitelisted :)')
          end
        end
      else
        print('>>> banhammer : User '..user_id..' allowed :)')
      end

      if not allowed then
        msg.text = ''
      end

    else
      print('>>> banhammer : Whitelist not enabled or is sudo')
    end

    return msg
  end

  local function run(msg, matches)

    local user = 'user#id'..(matches[2] or '')

    if is_chat_msg(msg) then
      if matches[1] == 'kickme' then
        if is_mod(msg.from.id, msg.to.id) then
          send_large_msg('chat#id'..msg.to.id, NO_KICK)
        else
          kick_user(msg.from.id, msg.to.id)
        end
      end
      if is_mod(msg.from.id, msg.to.id) then
        if matches[1] == 'kick' then
          if msg.reply_id then
            msgr = get_message(msg.reply_id, action_by_reply, {msg=msg, match=matches[1]})
          elseif string.match(matches[2], '^%d+$') then
            chat_info('chat#id'..msg.to.id, action_by_id, {msg=msg, matches=matches})
          elseif string.match(matches[2], '^@.+$') then
            msgr = res_user(string.gsub(matches[2], '@', ''), resolve_username, {msg=msg, match=matches[1]})
          end
        elseif matches[1] == 'ban' then
          if msg.reply_id then
            msgr = get_message(msg.reply_id, action_by_reply, {msg=msg, match=matches[1]})
          elseif string.match(matches[2], '^%d+$') then
            chat_info('chat#id'..msg.to.id, action_by_id, {msg=msg, matches=matches})
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
            chat_info('chat#id'..msg.to.id, action_by_id, {msg=msg, matches=matches})
          elseif string.match(matches[2], '^@.+$') then
            msgr = res_user(string.gsub(matches[2], '@', ''), resolve_username, {msg=msg, match=matches[1]})
          end
        end
        if matches[1] == 'antispam' then
          local data = load_data(_config.moderation.data)
          local settings = data[tostring(msg.to.id)]['settings']
          if matches[2] == 'kick' then
            if settings.anti_flood ~= 'kick' then
              settings.anti_flood = 'kick'
              save_data(_config.moderation.data, data)
            end
              return 'Anti flood and spam protection already enabled.\nOffender will be kicked.'
            end
          if matches[2] == 'ban' then
            if settings.anti_flood ~= 'ban' then
              settings.anti_flood = 'ban'
              save_data(_config.moderation.data, data)
            end
              return 'Anti flood and spam protection already enabled.\nOffender will be banned.'
            end
          if matches[2] == 'disable' then
            if settings.anti_flood == 'no' then
              return 'Anti flood and spam protection is not enabled.'
            else
              settings.anti_flood = 'no'
              save_data(_config.moderation.data, data)
              return 'Anti flood and spam protection has been disabled.'
            end
          end
        end
        if matches[1] == 'whitelist' then
          if msg.reply_id then
            msgr = get_message(msg.reply_id, action_by_reply, {msg=msg, match=matches[1]})
          end
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
        elseif matches[1] == 'unwhitelist' and msg.reply_id then
          msgr = get_message(msg.reply_id, action_by_reply, {msg=msg, match=matches[1]})
        end
      end
      if is_admin(msg.from.id, msg.to.id) then
        if matches[1] == 'superban' then
          if msg.reply_id then
            msgr = get_message(msg.reply_id, action_by_reply, {msg=msg, match=matches[1]})
          elseif string.match(matches[2], '^%d+$') then
            chat_info('chat#id'..msg.to.id, action_by_id, {msg=msg, matches=matches})
          elseif string.match(matches[2], '^@.+$') then
            msgr = res_user(string.gsub(matches[2], '@', ''), resolve_username, {msg=msg, match=matches[1]})
          end
        elseif matches[1] == 'superunban' then
          if msg.reply_id then
            msgr = get_message(msg.reply_id, action_by_reply, {msg=msg, match=matches[1]})
          elseif string.match(matches[2], '^%d+$') then
            chat_info('chat#id'..msg.to.id, action_by_id, {msg=msg, matches=matches})
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
        '!antispam kick : Enable flood and spam protection. Offender will be kicked.',
        '!antispam ban : Enable flood and spam protection. Offender will be banned.',
        '!antispam disable : Disable flood and spam protection',
        '!ban : If type in reply, will ban user from chat group.',
        '!ban <user_id>/<@username>: Kick user from chat and kicks it if joins chat again',
        '!banlist : List users banned from chat group.',
        '!unban : If type in reply, will unban user from chat group.',
        '!unban <user_id>/<@username>: Unban user',
        '!kick : If type in reply, will kick user from chat group.',
        '!kick <user_id>/<@username>: Kick user from chat group',
        '!whitelist : If type in reply, allow user to use the bot when whitelist mode is enabled',
        '!whitelist chat: Allow everybody on current chat to use the bot when whitelist mode is enabled',
        '!whitelist delete chat: Remove chat from whitelist',
        '!whitelist delete user <user_id>: Remove user from whitelist',
        '!whitelist <enable>/<disable>: Enable or disable whitelist mode',
        '!whitelist user <user_id>: Allow user to use the bot when whitelist mode is enabled',
        '!unwhitelist : If type in reply, remove user from whitelist'
      },
    },
    patterns = {
      '^!(antispam) (.*)$',
      '^!(ban) (.*)$',
      '^!(ban)$',
      '^!(banlist)$',
      '^!(unban) (.*)$',
      '^!(unban)$',
      '^!(kick) (.+)$',
      '^!(kick)$',
      '^!(kickme)$',
      '^!!tgservice (.+)$',
      '^!(whitelist)$',
      '^!(whitelist) (chat)$',
      '^!(whitelist) (delete) (chat)$',
      '^!(whitelist) (delete) (user) (%d+)$',
      '^!(whitelist) (disable)$',
      '^!(whitelist) (enable)$',
      '^!(whitelist) (user) (%d+)$',
      '^!(unwhitelist)$',
      '^!(superban)$',
      '^!(superban) (.*)$',
      '^!(superunban)$',
      '^!(superunban) (.*)$'
    },
    run = run,
    pre_process = pre_process
  }

end
