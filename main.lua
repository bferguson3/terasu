-- wolf demo
-- raycasting 

local ffi = require 'ffi'
ffi.cdef[[
    typedef struct { uint8_t r, g, b, a; } pixel;
]]


local mapWidth = 24
local mapHeight = 24
local textureSize = 64
--
local gWidth = 320
local gHeight = 200
local screenWidth = 319-8 --* 0.7
local screenHeight = 199-40 --* 0.7

local pixelScale = 2

local playerX, playerY = 12, 12.5
local dirX, dirY = -1, 0
local viewplaneX, viewplaneY = 0, 0.66 -- 66 degree fov

local ceilingTexture = 3

lightIntensity = 3
lightEnabled = true

m = love.filesystem.load('lib.lua'); m()

maps = LoadMaps()
lightMaps = LoadLightMaps()

--generate linear pixel data for placeholder textures
textures = {}

FPS = 0.0
secondCtr = 0.0

buf = nil

EGA = {
    { 0, 0, 0, 1 }, -- black
    { 0, 0, 170/255, 1 }, -- blue 
    { 0, 170/255, 0, 1 }, -- green 
    { 0, 170/255, 170/255, 1 }, -- cyan 
    { 170/255, 0, 0, 1 }, -- red 
    { 170/255, 0, 170/255, 1 }, -- magenta
    { 170/255, 85/255, 0, 1 }, -- dk yello
    { 170/255, 170/255, 170/255, 1 }, -- dk. white
    { 85/255, 85/255, 85/255, 1 }, -- grey
    { 85/255, 85/255, 1, 1 }, -- b blue
    { 85/255, 1, 85/255, 1 }, -- b green
    { 85/255, 1, 1, 1 }, -- b cyan 
    { 1, 85/255, 85/255, 1 }, -- b red
    { 1, 85/255, 1, 1 }, -- b magenta 
    { 1, 1, 85/255, 1 },-- b yellow
    { 1, 1, 1, 1 } -- b white
}
EGA[0] = { 0, 0, 0, 0 }


local screenBuffer 
local drawData 
local drawBuffer 
zBuffer = {}
local currentMap = 1

