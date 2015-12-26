do

  function run(msg, matches)
    return 'Merbot\n'..VERSION..'\nGitHub: https://git.io/v4Oi0\nLicense: GNU GPL v2'
  end

  return {
    description = 'Shows bot version',
    usage = '!version: Shows bot version',
    patterns = {
      '^!version$'
    },
    run = run
  }

end
