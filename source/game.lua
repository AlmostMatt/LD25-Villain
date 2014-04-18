require("ortho")
require("particles")
require("object")
 require("map")

Game = State:new()
Canvas = Layer:new()
Game:addlayer(Canvas)

SMALL = 0
MEDIUM = 1
LARGE = 2

SIZES = {
    [SMALL] = {
        w=800,
        h=600,
        visible=260,
        fog = 200,
        relevance = 400,
        size=SMALL
        },
    [MEDIUM]={
        w = 900,
        h = 700,
        visible = 325, --how far you can see
        fog = 250, --how far you can see before it fades
        relevance = 500, --forget anything past this distance
        size=MEDIUM
        },
    [LARGE]={
        w = 1024,
        h = 768,
        visible = 390, --how far you can see
        fog = 300, --how far you can see before it fades
        relevance = 600, --forget anything past this distance
        size=LARGE
    }
}

SIZE = nil
function setSize(size)
    local s = SIZES[size]
    SIZE = s.size
    if s.w ~= width or s.h ~= height then
        love.graphics.setMode(s.w,s.h)
        width = s.w
        height = s.h
        gameUI()
    end
    VISIBLE = s.visible
    FOG = s.fog
    RELEVANCE = s.relevance
end

function gameUI()
    local ui = BoxRel(width,height)
    local b = BoxV(150,height-40,false)
    b.alignV = ALIGNV.BOTTOM
    ui:add(b,REL.E)
    
    local b2
    b2 = BoxV(120,30)
    b2.label = "Toggle Lines"
    b2.onclick = function() OUTLINES = not OUTLINES end
    b:add(b2)
    if SIZE ~= SMALL then
        b2 = BoxV(120,30)
        b2.label = "Small"
        b2.onclick = function() setSize(SMALL) end
        b:add(b2)
    end
    if SIZE ~= MEDIUM then
        b2 = BoxV(120,30)
        b2.label = "Medium"
        b2.onclick = function() setSize(MEDIUM) end
        b:add(b2)
    end
    if SIZE ~= LARGE then
        b2 = BoxV(120,30)
        b2.label = "Large"
        b2.onclick = function() setSize(LARGE) end
        b:add(b2)
    end
    
    if UI then
        UI.ui = ui
    else
        UI = UILayer(ui)
        Game:addlayer(UI)
    end
end

function Game:load()
    killed = 0
    explored = 0
    burnt = 0
    WATERLEVEL = 4 --   -20
    OUTLINES = true
    
    --KEYS = {JUMP="z",DASH="x",LEFT="left",RIGHT="right",UP="up",DOWN="down",ATTACK="c"}
    KEYS = {JUMP=" ",DASH="x",LEFT="a",RIGHT="d",UP="w",DOWN="s",ATTACK="c"}
    DIRS = {UP=P(-sqrt2/2,sqrt2/2), LEFT=P(-sqrt2/2,-sqrt2/2), RIGHT=P(sqrt2/2,sqrt2/2), DOWN=P(sqrt2/2,-sqrt2/2)}

    --check if the player knows his controls
    moved = {}
    for k,v in pairs(DIRS) do
        moved[k] = false
    end
    jumped = false
    clicked = false

    MAXSPEED = 180 --speed after which unable to accelerate by running. could be ignored and use the breakeven point of friction instead
    ACCEL = 1100
    PULL = 800
    PULLR = 50
    MAXPULL = 260
    --FRICTION = 220
    FRICTION = 400
    GRAVITY = 500
    JUMP = 250
    
    setSize(SMALL)
    gameUI()
    
    WANDERDISTANCE = 200
    WANDERSPEED = 40
    OTHERSPEED = 150
    OTHERJUMP = 180
    
    player = Player(P(0,0),50)
    others = {}
    trees = {}
    particles = {}
    
    table.insert(others, Other(P(120,50), 40))
    table.insert(others, Other(P(50,150), 20))
    table.insert(others, Other(P(-120,-50), 20))
    
    walls = {}

    zmap = {}
    tmap = {}
    colmap = {}
    tilemap = {}
    areas = {}
    
    unit = TILESIZE
    --local w,h = 20*unit,20*unit
    --addwall(Prism:new({p=P(-w,-h),z=0,v1=V(2*w,0,0),v2=V(0,2*h,0),h=10}))
    local w,h = 5*unit,5*unit
    local g = gridpoint(player.p)
    zmap[g[1]]={[g[2]]=20}
    tmap[g[1]]={[g[2]]=GRASS}
    colmap[g[1]]={[g[2]]=TILECOLORS.TOP[GRASS]}
    --addwall(Prism:new({p=P(-w,-h),z=10,v1=V(2*w,0,0),v2=V(0,2*h,0),h=10}))
    --addwall(Prism:new({p=P(3*unit,unit),z=20,v1=V(2*unit,0,0),v2=V(0,3*unit,0),h=20}))
    --addwall(Prism:new({p=P(-3*unit,-2*unit),z=20,v1=V(4*unit,0,0),v2=V(0,4*unit,0),h=10}))
    --addwall(Prism:new({p=P(unit,-2*unit),z=20,v1=V(2*unit,0,0),v2=V(0,3*unit,0),h=20}))
    
    placing = false
    sizing = false
    placingat = nil
    sizingat = nil
    newwall = nil
    
    frame = 0
    
    Game:update(1/30) --force an update before any draw function is possible.