function love.load()
    
    a = love.graphics.newCanvas()
    
    screenBuffer = ffi.new("pixel[?]", screenWidth*screenHeight)
    bufSize = ffi.sizeof(screenBuffer)
    love.graphics.setDefaultFilter(Fm)
    for i=0,(screenWidth*screenHeight)-1 do 
        screenBuffer[i].a = 255
    end
    --textureData = ffi.new("pixel[64][64*64]")
    
    drawData = love.image.newImageData(screenWidth, screenHeight, "rgba8", ffi.string(screenBuffer, bufSize))
    drawBuffer = love.graphics.newImage(drawData)

    local NUMBER_OF_TEXTURES = 9
    --for i=1,NUMBER_OF_TEXTURES do 
    --    o = {}
    --    table.insert(textures, o)
    --    for j=1,(textureSize * textureSize) do 
    --        j = { 0, 0, 0 }
    --        table.insert(textures[i], j)
    --    end
    --end
    
    textureData = ffi.new("pixel[10][64*64]")
    for i=1,NUMBER_OF_TEXTURES do 
        
        for j=0,(textureSize * textureSize)-1 do     
            textureData[i][j].a = 255
        end
        --table.insert(textureData, o)
    end
    
    love.window.setMode(gWidth * pixelScale, gHeight * (pixelScale*1.2))
    
    for xx=0,textureSize-1 do 
        for yy=0,textureSize-1 do 
            local txn = (textureSize * yy) + xx
            textureData[5][txn].r = 0
            textureData[5][txn].g = 255
            textureData[5][txn].b = 0
            --textureData[5][txn].a = 255
            
            textureData[6][txn].r = 0.8 * 255
            textureData[6][txn].g = 0.1 * 255
            textureData[6][txn].b = 0.1 * 255
            --textureData[6][txn].a = 255
            
            textureData[7][txn].r = 0.9 * 255
            textureData[7][txn].g = 0.3 * 255
            textureData[7][txn].b = 0.3 * 255
            --textureData[7][txn].a = 255
            
            textureData[8][txn].r = 0.7 * 255
            textureData[8][txn].g = 0.7 * 255
            textureData[8][txn].b = 0.7 * 255
            --textureData[8][txn].a = 255
        end
    end
    smileTexture = love.image.newImageData('tex/Untitled.png')
    fakeTex = love.image.newImageData('tex/tex2.png')
    stoneTex = love.image.newImageData('tex/tex3.png')
    blueTex = love.image.newImageData('tex/tex4.png')
    floorTex = love.image.newImageData('tex/floor.png')
    for i=0,smileTexture:getHeight()-1 do 
        for j=0,smileTexture:getWidth()-1 do 
            local r, g, b, a = smileTexture:getPixel(i, j)
            textureData[1][(j*64)+i].r = r * 255
            textureData[1][(j*64)+i].g = g * 255
            textureData[1][(j*64)+i].b = b * 255
            --textureData[1][(j*64)+i].a = 255

            r, g, b, a = blueTex:getPixel(i, j)
            textureData[2][(j*64)+i].r = r * 255
            textureData[2][(j*64)+i].g = g * 255
            textureData[2][(j*64)+i].b = b * 255
            --textureData[2][(j*64)+i].a = 255

            r, g, b, a = stoneTex:getPixel(i, j)
            textureData[3][(j*64)+i].r = r * 255
            textureData[3][(j*64)+i].g = g * 255
            textureData[3][(j*64)+i].b = b * 255
            --textureData[3][(j*64)+i].a = 255

            r, g, b, a = fakeTex:getPixel(i, j)
            textureData[4][(j*64)+i].r = r * 255
            textureData[4][(j*64)+i].g = g * 255
            textureData[4][(j*64)+i].b = b * 255
            --textureData[4][(j*64)+i].a = 255

            r, g, b, a = floorTex:getPixel(i, j)
            textureData[9][(j*64)+i].r = r * 255
            textureData[9][(j*64)+i].g = g * 255
            textureData[9][(j*64)+i].b = b * 255
            --textureData[9][(j*64)+i].a = 255
        end
    end
    
    moved = true
    zBuffer = {}
    for i=0,screenWidth do 
        zBuffer[i] = 0.0
    end
end

--frameMode = 30

function CheckInput()

    if love.keyboard.isDown('up') then 
        local tgx = math.floor(playerX + dirX * (playerSpeed*5))
        local tgy = math.floor(playerY)
        if maps[currentMap][(tgy*24)+tgx+1] < 2 then 
            moved = true 
            playerX = playerX + (dirX * playerSpeed)
        end
        tgx = math.floor(playerX)
        tgy = math.floor(playerY + dirY * (playerSpeed*5))
        if maps[currentMap][(tgy*24)+tgx+1] < 2 then 
            moved = true
            playerY = playerY + (dirY * playerSpeed)
        end
    elseif love.keyboard.isDown('down') then 
        local tgx = math.floor(playerX - dirX * (playerSpeed*5))
        local tgy = math.floor(playerY)
        if maps[currentMap][(tgy*24)+tgx+1] < 2 then 
            moved = true 
            playerX = playerX - (dirX * playerSpeed)
        end
        tgx = math.floor(playerX)
        tgy = math.floor(playerY - dirY * (playerSpeed*5))
        if maps[currentMap][(tgy*24)+tgx+1] < 2 then
            moved = true 
            playerY = playerY - (dirY * playerSpeed)
        end
    end
    
    if love.keyboard.isDown('1') then Fm = 'nearest'; love.graphics.setDefaultFilter('nearest', 'nearest') elseif love.keyboard.isDown('2') then Fm = 'linear'; love.graphics.setDefaultFilter('linear', 'linear') end 
    if love.keyboard.isDown('3') then Fr = (1/30) end 
    if love.keyboard.isDown('4') then Fr = (1/60) end 
    if love.keyboard.isDown('right') then 
        moved = true 
        local r = math.cos(-rotSpeed)
        local rn = math.sin(-rotSpeed)
        local olddirx = dirX
        dirX = dirX * r - dirY * rn
        dirY = olddirx * rn + dirY * r
        local oldplanex = viewplaneX
        viewplaneX = viewplaneX * r - viewplaneY * rn
        viewplaneY = oldplanex * rn + viewplaneY * r
    elseif love.keyboard.isDown('left') then 
        moved = true 
        local r = math.cos(rotSpeed)
        local rn = math.sin(rotSpeed)
        local olddirx = dirX
        dirX = dirX * r - dirY * rn
        dirY = olddirx * rn + dirY * r
        local oldplanex = viewplaneX
        viewplaneX = viewplaneX * r - viewplaneY * rn
        viewplaneY = oldplanex * rn + viewplaneY * r
    end
