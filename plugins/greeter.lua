--[[
Sends a custom message when a user enters or leave a chat.

!welcome group
The custom message will send to the group. Recommended way.

!welcome pm
The custom message will send to private chat newly joins member.
Not recommended as a privacy concern and the possibility of user reporting the bot.

!welcome disable
Disable welcome service. Also, you can just disable greeter plugin.
--]]

do

  local function is_banned(user_id, chat_id)
    return redis:get('banned:'..chat_id..':'..user_id) or false
  end

  local function is_super_banned(user_id)
      return redis:get('superbanned:'..user_id) or false
  end

  local function run(msg, matches)

    local data = load_data(_config.moderation.data)
    local welcome_stat = data[tostring(msg.to.id)]['settings']['welcome']

    if matches[1] == 'welcome' and is_mod(msg) then
      if matches[2] == 'group' then
        if welcome_stat ~= 'group' then
          welcome_stat = 'group'
          save_data(_config.moderation.data, data)
        end
        return 'Welcome service already enabled.\nWelcome message will shown in group.'
      elseif matches[2] == 'pm' then
        if welcome_stat ~= 'private' then
          welcome_stat = 'private'
          save_data(_config.moderation.data, data)
        end
        return 'Welcome service already enabled.\nWelcome message will send as private message to new member.'
      elseif matches[2] == 'disable' then
        if welcome_stat == 'no' then
          return 'Welcome service is not enabled.'
        else
          welcome_stat = 'no'
          save_data(_config.moderation.data, data)
          return 'Welcome service has been disabled.'
        end
      end
    end

    if welcome_stat ~= 'no' and msg.action and msg.action.type then
      local action = msg.action.type
      if action == 'chat_add_user' or action == 'chat_add_user_link' or action == "chat_del_user" then
        if msg.action.link_issuer then
          user_id = msg.from.id
          new_member = (msg.from.first_name or '')..' '..(msg.from.last_name or '')
          if msg.from.username then
            username = '@'..msg.from.username..' AKA '
          else
            username = ''
          end
          user_flags = msg.flags
        else
	        user_id = msg.action.user.id
          new_member = (msg.action.user.first_name or '')..' '..(msg.action.user.last_name or '')
          if msg.action.user.username then
            username = '@'..msg.action.user.username..' AKA '
          else
            username = ''
          end
          user_flags = msg.action.user.flags
        end
        -- do not greet (super)banned users or API bots.
        if is_super_banned(user_id) or is_banned(user_id, msg.to.id) then
          print 'Ignored. User is banned!'
          return nil
        end
        if user_flags == 4352 then
          print 'Ignored. It is an API bot.'
          return nil
        end
      end

      if matches[1] == 'chat_add_user' or matches[1] == 'chat_add_user_link' then
        if data[tostring(msg.to.id)] then
          local about = ''
          local rules = ''
          if data[tostring(msg.to.id)]['description'] then
            about = '\nDescription :\n'..data[tostring(msg.to.id)]['description']..'\n'
          end
          if data[tostring(msg.to.id)]['rules'] then
            rules = '\nRules :\n'..data[tostring(msg.to.id)]['rules']..'\n'
          end
          local welcomes = 'Welcome '..username..new_member..' ['..user_id..'].\n'
                           ..'You are in group '..msg.to.title..'.\n'
          if welcome_stat == 'group' then
            receiver = get_receiver(msg)
          elseif welcome_stat == 'private' then
            receiver = 'user#id'..msg.from.id
          end
          send_large_msg(receiver, welcomes..about..rules..'\n', ok_cb, false)
        end
      elseif matches[1] == 'chat_del_user' then
        return 'Bye '..new_member..'!'
      end
    end
  end

  return {
    description = 'Sends a custom message when a user enters or leave a chat.',
    usage = {
      moderator = {
        '!welcome group : Welcome message will shows in group.',
        '!welcome pm : Welcome message will send to new member via PM.',
        '!welcome disable : Disable welcome message.'
      },
    },
    patterns = {
      "^!!tgservice (.+)$",
      "^!(welcome) (.*)$"
    },
    run = run
  }

end
