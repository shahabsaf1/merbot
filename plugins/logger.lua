do

  function run(msg, matches)
    if is_chat_msg(msg) then
      local log_file = './data/log/'..msg.to.id..'_log.csv'
      local logtxt = os.date('%F;%T', msg.date)..';'..msg.to.title..';'..msg.to.id
                     ..';'..(msg.from.first_name or '')..(msg.from.last_name or '')
                     ..';@'..(msg.from.username or '')..';'..msg.from.id..';'
                     ..msg.text..'\n'
      local log_file = io.open(log_file, 'a')

      log_file:write(logtxt)
      log_file:close()

      if is_mod(msg) then
        if matches[1] == 'get' then
          send_document('chat#id'..msg.to.id, log_file, ok_cb, false)
        elseif matches[1] == 'pm' then
          send_document('user#id'..msg.from.id, log_file, ok_cb, false)
        end
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
      '^!log (pm)$',
      '^.+$'
    },
    run = run
  }

end

