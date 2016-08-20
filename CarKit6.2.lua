wifi.setmode(wifi.SOFTAP)

cfg={}
cfg.ssid="MyCar"
cfg.pwd="123456789"

cfg.ip="192.168.0.1"
cfg.netmask="255.255.255.0"
cfg.gateway="192.168.0.1"

port = 9876

wifi.ap.setip(cfg)
wifi.ap.config(cfg)

function stringStarts(a,b)
    return string.sub(a,1,string.len(b))==b
end

function stringEnds(a,b)
   return b=='' or string.sub(a,-string.len(b))==b
end

chCount = 4
chPin   = {1, 2, 3, 4} -- GPIO 1, 2, 3, 4
xVal    = 0
xSens   = 128 -- Accelerometer sensitivity 
vDly    = 200  -- Delay
cmd     = ""

for i=1, chCount do
    gpio.mode(chPin[i],gpio.OUTPUT)
    gpio.write(chPin[i],gpio.LOW)
end

function exeCmd(st) 
 
    if stringStarts(st, "x") then       -- Set direction
        xVal = tonumber( string.sub(st, 3 ))
    end
    
    if st == "back" then               --> Drive Forwords
        drive(1, 2)
    elseif st == "go" then             --< Drive Backwords
        drive(3, 4)
    elseif st  == "stop" then  -- At botton release
        for i=1, chCount do
            gpio.write(chPin[i],gpio.LOW)
        end
    end
end

function drive (A, B)
    if (xVal > xSens) then          --> Turn direction 1
        gpio.write(chPin[A], gpio.HIGH)
        gpio.write(chPin[B], gpio.LOW)
        tmr.delay((xVal - 128) * vDly)
        gpio.write(chPin[B], gpio.HIGH)
    elseif (xVal < xSens - 5) then  --> Turn direction 2
        gpio.write(chPin[B], gpio.HIGH)
        gpio.write(chPin[A], gpio.LOW)
        tmr.delay((128 - xVal) * vDly)
        gpio.write(chPin[A], gpio.HIGH)
    else                            --> Go Straight
        gpio.write(chPin[A], gpio.HIGH)
        gpio.write(chPin[B], gpio.HIGH) 
    end
end

function receiveData(conn, data)
    cmd = cmd .. data
    local a, b = string.find(cmd, "\n", 1, true)   
    while a do
        exeCmd( string.sub(cmd, 1, a-1) )
        cmd = string.sub(cmd, a+1, string.len(cmd))
        a, b = string.find(cmd, "\n", 1, true)
    end 
end

print("ESP8266 RC receiver 1.0 powered by RoboRemo")
print("SSID: " .. cfg.ssid .. "  PASS: " .. cfg.pwd)
print("RoboRemo app must connect to " .. cfg.ip .. ":" .. port)

srv=net.createServer(net.TCP, 28800)
srv:listen(port,function(conn)
    print("RoboRemo connected")
    conn:on("receive",receiveData)  
    conn:on("disconnection",function(c) 
        print("RoboRemo disconnected")
    end)
end)