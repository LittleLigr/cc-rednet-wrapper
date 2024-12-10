local Wrapper = {}
Wrapper.rednet = {}
Wrapper.rpc_call = {}
Wrapper.regs = {}

function get_func_args_count(func)
  return debug.getinfo(func).nparams;
end


function Wrapper:host(protocol, name)
  Wrapper.rednet.protocol = protocol
  Wrapper.rednet.name = name
  return Wrapper.rpc_call
end


function Wrapper:client(protocol, name)
  Wrapper.rednet.protocol = protocol
  Wrapper.rednet.name = name
  rednet.host(protocol, name)
  return Wrapper.regs
end


function Wrapper:tick(timeout=1)
  local id, message = rednet.receive(Wrapper.rednet.protocol, timeout)
  print(textutils.serialise(message))
  if id then
    --Wrapper.rpc_call[message]()
  end
end


function call_reg_func(name, ...)
  if Wrapper.regs[name].params_count == select('#', ...) then
    local message = {}
    message.rpc = {}
    message.rpc[name] = {...}
    rednet.broadcast(message, Wrapper.rednet.protocol)
  end 
end


function Wrapper:register(name, func)
  Wrapper.regs[name] = {}
  Wrapper.regs[name].params_count = get_func_args_count(func)
  Wrapper.regs[name].call = func
  Wrapper.rpc_call[name] = (
    function (...) 
      call_reg_func(name, ...)
    end
  )
  print("New wrapper registered="..name)
end


return Wrapper