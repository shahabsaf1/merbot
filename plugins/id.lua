--[[

Print user identification/informations by replying their post or by providing
their username or print_name.

!id <text> is the least reliable because it will scan trough all of members
and print all member with <text> in their print_name.

--]]

do

  local function scan_name(extra, success, result)
    local founds = {}
    for k,member in pairs(result.members) do
      local fields = {'first_name', 'last_name', 'print_name', 'username'}
      for k,field in pairs(fields) do
        if member[field] and type(member[field]) == 'string' then
          if member[field]:match(extra.user) then
            founds[tostring(member.id)] = member
          end
        end
      end
    end
    if next(founds) == nil then -- Empty table
      send_msg(extra.receiver, extra.user..' not found on this chat.', ok_cb, false)
    else
      local text = ''
      for k,user in pairs(founds) do
        text = text..'Name: '..(user.first_name or '')..' '..(user.last_name or '')..'\n'
               ..'User name: @'..(user.username or '')..'\n'
               ..'ID: '..(user.id  or '')..'\n\n'
      end
      send_msg(extra.receiver, text, ok_cb, false)
    end
  end

  local function res_user_callback(extra, success, result)
    if success == 1 then
      local text = 'ID for '..extra.user..' AKA '..(result.first_name or '')..' '
                   ..(result.last_name or '')..' is '..result.id
      send_msg(extra.receiver, text, ok_cb, false)
    else
      send_msg(extra.receiver, extra.user..' not found on this chat.', ok_cb, false)
    end
  end

  local function action_by_reply(extra, success, result)
    local text = 'Name : '..(result.from.first_name or '')..' '..(result.from.last_name or '')..'\n'
                 ..'User name: @'..(result.from.username or '')..'\n'
                 ..'ID : '..result.from.id
    send_msg(extra.receiver, text, ok_cb,  true)
  end

  local function returnids(extra, success, result)
    local text = '['..result.id..'] '..result.title..'.\n'
                 ..result.members_num..' members.\n\n'
    i = 0
    for k,v in pairs(result.members) do
      i = i+1
      if v.last_name then
        last_name = ' '..v.last_name
      else
        last_name = ''
      end
      if v.username then
        user_name = ' @'..v.username
      else
        user_name = ''
      end
      text = text..i..'. ['..v.id..'] '..user_name..' '..v.first_name..last_name..'\n'
    end
    send_large_msg(extra.receiver, text)
  end

  local function run(msg, matches)
    local receiver = get_receiver(msg)
    if is_chat_msg(msg) then
      if msg.text == '!id' then
        if msg.reply_id then
          if is_mod(msg) then
            msgr = get_message(msg.reply_id, action_by_reply, {receiver=receiver})
          end
        else
          local text = 'Name : '..(msg.from.first_name or '')..' '..(msg.from.last_name or '')..'\n'
                       ..'User name: @'..(msg.from.username or '')..'\n'
                       ..'ID : ' .. msg.from.id
          local text = text..'\n\nYou are in group '
                       ..msg.to.title..' (ID: '..msg.to.id..')'
          return text
        end
      elseif is_mod(msg) and matches[1] == 'chat' then
        if matches[2] and is_sudo(msg) then
          chat_info('chat#id'..matches[2], returnids, {receiver=receiver})
        else
          chat_info(receiver, returnids, {receiver=receiver})
        end
      elseif is_mod(msg) and string.match(matches[1], '^@.+$') then
        username = string.gsub(matches[1], '@', '')
        msgr = res_user(username, res_user_callback, {receiver=receiver, user=matches[1]})
      elseif is_mod(msg) and string.gsub(matches[1], ' ', '_') then
        user = string.gsub(matches[1], ' ', '_')
        chat_info(receiver, scan_name, {receiver=receiver, user=matches[1]})
      end
    else
      return 'You are not in a group.'
    end
  end

  return {
    description = 'Know your id or the id of a chat members.',
    usage = {
      user = {
        '!id: Return your ID and the chat id if you are in one.'
      },
      moderator = {
        '!id: Return ID of replied user if used by reply.',
        '!id chat: Return the IDs of the current chat members.',
        '!id chat <chat_id>: Return the IDs of the current <chat_id> members.',
        '!id <id>: Return the IDs of the <id>.',
        '!id @<user_name>: Return the member @<user_name> ID from the current chat.',
        '!id <text>: Search for users with <text> on print_name on current chat.'
      },
    },
    patterns = {
      "^!id$",
      "^!id (chat) (%d+)$",
      "^!id (.*)$",
      "^!id (%d+)$"
    },
    run = run
  }

end