end

function addwall(w)
    local a,b = w.p,Vadd(Vadd(w.p,w.v1),w.v2)
    local x1,y1 = math.min(a[1],b[1]),math.min(a[2],b[2])
    local x2,y2 = math.max(a[1],b[1]),math.max(a[2],b[2])
    for x = x1+TILESIZE/2,x2,TILESIZE do
        if not zmap[x] then
            zmap[x] = {}
            tmap[x] = {}
            colmap[x] = {}
        end
        for y = y1+TILESIZE/2,y2,TILESIZE do
            local r = math.random(-4,4)
            if math.abs(r) < 2 then r = 0 end
            zmap[x][y] = w.z+w.h+r
            tmap[x][y] = GRASS
            colmap[x][y] = TILECOLORS.TOP[GRASS]
        end
    end
    table.insert(walls,w)
    sorted = false
end

function Canvas:draw()
    local drawable = {}-- walls--
    drawable = join(join(drawable,{player}),others)
    drawable = join(drawable,particles)
    drawable = join(drawable,trees)
    
    --verticalsort(drawable)
    tilemap = {}
    for i,o in ipairs(join(others,{player})) do
        drawable = join(drawable,(shadowtiles(o.p,o.z,o.r)))
    end
    for i,o in ipairs(drawable) do
        local p1,p2 = bounds(o)
        local g = gridpoint(P(p2[1],p1[2])) --max x, min y
        local x,y = g[1],g[2]
        if not tilemap[x] then
            tilemap[x] = {[y]={o}}
        elseif not tilemap[x][y] then
            tilemap[x][y] = {o}
        else
            table.insert(tilemap[x][y],o)
        end
    --    o:draw()
    end
    
    drawmap()
    
    --outline player
    --love.graphics.setColor(player.line)
    --Ocylinder("line",player.p,player.z,player.r,player.h)    

end