end

-- UPDATE! --
local lightFlashCounter = 0
local acc = 0
Fr = (1/30)
local fiveSeconds = 0

function love.update(dT)
    secondCtr = secondCtr + dT
    if secondCtr > 1.0 then 
        secondCtr = secondCtr - 1

        fiveSeconds = fiveSeconds + 1
        if fiveSeconds >= 5 then 
            collectgarbage(); fiveSeconds = 0
        end
    end 

    local fstart = love.timer.getTime()

    acc = acc + dT 
    if acc < Fr then return else acc = acc - Fr end 
    if Fr == (1/30) then dT = dT * 2 end 
    
    FPS = 1.0 / dT;
    -- EVERYTHING BELOW IS ONLY DRAW RELATED
    playerSpeed = 3 * dT
    rotSpeed = 2 * dT

    CheckInput()
    
    if moved then 
        RaycastDraw()
        moved = false 
    end
    SpriteTest()

    drawData = love.image.newImageData(screenWidth, screenHeight, "rgba8", ffi.string(screenBuffer, bufSize))
    if drawData then 
        drawBuffer:replacePixels(drawData) end 
    drawData = nil 
    
    fend = 1/(love.timer.getTime() - fstart)
end



function RaycastDraw()
    -- Clear buffer 
    --for i=0,(screenWidth*screenHeight) do 
    --    screenBuffer[i].r = 0
    --    screenBuffer[i].g = 0
    --    screenBuffer[i].b = 0
    --    screenBuffer[i].a = 0
    --end

    local y -- FLOOR tracing 
    local rayDirX0 = dirX - viewplaneX
    local rayDirY0 = dirY - viewplaneY
    local rayDirX1 = dirX + viewplaneX
    local rayDirY1 = dirY + viewplaneY
    
    for y = 0, screenHeight do --screenHeight/2, screenHeight do 
        
        local p = math.floor(y - screenHeight / 2)
        local posZ = screenHeight / 2
        local rowDistance = posZ / p 
        local floorStepX = rowDistance * (rayDirX1 - rayDirX0) / screenWidth
        local floorStepY = rowDistance * (rayDirY1 - rayDirY0) / screenWidth 
        local floorX = playerX + rowDistance * rayDirX0 
        local floorY = playerY + rowDistance * rayDirY0 
        local mx, my = math.floor(playerX), math.floor(playerY)
        local lightNum = lightMaps[currentMap][(my*24)+mx+1]    
        local fader = clamp(0.08, (EGA[lightNum+1][1] / rowDistance) * lightIntensity, EGA[lightNum+1][1])
        local fadeg = clamp(0.08, (EGA[lightNum+1][2] / rowDistance) * lightIntensity, EGA[lightNum+1][2])
        local fadeb = clamp(0.08, (EGA[lightNum+1][3] / rowDistance) * lightIntensity, EGA[lightNum+1][3])
        for yx = 0, screenWidth do 
            local cellX = math.floor(floorX)
            local cellY = math.floor(floorY)
            local tx = math.max(math.floor(textureSize * (floorX - cellX)), 0)
            local ty = math.max(math.floor(textureSize * (floorY - cellY)), 0)
            if tx >= textureSize then tx = textureSize - 1 end 
            if ty >= textureSize then ty = textureSize - 1 end
            floorX = floorStepX + floorX 
            floorY = floorY + floorStepY
            --local floorTexture = 9
            cellY = clamp(0, cellY, 23)
            cellX = clamp(0, cellX, 23)
            local texnum = maps[currentMap][math.floor((cellY*24)+cellX+1)]-- cellX and cellY
            if texnum == 0 then texnum = 5 end 
            if texnum == 1 then texnum = 9 end 
            local c = textureData[texnum][(ty*textureSize)+tx]
            
            local px = math.floor((y*screenWidth)+yx)
            local r, g, b = c.r*fader, c.g*fadeg, c.b*fadeb
            screenBuffer[px].r = r 
            screenBuffer[px].g = g 
            screenBuffer[px].b = b 
            --screenBuffer[px].a = 255
            px = math.floor(((screenHeight-y)*screenWidth) + yx)
            c = textureData[ceilingTexture][(textureSize*ty)+tx]
            r, g, b = c.r*fader, c.g*fadeg, c.b*fadeb
            screenBuffer[px].r = r 
            screenBuffer[px].g = g 
            screenBuffer[px].b = b 
            --screenBuffer[px].a = 255
        end
    end

    local x -- LINE tracing for walls
    
    for x = 0, screenWidth do  -- for every X pixel...
        local camX = 2 * x / screenWidth - 1 -- find the camera position
        local rayDirX = dirX + viewplaneX * camX -- the direction vector X
        local rayDirY = dirY + viewplaneY * camX -- and Y
        local mapx = math.floor(playerX) -- the tile number in x
        local mapy = math.floor(playerY) -- and y
        local sidedistX, sidedistY = 0.0, 0.0
        local deltaX = math.abs(1/rayDirX) -- the 'step' to next tile edge
        local deltaY = math.abs(1/rayDirY) -- in x and y
        local perpWallDist
        local stepX, stepY
        hit = 0
        local side 
        if rayDirX < 0 then  -- left
            stepX = -1; sidedistX = (playerX - mapx) * deltaX;
        else    -- or right?
            stepX = 1; sidedistX = (mapx + 1 - playerX) * deltaX;
        end
        if rayDirY < 0 then  -- down
            stepY = -1; sidedistY = (playerY - mapy) * deltaY;
        else -- or up?
            stepY = 1; sidedistY = (mapy + 1 - playerY) * deltaY;
        end
        while hit == 0 do -- find the next ray collision...
            if sidedistX < sidedistY then 
                sidedistX = sidedistX + deltaX
                mapx = mapx + stepX
                side = 0
            else
                sidedistY = sidedistY + deltaY
                mapy = mapy + stepY
                side = 1
            end
            if (mapx < 0) or (mapx > 23) then 
                hit = 1
                mapx = clamp(0, mapx, 23) 
            end 
            if (mapy < 0) or (mapy > 23) then 
                hit = 1
                mapy = clamp(0, mapy, 23)
            end
            if maps[currentMap][math.floor((mapy*24)+mapx+1)] > 1 then hit = 1 end 
        end
        if side == 0 then -- its top/bottom edge
            perpWallDist = (mapx - playerX + (1 - stepX)/2) / rayDirX
        else -- its l/r edge
            perpWallDist = (mapy - playerY + (1 - stepY)/2) / rayDirY
        end
        
        -- determine wall height based on distance and resolution
        local lineHeight = math.floor(screenHeight / perpWallDist) 
        local drawStart = math.floor(-lineHeight / 2 + screenHeight / 2) + 1
        if drawStart < 0 then drawStart = 0 end 
        local drawEnd = lineHeight / 2 + screenHeight / 2
        if drawEnd >= screenHeight then drawEnd = screenHeight - 1 end 
        local mpos = math.floor((mapy*24)+mapx+1)
        local texNum = maps[currentMap][mpos]
        local lightNum = lightMaps[currentMap][mpos]
        if texNum == 0 then texNum = 1 end
        if (texNum < 1) then print('Bad texture' .. texNum) end 
        if (texNum > 8) then print('Bad texture' .. texNum) end 
        local wallX = 0.0
        if side == 0 then wallX = playerY + perpWallDist * rayDirY
                    else wallX = playerX + perpWallDist * rayDirX end 
        wallX = wallX - math.floor(wallX)
        local texX = math.floor(wallX * textureSize)
        if (side == 0) and (rayDirX > 0) then texX = textureSize - texX - 1 end
        if (side == 1) and (rayDirY < 0) then texX = textureSize - texX - 1 end 
        local step = 1.0 * textureSize / lineHeight
        local texPos = (drawStart - screenHeight / 2 + lineHeight / 2) * step 
        local fader = clamp(0.08, EGA[lightNum+1][1] / perpWallDist*lightIntensity, EGA[lightNum+1][1])
        local fadeg = clamp(0.08, EGA[lightNum+1][2] / perpWallDist*lightIntensity, EGA[lightNum+1][2])
        local fadeb = clamp(0.08, EGA[lightNum+1][3] / perpWallDist*lightIntensity, EGA[lightNum+1][3])
        for yy=drawStart, drawEnd do 
            local texY = math.floor(texPos)
            if texY >= textureSize then texY = textureSize - 1 end
            texPos = texPos + step 
            local c = textureData[texNum][textureSize * texY + texX]
            
            --fader, fadeb, fadeg = 1, 1, 1
            --local lightFade = clamp(0.05, ((fader+fadeg+fadeb)/3)*5, 1)
            
            local px = math.floor((yy*screenWidth)+x)
            if side == 0 then 
                local r, g, b = c.r*fader, c.g*fadeg, c.b*fadeb
                screenBuffer[px].r = r 
                screenBuffer[px].g = g 
                screenBuffer[px].b = b 
                --screenBuffer[px].a = 255
            else 
                
                local r, g, b = c.r*fader, c.g*fadeg, c.b*fadeb
                screenBuffer[px].r = r * 0.75
                screenBuffer[px].g = g * 0.75
                screenBuffer[px].b = b * 0.75
                --screenBuffer[px].a = 255
            end
        end
        zBuffer[x] = perpWallDist
    end
