do

  local function run(msg, matches)
    -- comment this line if you want reddit.lua works in private message.
    if not is_chat_msg(msg) then return nil end

    if is_chat_msg(msg) then
      thread_limit = 5
    else
      thread_limit = 8
    end

    if matches[1] then
      if matches[1]:match('^r/') then
        url = 'http://www.reddit.com/'..matches[1]..'/.json?limit='..thread_limit
      else
        url = 'http://www.reddit.com/search.json?q='..matches[1]..'&limit='..thread_limit
      end
		else
      url = 'http://www.reddit.com/.json?limit='..thread_limit
    end

    -- Do the request
    local res, code = https.request(url)
    if code ~=200 then return nil  end

    local jdat = JSON.decode(res)
	  if #jdat.data.children == 0 then
		  return nil
	  end

    local i = 0 + 1
	  local subreddit = ''
	  for i,v in ipairs(jdat.data.children) do
		  if v.data.over_18 then
			  subreddit = subreddit..i..'. [NSFW] '
		  else
        subreddit = subreddit..i..'. '
      end
		  local long_url = '\n'
		  if not v.data.is_self then
			  long_url = '\n'..v.data.url..'\n'
		  end
		  subreddit = subreddit..'[redd.it/'..v.data.id..'] '..v.data.title..'\n'
	  end
    return subreddit
  end

  return {
    description = 'Returns the five (if group) or eight (if private message) top posts for the given subreddit or query, or from the frontpage.',
    usage = {
      ' !reddit : Reddit frontpage.',
      ' !reddit r/[query] : Subreddit',
      ' !reddit [query] : Search subreddit.'
    },
    patterns = {
      '^!reddit$',
      '^!reddit (.*)$'
    },
    run = run
  }

end