function Game:update(dt)
    --[[
    if player.z  > WATERLEVEL + 60 then
        WATERLEVEL = WATERLEVEL + 8 * dt
    elseif player.z + player.h + 20  > WATERLEVEL then
        WATERLEVEL = WATERLEVEL + 2 * dt
    end
    ]]
    if player.z+player.h/2 < WATERLEVEL then
        player.vz = CLIMBSPEED
    end
    for i,o in ipairs(others) do
        if o.z + o.h/2 < WATERLEVEL then
            o.vz = CLIMBSPEED
        end
    end
    
	dt = math.min(dt,1/30)
    frame = frame + 1
    mx,my = love.mouse.getPosition()
    mouse = P(mx,my)
    
    local p = ortho(player.p,player.z)
    --love.graphics.translate(width/2-p[1],height/2-p[2])
    omouse = cartesian(Vadd(Vsub(mouse,P(width/2,height/2)),p),player.z+player.h/2)
    
    
    for i,o in ipairs(others) do
        --[[
        if distance(o.p,omouse) < PULLR*PULLR then
            o.v = Vadd(o.v,Vscale(Vsub(omouse,o.p),PULL*dt))
            if Vdd(o.v) > MAXPULL * MAXPULL then
                o.v = Vscale(o.v,MAXPULL)
            end
        --else
        --    local d = Vmagn(o.v)
        --    o.v = Vscale(o.v,math.max(0,d-FRICTION*dt))
        end]]
        if o.dest then
            local diff = Vsub(o.dest,o.p)
            if Vdd(diff) < 10*10 then
                o.dest = false
            else
                o.v = Vadd(o.v, Vscale(diff,ACCEL*dt))
                if Vdd(o.v) > WANDERSPEED*WANDERSPEED then
                    o.v = Vscale(o.v,WANDERSPEED)
                end
            end
            if o.collided then --maybe stuck on a wall
                o.vz = OTHERJUMP
            end
        else
            o.dest = randompoint(o.p,WANDERDISTANCE)
        end
        --[[
        if o.afraifof something nearby
            if Vdd(o.v) > WANDERSPEED*WANDERSPEED then
                o.v = Vscale(o.v,WANDERSPEED)
            end
        ]]
        o:move(dt)
        
    end
    for i = #trees,1,-1 do
        local o = trees[i]
        if o.burning and o.life > 0 and o.z > WATERLEVEL and frame%4 == 1 then
            burn(o.p,o.z,o.r)
            o.life = o.life - 2
            if o.life <= 0 then
                burnt = burnt + 1
                o.col = {60,40,30}
                o.r = o.r/7
                o.h = o.h*(0.1+0.2*math.random())
            end
        end
        if Vdist(o.p,player.p) > RELEVANCE then
            table.remove(trees,i)
        end
    end
    for i = #others,1,-1 do
        local o = others[i]
        --if dead
        if o.dead then
            killed = killed + 1
            table.remove(others,i)
        elseif o.burning and frame%4 == 1 then
            burn(o.p,o.z+o.h,o.r)
        end
        if Vdist(o.p,player.p) > RELEVANCE then
            table.remove(others,i)
        end
    end
    for i = #areas,1,-1 do
        local o = areas[i]
        if Vdist(o.p,player.p) > RELEVANCE + o.r then
            table.remove(areas,i)
        end
    end
    
    --player.v = P(0,0)
    for k,dir in pairs(DIRS) do
        if love.keyboard.isDown(KEYS[k]) then
            player.v = Vadd(player.v, Vmult(ACCEL*dt,dir))
            moved[k] = true
        --elseif not Vsamedir(player.v,dir) then
        --    player.v = Vadd(player.v, Vmult(FRICTION*dt,dir))
        end
    end
    if Vdd(player.v) > MAXSPEED*MAXSPEED then
        player.v = Vscale(player.v,MAXSPEED)
    end
    --if player.collided and player.onground then --maybe stuck on a wall
    --    player.vz = JUMP
    --end
    player:move(dt)
    
    updateparticles(dt)
    
    --if placing then
    --    resize(newwall)
    --end
    
    
    --clear extra map tiles
    --zmap, tmap, colmap
    --tilemap is already cleared every frame
    --local zmap2,tmap2,colmap2 = {}
    
    for x,column in pairs(zmap) do
        if Vdist(P(x,player.p[2]),player.p) > RELEVANCE then
            zmap[x] = {}
        elseif false then
            for y,value in pairs(zmap[x]) do
                if Vdist(P(x,y),player.p) > RELEVANCE then
                    zmap[x][y] = nil
                    tmap[x][y] = nil
                    colmap[x][y] = nil
                end
            end
        end
    end
    
end


function Game:mousepress(x,y, button)
    if button == "r" or button == "l" then
        local mousez = getZ(omouse)
        --[[
        for i,t in ipairs(getTiles(omouse,PULLR)) do
            local dist = Vdist(t.p,omouse)
            --local tilez = getZ(t.p)
            --dist = Vmagn(P(dist,mousez-tilez))
            --if dist < PULLR then
                zmap[t.p[1] ][t.p[2] ] = zmap[t.p[1] ][t.p[2] ] - 10--(10-5*dist/PULLR) --math.abs(PULLR - dist) -- 10
            --end
        end
        --for i=1,6 do
        --    debris(omouse,mousez)
        --end]]
        for i,o in ipairs(trees) do
            if distance(o.p,omouse) < PULLR*PULLR then
                o.burning = true
                clicked = true
            end
        end
        for i,o in ipairs(others) do
            if distance(o.p,omouse) < PULLR*PULLR then
                --o.burning = true
                clicked = true
                o.dead = true
                for i=1,8 do --15
                    blood(o.p,o.z)
                end
            end
        end
    elseif button == "l" then
        --[[
        if not placing then
            placing = true
            placingat = mousetile
            newwall = Prism:new({h=1})
            resize(newwall)
        elseif sizing then
            addwall(newwall)
            newwall = nil
            placing = false
            sizing = false
        end]]
    end
end

function resize(w)
    if sizing then
        w.h = math.max(
                    10,
                    math.abs(
                        round(
                            (my-sizingat)/zskew,
                            10)))
    else
        local a,b = placingat.p,mousetile.p
        local x1,y1 = math.min(a[1],b[1]),math.min(a[2],b[2])
        local x2,y2 = math.max(a[1],b[1]),math.max(a[2],b[2])
        w.p=P(x1-TILESIZE/2,y1-TILESIZE/2)
        w.z=placingat.z
        w.v1=V(TILESIZE+x2-x1,0,0)
        w.v2=V(0,TILESIZE+y2-y1,0)
        w.h=10
    end