end


function SpriteTest()
    -- Sprites
    sprite = {}
    sprite.x = 6
    sprite.y = 15
    local spriteDistance = ((playerX - sprite.x)*(playerX - sprite.x) + (playerY - sprite.y)*(playerY - sprite.y))
    --print(spriteDistance)
    local sprX = sprite.x - playerX
    local sprY = sprite.y - playerY 
    -- sprite transform
    local invDet = 1 / (viewplaneX * dirY - dirX * viewplaneY)
    local transformX = invDet * ((dirY * sprX) - (dirX * sprY))
    local transformY = invDet * ((-viewplaneY * sprX) + (viewplaneX * sprY))
    local spriteScrX = (screenWidth/2) * (1 + transformX / transformY)
    -- sprite height
    local sprHeight = math.abs(math.floor(screenHeight / transformY))/2
    local sprdrawstartY = math.floor(-sprHeight / 2 + screenHeight / 2)
    if sprdrawstartY < 0 then sprdrawstartY = 0 end 
    local sprdrawendY = math.floor(sprHeight / 2 + screenHeight / 2)
    if sprdrawendY >= screenHeight then sprdrawendY = screenHeight - 1 end 
    -- sprite width 
    local sprWidth = math.abs(math.floor(screenHeight / transformY)) /2
    local sprdrawstartX = math.floor((-sprWidth / 2) + spriteScrX)
    if sprdrawstartX < 0 then sprdrawstartX = 0 end 
    local sprdrawendX = math.floor((sprWidth / 2) + spriteScrX)
    if sprdrawendX >= screenWidth then sprdrawendX = screenWidth - 1 end 
    local lightNum = lightMaps[currentMap][math.floor(math.floor(sprite.y) * 24 + sprite.x)]
    local fader = clamp(0.08, (EGA[lightNum+1][1] / spriteDistance) * lightIntensity, EGA[lightNum+1][1])
    local fadeg = clamp(0.08, (EGA[lightNum+1][2] / spriteDistance) * lightIntensity, EGA[lightNum+1][2])
    local fadeb = clamp(0.08, (EGA[lightNum+1][3] / spriteDistance) * lightIntensity, EGA[lightNum+1][3])
                
    --
    for stripe = sprdrawstartX, sprdrawendX do 
        local sprtexX = math.floor(((stripe - (-(sprWidth/2) + spriteScrX)) * textureSize)/sprWidth)
        if (transformY > 0) and (stripe > 0) and (stripe < screenWidth) and (transformY < zBuffer[stripe]) then 
            for sy = sprdrawstartY, sprdrawendY do 
                local d = sy - (screenHeight /2) + (sprHeight /2)
                d = math.floor(d)
                local textureY = math.floor(((d * textureSize) / sprHeight))
                local c = textureData[3][math.floor((textureSize * textureY) + sprtexX)]
                if c == nil then c = ffi.new('pixel') end
                
                screenBuffer[(sy*screenWidth) + stripe].r = c.r * fader
                screenBuffer[(sy*screenWidth) + stripe].g = c.g * fadeg
                screenBuffer[(sy*screenWidth) + stripe].b = c.b * fadeb
                --screenBuffer[(sy*screenWidth) + stripe].a = 255
            end
        end
    end
    --if zBuffer[sprdrawstartX] then 
    --    if (transformY > 0) and (transformY < zBuffer[sprdrawstartX]) then 
    --        love.graphics.setCanvas(a)
    --        love.graphics.draw(love.graphics.newImage('tex2.png'), sprdrawstartX, sprdrawstartY)
    --        love.graphics.setCanvas()
    --    end
    --end
