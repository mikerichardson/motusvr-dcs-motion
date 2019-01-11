function LuaExportStart()
-- Works once just before mission start.
-- Example Export.lua file
-- C:\Users\Admin\Saved Games\DCS\Scripts
-- Make initializations of your files or connections here.
-- For example:
-- 1) File
--	local file = io.open("./temp/Export.log", "w")
--	if file then
--		io.output(file)
--	end
	package.path  = package.path..";.\\LuaSocket\\?.lua"
    package.cpath = package.cpath..";.\\LuaSocket\\?.dll"
-- 2) Socket
--  dofile "lua.lua"
--  socket = require("socket")
--  host = host or "localhost"
--  port = port or 8080
--  c = socket.try(socket.connect(host, port)) -- connect to the listener socket
--  c:setoption("tcp-nodelay",true) -- set immediate transmission mode

--  dofile "lua.lua"
  socket = require("socket")
  host = socket.try(socket.dns.toip("localhost"))
  port = 12345
  c = socket.try(socket.udp()) -- connect to the listener socket
  lastbank = 0.0
  lastpitch = 0.0
  lasttime = 0.0
  pi = math.pi
    seatbank = 0.0
    seatpitch = 0.0
end

function LuaExportBeforeNextFrame()
-- Works just before every simulation frame.

-- Call Lo*() functions to set data to Lock On here
-- For example:
--	LoSetCommand(3, 0.25) -- rudder 0.25 right 
--	LoSetCommand(64) -- increase thrust

end

local function be16(v)
  local lo = math.mod(v,256)
  local hi = (v-lo)/256 
  return string.char(hi,lo)
end

local function makelegs(leg1,leg2,leg3)
  return "LEGS"..be16(leg1)..be16(leg2)..be16(leg3)
end

function LuaExportAfterNextFrame()
-- Works just after every simulation frame.

-- Call Lo*() functions to get data from Lock On here.
-- For example:
	local t = LoGetModelTime()
--	local name = LoGetPilotName()
--	local altBar = LoGetAltitudeAboveSeaLevel()
--	local altRad = LoGetAltitudeAboveGroundLevel()
	local pitch, bank, yaw = LoGetADIPitchBankYaw()
--	local engine = LoGetEngineInfo()
--	local HSI    = LoGetControlPanel_HSI()
-- Then send data to your file or to your receiving program:
-- 1) File
--	io.write(string.format("t = %.2f, name = %s, altBar = %.2f, altRad = %.2f, pitch = %.2f, bank = %.2f, yaw = %.2f\n", t, name, altBar, altRad, 57.3*pitch, 57.3*bank, 57.3*yaw))
--	io.write(string.format("t = %.2f ,RPM left = %f  fuel_internal = %f \n",t,engine.RPM.left,engine.fuel_internal))
--	io.write(string.format("ADF = %f  RMI = %f\n ",57.3*HSI.ADF,57.3*HSI.RMI))
-- 2) Socket
--	socket.try(c:send(string.format("t = %.2f, name = %s, altBar = %.2f, alrRad = %.2f, pitch = %.2f, bank = %.2f, yaw = %.2f\n", t, name, altRad, altBar, pitch, bank, yaw)))

  local leg1,leg2,leg3
  if not (bank and pitch) then
    leg1=0
    leg2=0
    leg3=0
  else
    local dt,dbank,dpitch
    if lasttime~=0.0 then
      dt = t-lasttime
	seatpitch = seatpitch - seatpitch*dt*2
	seatbank = seatbank - seatbank*dt*2
      dbank = bank-lastbank
      if dbank>pi then 
	dbank = dbank - 2*pi
      elseif dbank < -pi then
	dbank = dbank + 2*pi
      end
      dpitch = pitch-lastpitch
--      io.write(string.format("%6.2f: pby %.2f,%.2f,%.2f  dt=%.4f dbank=%.4f dpitch=%.4f\n", t, 57.3*pitch, 57.3*bank, 57.3*yaw, dt, dbank, dpitch))
      seatpitch = seatpitch + dpitch
      seatbank = seatbank + dbank
    end
    lastbank = bank
    lastpitch = pitch
    lasttime = t
    leg1 = 10000+seatpitch*60000-seatbank*20000
    leg2 = 10000-seatpitch*60000
    leg3 = 10000+seatpitch*60000+seatbank*20000
    leg1 = math.min(math.max(leg1,1000),19000)
    leg2 = math.min(math.max(leg2,1000),19000)
    leg3 = math.min(math.max(leg3,1000),19000)
  end
  socket.try(c:sendto(makelegs(leg1,leg2,leg3),host,port))
end

function LuaExportStop()
-- Works once just after mission stop.

-- Close files and/or connections here.
-- For example:
-- 1) File
	io.close()
-- 2) Socket
--	socket.try(c:send("quit")) -- to close the listener socket
	c:close()

end

function LuaExportActivityNextEvent(t)
	local tNext = t
		return tNext
end
  