end

function Game:mouserelease(x,y, button)
    if placing then
        sizingat = my
        sizing = true
    end
end

function Game:keypress(key)
    if key == KEYS.JUMP and (player.onground or player.z < WATERLEVEL) then
        player.vz = JUMP
        jumped = true
    end
end

function Game:keyrelease(key)

end

function grid()
    love.graphics.setColor(0,0,0,100)
    love.graphics.setLineWidth(1)
    local w,h = 10,10
    for x=-w*unit,w*unit,unit do
        Oline(P(x,-h*unit),0,P(x,h*unit))
    end
    for y=-h*unit,h*unit,unit do
        Oline(P(-w*unit,y),0,P(w*unit,y))
    end
end

function drawmap()
    camera = player.p
    love.graphics.push()
    local p = ortho(camera,player.z)
    love.graphics.translate(width/2-p[1],height/2-p[2])
    
    --to draw so many small tiles is too slow.
    --compromise draw order bugs.
    
    --x-y = screeny
    --draw in order of increasing z
    --for each tile draw it's elevation and optional front walls and shadow tiles
    local tl = P (10,10)
    local br = P(width-10,height-10)
    local wh = Vsub(br,tl)
    
    local p1 = cartesian(tl,0)
    local p2 = cartesian(br,0)
    --local ts = getTiles(cartesian(Vavg(p1,p2),0),height/2)
    local ts = getTiles(camera,VISIBLE)
    table.sort(ts,function(a,b) return a.p[1]-a.p[2] < b.p[1]-b.p[2] end)
    --local ts = getTiles(P(0,0),height/2)
    drawTiles(ts)
    --fillTiles({{p=p1,z=0},{p=p2,z=2}})
    
    
    
    
    
    
    
    
    
    --target and weapon
    local t = {p = omouse,z = player.z+player.h/2}
    local z = getZ(t.p)
    love.graphics.setColor(128,0,0)
    Oline(player.p,t.z,t.p,z)
    Ocircle("line",t.p,z,4)
    love.graphics.setColor(128,0,0,64)
    --Ocircle("line",t.p,t.z,PULLR)
    Ocircle("line",t.p,z,PULLR)
    
    --burn(t.p,t.z,10)
    
    --orthomouse
    love.graphics.setPointSize(4)
    Opoint(omouse,20)
    
    local p=P(round(omouse[1],TILESIZE,TILESIZE/2),round(omouse[2],TILESIZE,TILESIZE/2))
    mousetile = {p=p,z=getZ(p)}
    --love.graphics.setLineWidth(4)
    drawTile(mousetile)
    --love.graphics.setLineWidth(1)
    
    --drawparticles()
    
    
    
    --[[
    for i,a in ipairs(areas) do
        love.graphics.setColor(0,255,0,128)
        Ocircle("line",a.p,a.z+a.h,a.r)
        love.graphics.setColor(255,0,0,128)
        Ocircle("line",a.p,a.z,a.r)
    end
    ]]
    
    
    
    
    
    love.graphics.pop()
    
    love.graphics.setColor(128,0,0,64)
    love.graphics.rectangle("line",tl[1],tl[2],wh[1],wh[2])

    love.graphics.setColor(0,0,0)
    love.graphics.print("Altitude: " .. math.floor(player.z/5),20,35)
    love.graphics.print("Water level: " .. math.floor(WATERLEVEL/5),20,50)
    love.graphics.print("Cylinders killed: " .. killed,20,95)
    love.graphics.print("Trees burned: " .. burnt,20,65)
    love.graphics.print("Tiles explored: " .. explored,20,80)
    
    local y = 65
    local h = 30
    love.graphics.setLineWidth(1)
    local c = 0
    for k,v in pairs(moved) do
        if v then c = c + 1 end
    end
    if c < 2 then
        notify("W A S D to move",y)
        y = y + h
    end
    if not jumped then
        notify("Space to jump",y)
        y = y + h
    end
    if not clicked then
        notify("Click on stuff",y)
        y = y + h
    end
end

function notify(msg,y)
    local w,h = 200,24
    local x = width - w - 15
    love.graphics.setColor(255,255,255,128)
    love.graphics.rectangle("fill",x,y,w,h)
    love.graphics.setColor(0,0,0,196)
    love.graphics.rectangle("line",x,y,w,h)
    love.graphics.printf(msg,x,y+5,w,"center")
end