end

Fm = 'nearest'

function love.draw()
    a:setFilter(Fm)
    love.graphics.setCanvas(a)
        love.graphics.draw(drawBuffer, 4, 4)
    love.graphics.setCanvas()
    
    love.graphics.scale(pixelScale, pixelScale*1.2)
    love.graphics.draw(a)
    
    DrawScreenFrame()

    love.graphics.setColor(EGA[5])
    love.graphics.rectangle('fill', 0, screenHeight+8, gWidth, gHeight)
    love.graphics.setColor(EGA[6])
    love.graphics.rectangle('fill', 4, screenHeight+12, gWidth-8, 24)

    love.graphics.setColor(EGA[16])
    love.graphics.print('Apogee presents \n     a River Mortis production', 8, 200-40+8, 0)

    love.graphics.reset()
    
    if FPS and fend then 
        love.graphics.print('FPS: ' .. math.floor(FPS) .. ' / ' .. math.floor(fend), 1+4*pixelScale, 4*pixelScale*1.2, 0, 1, 1.2)
    end
    love.graphics.print('1 - Linear filter\n2 - Nearest filter\n3 - 30 fps\n4 - 60 fps', 20, 40, 0, 1, 1.2)
    love.graphics.setColor(EGA[1])
    love.graphics.print('1 - Linear filter\n2 - Nearest filter\n3 - 30 fps\n4 - 60 fps', 22, 42, 0, 1, 1.2)
    love.graphics.setColor(1, 1, 1, 1)
    
