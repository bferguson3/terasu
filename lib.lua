--Ben's Lib

function round(num, numDecimalPlaces)
    -- From luausers
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function include(fileName)
    local m = love.filesystem.load(fileName)
    m()
end

function incbin(fn)
    return love.filesystem.read(fn)
end

function split (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

function LoadMaps()
    local m = {}
    local fns = love.filesystem.getDirectoryItems('maps') -- enumerate maps folder
    for i=1,#love.filesystem.getDirectoryItems('maps') do 
        local n = split(fns[i],'.')[1] -- get filename
        local mapstr = love.filesystem.read('maps/' .. fns[i]) -- read csv as string
        --print(mapstr)
        mapstr = string.gsub(mapstr, '\n', ',') -- chop newlines 
        m[i] = split(mapstr, ',') -- split into lua table
        for k=1,#m[i] do 
            m[i][k] = tonumber(m[i][k]) -- convert char to num
        end
    end
    return m
end

function LoadLightMaps()
    local m = {}
    local fns = love.filesystem.getDirectoryItems('lightmaps') -- enumerate maps folder
    for i=1,#love.filesystem.getDirectoryItems('lightmaps') do 
        local n = split(fns[i],'.')[1] -- get filename
        local mapstr = love.filesystem.read('lightmaps/' .. fns[i]) -- read csv as string
        --print(mapstr)
        mapstr = string.gsub(mapstr, '\n', ',') -- chop newlines 
        m[i] = split(mapstr, ',') -- split into lua table
        for k=1,#m[i] do 
            m[i][k] = tonumber(m[i][k]) -- convert char to num
        end
    end
    return m
end

--[[
function bitoper(a, b, oper)
   local r, m, s = 0, 2^52
   repeat
      s,a,b = a+b+m, a%m, b%m
      r,m = r + m*oper%(s-a-b), m/2
   until m < 1
   return r
end

function AND(a, b)
    return bitoper(a, b, 4)
end

function XOR(a, b)
    return bitoper(a, b, 3)
end

function OR(a, b)
    return bitoper(a, b, 1)
end
]]
function AND(a, b)
    local result = 0
    local bitval = 1
    while a > 0 and b > 0 do
      if a % 2 == 1 and b % 2 == 1 then -- test the rightmost bits
          result = result + bitval      -- set the current bit
      end
      bitval = bitval * 2 -- shift left
      a = math.floor(a/2) -- shift right
      b = math.floor(b/2)
    end
    return result
end

function clamp(min, val, max)
    return math.max(min, math.min(val, max));
end

-- define DEBUG object 
debug = {
    showFPS = false,
    logFPS = false,
    showFrameDelta = false
}

debug.init = function()
    debug.file = 'debug' .. os.time() .. '.log'
    love.filesystem.write(debug.file, '')
end

debug.print = function (tx) 
    love.filesystem.append(debug.file, tx .. '\n')
    print(tx)
end
  