return function (connection, req, args)
   print( 'Request Temperature Data' )
   connection:send("HTTP/1.0 200 OK\r\nContent-Type: application/json\r\nCache-Control: private, no-store\r\n\r\n")
   connection:send('{"current":' .. currentTemperature .. ',"target":' .. targetTemperature .. '}' )
end
