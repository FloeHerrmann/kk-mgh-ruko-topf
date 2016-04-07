-- Variables for the temperature data
currentTemperature = 0
targetTemperature = 0

-- End of data indicator
EOF = "\r"

-- Begin WiFi configuration
local wifiConfig = {}

-- wifi.STATION         -- station: join a WiFi network
-- wifi.SOFTAP          -- access point: create a WiFi network
-- wifi.wifi.STATIONAP  -- both station and access point
wifiConfig.mode = wifi.SOFTAP  -- both station and access point

wifiConfig.accessPointConfig = {}
wifiConfig.accessPointConfig.ssid = "RUKO-"..node.chipid()   -- Name of the SSID you want to create
wifiConfig.accessPointConfig.pwd = "RUKO-"..node.chipid()    -- WiFi password - at least 8 characters

wifiConfig.accessPointIpConfig = {}
wifiConfig.accessPointIpConfig.ip = "192.168.1.1"
wifiConfig.accessPointIpConfig.netmask = "255.255.255.0"
wifiConfig.accessPointIpConfig.gateway = "192.168.1.1"

wifiConfig.stationPointConfig = {}
wifiConfig.stationPointConfig.ssid = "Internet"        -- Name of the WiFi network you want to join
wifiConfig.stationPointConfig.pwd =  ""                -- Password for the WiFi network

-- Tell the chip to connect to the access point

wifi.setmode(wifiConfig.mode)
print('set (mode='..wifi.getmode()..')')

if (wifiConfig.mode == wifi.SOFTAP) or (wifiConfig.mode == wifi.STATIONAP) then
    print('AP MAC: ',wifi.ap.getmac())
    wifi.ap.config(wifiConfig.accessPointConfig)
    wifi.ap.setip(wifiConfig.accessPointIpConfig)
end
if (wifiConfig.mode == wifi.STATION) or (wifiConfig.mode == wifi.STATIONAP) then
    print('Client MAC: ',wifi.sta.getmac())
    wifi.sta.config(wifiConfig.stationPointConfig.ssid, wifiConfig.stationPointConfig.pwd, 1)
end

print('chip: ',node.chipid())
print('heap: ',node.heap())

wifiConfig = nil
collectgarbage()

-- End WiFi configuration

-- Compile server code and remove original .lua files.
-- This only happens the first time afer the .lua files are uploaded.

local compileAndRemoveIfNeeded = function(f)
   if file.open(f) then
      file.close()
      print('Compiling:', f)
      node.compile(f)
      file.remove(f)
      collectgarbage()
   end
end

local serverFiles = {
   'httpserver.lua',
   'httpserver-b64decode.lua',
   'httpserver-basicauth.lua',
   'httpserver-conf.lua',
   'httpserver-connection.lua',
   'httpserver-error.lua',
   'httpserver-header.lua',
   'httpserver-request.lua',
   'httpserver-static.lua',
}
for i, f in ipairs(serverFiles) do compileAndRemoveIfNeeded(f) end

compileAndRemoveIfNeeded = nil
serverFiles = nil
collectgarbage()

-- Connect to the WiFi access point.
-- Once the device is connected, you may start the HTTP server.

if (wifi.getmode() == wifi.STATION) or (wifi.getmode() == wifi.STATIONAP) then
    local joinCounter = 0
    local joinMaxAttempts = 5
    tmr.alarm(0, 3000, 1, function()
       local ip = wifi.sta.getip()
       if ip == nil and joinCounter < joinMaxAttempts then
          print('Connecting to WiFi Access Point ...')
          joinCounter = joinCounter +1
       else
          if joinCounter == joinMaxAttempts then
             print('Failed to connect to WiFi Access Point.')
          else
             print('IP: ',ip)
          end
          tmr.stop(0)
          joinCounter = nil
          joinMaxAttempts = nil
          collectgarbage()
       end
    end)
end

-- Uncomment to automatically start the server in port 80
if (not not wifi.sta.getip()) or (not not wifi.ap.getip()) then
    dofile("httpserver.lc")(80)
end

file.open( "parse.txt" , "r" )
parseData = ( file.readline() )
parseData = string.gsub( parseData , "\r" , "" )
parseData = string.gsub( parseData , "\n" , "" )
file.close()

print( "Parsing >> " , parseData )

if ( parseData == "true" ) then 
	-- Handling incoming data
	-- Data from arduino are send in a specific format: {current temp};{target temp}<CR>
	-- Example: 67.5;80.0\r

	uart.on(
	  "data",
	  EOF,
	  function( data )
		tempData = string.gsub( data , "\r" , "" )
		tempData = string.gsub( tempData , "\n" , "" )
		
		print( "Received >> " , tempData )
		
		if tempData == "noParsing" then
			file.open("parse.txt","w")
			file.write( "false" )
			file.close()
			print( "Parsing Disabled AFTER Restart" )
		else
			start = 1
			currentTemperature = tonumber( string.sub( data , 1 , string.find( data , ";" , 1 , string.len( data ) ) - 1 ) )
			start = string.find( data , ";" , start , string.len ( data ) ) + 1
			targetTemperature = tonumber( string.sub( data , start , string.find( data , EOF , start , string.len( data ) ) - 1 ) )
			print( "Parsed Data: ", currentTemperature , targetTemperature )
		end
	  end, 
	  0
	)
	
	-- UART setup
	uart.setup( 0 , 9600 , 8 , 0 , 1 , 0 )
end