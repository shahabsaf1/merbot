do

  local function pre_process(msg)
    if is_chat_msg(msg) then
      local logtxt = os.date('%F;%T', msg.date)..';'..msg.to.title..';'..msg.to.id
                     ..';'..(msg.from.first_name or '')..(msg.from.last_name or '')
                     ..';@'..(msg.from.username or '')..';'..msg.from.id..';'
                     ..(msg.text or msg.media.type..':'..(msg.media.caption or ''))..'\n'
      local file = io.open('./data/logs/'..msg.to.id..'_log.csv', 'a')
      file:write(logtxt)
      file:close()
    end
    return msg
  end

  function run(msg, matches)
    if is_mod(msg.from.id, msg.to.id) then
      if matches[1] == 'get' then
        send_document('chat#id'..msg.to.id, './data/logs/'..msg.to.id..'_log.csv', ok_cb, false)
      elseif matches[1] == 'pm' then
        send_document('user#id'..msg.from.id, './data/logs/'..msg.to.id..'_log.csv', ok_cb, false)
      end
    end
  end

  return {
    description = 'Logging group messages.',
    usage = {
      '!log get : Send chat log to its chat group',
      '!log pm : Send chat log to private message'
      },
    patterns = {
      '^!log (get)$',
      '^!log (pm)$'
    },
    run = run,
    pre_process = pre_process
  }

end

