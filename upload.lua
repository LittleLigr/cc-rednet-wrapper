shell.execute("rm", "rpc_client.lua")
shell.execute("rm", "rpc_host.lua")
shell.execute("rm", "rpc_common.lua")
shell.execute("rm", "rednet-wrapper.lua")

shell.execute("wget", "https://raw.githubusercontent.com/LittleLigr/cc-rednet-wrapper/refs/heads/main/rednet-wrapper.lua")
shell.execute("wget", "https://raw.githubusercontent.com/LittleLigr/cc-rednet-wrapper/refs/heads/main/rpc_common.lua")
shell.execute("wget", "https://raw.githubusercontent.com/LittleLigr/cc-rednet-wrapper/refs/heads/main/rpc_host.lua")
shell.execute("wget", "https://raw.githubusercontent.com/LittleLigr/cc-rednet-wrapper/refs/heads/main/rpc_client.lua")
