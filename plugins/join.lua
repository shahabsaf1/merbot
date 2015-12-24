--[[

User can join into a group by replying a message contain an invite link or by
typing !join [invite link].

URL.parse cannot parsing complicated message. So, this plugin only works for
single [invite link] in a post.

[invite link] may be preceeded but must not followed by another characters.

--]]

do

  local function parsed_url(link, segment)
    local parsed_link = URL.parse(link)
    local parsed_path = URL.parse_path(parsed_link.path)
    return parsed_path[segment]
  end

  local function action_by_reply(extra, success, result)
    local hash = parsed_url(result.text, 4)
    join = import_chat_link(hash,ok_cb,false)
  end

  function run(msg, matches)
    if msg.reply_id then
      msgr = get_message(msg.reply_id, action_by_reply, {msg=msg})
    else
      local hash = parsed_url(matches[1], 2)
      join = import_chat_link(hash,ok_cb,false)
    end
  end

  return {
    description = "Join a group chat via its invite link.",
    usage = {
      '!join : Join a group by replying a message containing invite link.',
      '!join [invite link] : Join into a group by providing their `invite link`.',
      },
    patterns = {
      '^!join$',
      '^!join (.*)$'
    },
    run = run
  }

end