end



function DrawScreenFrame()
    love.graphics.setColor(EGA[4]) -- dark cyan
    love.graphics.line(1, 0, 1, 200-36)
    love.graphics.line(4, 0, 4, 200-36)

    love.graphics.line(1, 0, gWidth, 0)
    love.graphics.line(1, 3, gWidth, 3)
    
    love.graphics.line(gWidth-1, 0, 320-1, 200-36)
    love.graphics.line(gWidth-4, 0, 320-4, 200-36)
    
    love.graphics.line(1, screenHeight+4, gWidth, screenHeight+4)
    love.graphics.line(1, screenHeight+3+4, gWidth, screenHeight+3+4)
    --
    love.graphics.setColor(EGA[12])
    love.graphics.line(1, screenHeight+5, gWidth, screenHeight+5)
    love.graphics.line(1, screenHeight+2+4, gWidth, screenHeight+2+4)

    love.graphics.line(2, 0, 2, 200-36)
    love.graphics.line(3, 0, 3, 200-36)
    
    love.graphics.line(1, 1, gWidth, 1)
    love.graphics.line(1, 2, gWidth, 2)
    
    love.graphics.line(gWidth-2, 0, gWidth-2, 200-36)
    love.graphics.line(gWidth-3, 0, gWidth-3, 200-36)
    --
end
