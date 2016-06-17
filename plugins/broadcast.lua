local function deactivate(msg, hash)
  redis:hset(hash, 'stage', 'off')
  return "تم الغاء الطلب"
end
local function activate(msg, hash)
  redis:hset(hash, 'stage', 'one')
  return 'اكتب ما تريد ارساله للمجموعات'
end
local function pre_process(msg)
  local hash = 'broadcast'..msg.to.id
  local get_hash = redis:hgetall(hash)
  local stage = get_hash.stage
  if msg.text then
    if msg.service then
      return msg
    end
    if stage == 'one' then
      redis:hset(hash, 'stage', 'two')
      redis:hset(hash, 'text', msg.text)
      send_large_msg(get_receiver(msg), "هل انت متأكد ؟\nللتأكيد اكتب   /yes\nاو للإلغاء اكتب     /no")
    end
  end
  return msg
end
local function run(msg, matches)
  local hash = 'broadcast'..msg.to.id
  local get_hash = redis:hgetall(hash)
  local stage = get_hash.stage
  local data = load_data(_config.moderation.data)
  if matches[1]:lower() == 'broadcast' then
    return activate(msg, hash)
  end
  if matches[1]:lower() == 'no' and stage == 'two' then
    return deactivate(msg, hash)
  end
  if matches[1]:lower() == 'yes' and stage == 'two' then
    local text = get_hash.text
    for k,v in pairs(data) do 
      if string.match(k, '^%d+$') then
        local id = tonumber(k)
        vardump(id)
        vardump(msg.to.id)
        if id ~= tonumber(msg.to.id) then
          send_large_msg('channel#id'..id, text)
        end
      end
    end
    send_large_msg('channel#id'..msg.to.id, 'تم ارسال الرسالة')
    redis:hset(hash, 'stage', 'off')
    redis:hset(hash, 'text', '')
  end
end
return {
  patterns = {
    "^([Bb]roadcast)$",
    "^([Yy]es)$",
    "^([Nn]o)$",
    },
  run = run,
  pre_process = pre_process
}