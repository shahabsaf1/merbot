local function run(msg)
if msg.text == "hi" then
 return "Hello bb"
end
if msg.text == "Hi" then
 return "Hello honey"
end
if msg.text == "Hello" then
 return "Hi bb"
end
if msg.text == "hello" then
 return "Hi honey"
end
if msg.text == "Salam" then
 return "Salam aleykom"
end
if msg.text == "salam" then
 return "va aleykol asalam"
end
if msg.text == "ZAC" then
 return "kose nanash"
end
if msg.text == "zac" then
 return "kose nanash"
end
if msg.text == "Zac" then
 return "kose nanash"
end
if msg.text == "Shahab" then
 return "ba baba joonam chikar dari"
end
if msg.text == "shahab" then
 return "Ba babam chikar dari"
end
if msg.text == " Hell" then
 return "Yes?"
end
if msg.text == "hell" then
 return "What?"
end
if msg.text == "HELL" then
 return "Jan?"
end
if msg.text == "bot" then
 return "hum?"
end
if msg.text == "Bot" then
 return "Huuuum?"
end
if msg.text == "Sudo" then
 return "The Sudo user off bot is @Shahabambesik"
end
if msg.text == "sudo" then
 return "The Sudo user off bot is @Shahabambesik"
end
if msg.text == "?" then
 return "Hum??"
end
if msg.text == "Bye" then
 return "Babay"
end
if msg.text == "bye" then
 return "Bye Bye"
end
end

return {
 description = "Chat With Robot Server", 
 usage = "chat with robot",
 patterns = {
  "^[Hh]i$",
  "^[Hh]ello$",
  "^[Ss]hahab$",
  "^SHAHAB",
  "^ZAC",
  "^[Bb]ot$",
  "^[Zz]ac$",
  "^[Mm]amshotak$",
  "^[Hh]ell",
  "^HELL",
  "^[Bb]ye$",
   "^[Ss]udo$",
  "^?$",
  "^[Ss]alam$",
  }, 
 run = run,
    --privileged = true,
 pre_process = pre_process
}
