TILESIZE = 32 --this is good
--TILESIZE =40


SHADOWTILE = "shadow"
ShadowTile = Object:new{t=SHADOWTILE}

--TILES
GRASS=0
DARKGRASS=1
DIRT=2
STONE=3
CLIFF=4
WATER = 5

watercolor = {63,143,255,64}

areas = {
    --example a valley, lake, mountain, city, or hill
    --[p=centerpoint,r=radius,z=centreZ]
}


UNITCHANCE = {
    [GRASS]=1/30,
    [DARKGRASS]=1/60,
    [DIRT]=1/20,
    [STONE]=1/80,
    [CLIFF]=0,
    [WATER]=0
}

TREECHANCE = {
    [GRASS]=0.2,
    [DARKGRASS]=0.6,
    [DIRT]=0.02,
    [STONE]=0,
    [CLIFF]=0,
    [WATER]=0
}

--vertical variance
VARIANCE = {
    [GRASS]={-14,2},
    [DARKGRASS]={-6,16},
    [DIRT]={-8,2},
    [STONE]={14,20},
    [CLIFF]={10,30},
    [WATER]={-11,-9}
}
--sum of chances should be 100
TILECHANCE = {
    [GRASS]={
        [GRASS]=50,
        [DARKGRASS]=30,
        [DIRT]=17,
        [STONE]=3,
        [CLIFF]=0,
        [WATER]=0--15
    },
    [DARKGRASS]={
        [GRASS]=40,
        [DARKGRASS]=35,
        [DIRT]=0,
        [STONE]=23,
        [CLIFF]=2,
        [WATER]=0--3
    },
    [DIRT]={
        [GRASS]=15,
        [DARKGRASS]=0,
        [DIRT]=85,
        [STONE]=0,
        [CLIFF]=0,
        [WATER]=0
    },
    [STONE]={
        [GRASS]=5,
        [DARKGRASS]=20,
        [DIRT]=0,
        [STONE]=65,
        [CLIFF]=10,
        [WATER]=0
    },
    [CLIFF]={
        [GRASS]=0,
        [DARKGRASS]=0,
        [DIRT]=0,
        [STONE]=50,
        [CLIFF]=50,
        [WATER]=0
    },
    [WATER]={
        [GRASS]=20,
        [DARKGRASS]=0,
        [DIRT]=0,
        [STONE]=0,
        [CLIFF]=0,
        [WATER]=80
    }
}
for k,types in pairs(TILECHANCE) do
    local sum = 0
    for i,v in pairs(types) do
        sum = sum + v
    end
    if sum ~= 100 then
        print(k,i,sum)
    end
end
--local newcol = map(function(x) return x-2*(t.z) end, {196,219,196})
        
TILECOLORS = {
    TOP={
        [GRASS]={120,180,110},
        [DARKGRASS]={50,70,50},
        [DIRT]={80,70,60},--{189,189,156},
        [STONE]={150,150,150},
        [CLIFF]={120,120,120},
        [WATER]={63,143,255}
    }
}
COLORWEIGHT = {
        [GRASS]=0.1,
        [DARKGRASS]=0.4,
        [DIRT]=0.2,
        [STONE]=0.5,
        [CLIFF]=0.7,
        [WATER] = 1
}

--rounds n to offset mod m
function round(n,m,offset)
    offset = offset or 0
    return math.floor(0.5 + (n-offset)/m)*m + offset
end

function tileStencil(t)
    local tsize = P(TILESIZE/2,TILESIZE/2)
    return function()
        Orectangle("fill",Vsub(t.p,tsize), t.z, V(TILESIZE,0,0), V(0,TILESIZE,0))
    end
end

--determine tiles under a unit
function getTiles(p,r)
    local tiles = {}
    local p1,p2 = Vsub(p,P(r,r)),Vadd(p,P(r,r))
    for x = round(p1[1],TILESIZE,TILESIZE/2),round(p2[1],TILESIZE,TILESIZE/2),TILESIZE do
        for y = round(p1[2],TILESIZE,TILESIZE/2),round(p2[2],TILESIZE,TILESIZE/2),TILESIZE do
            -- add "if in circle" for tile centred at x,y with width TILESIZE
            if Vdist(P(x,y),p) < r+TILESIZE*sqrt2/2 then
                table.insert(tiles,{p=P(x,y),z=getZ(P(x,y)),t=getT(P(x,y))})
            end
        end
    end
    return tiles
end

function drawTile(t)
    --love.graphics.setColor(0,0,0,128)
    local tsize = P(TILESIZE/2,TILESIZE/2)
    Orectangle("fill",Vsub(t.p,tsize), t.z, V(TILESIZE,0,0), V(0,TILESIZE,0))
end


function drawTiles(tiles)
    --love.graphics.setColor(0,0,0,128)
    local tsize = P(TILESIZE/2,TILESIZE/2)
    for i,t in ipairs(tiles) do
        local x,y,z = t.p[1],t.p[2],t.z
        local d = Vdist(camera,t.p)
        local a = 255
        if d > FOG then
            a = math.max(0,a - 200 * (d-FOG)/(VISIBLE-FOG))
        end
        local zx, zy = getZ(P(x+TILESIZE,y)), getZ(P(x,y-TILESIZE))
        local col,col2
        col = getCol(t.p) --TILECOLORS.TOP[t.t]
        col[4] = a
        local linecol = colormult(0.5,col)--TILECOLORS.LINE[t.t]
        linecol[4] = a
--        if t.z >= WATERLEVEL then
        if zx < z then
            --x axis wall
            --if z-zx > WALKABLE then
            --    love.graphics.setColor(150,150,150,a)
            --else
            col2 = colormult(0.7,col)--TILECOLORS.RIGHT[t.t]
            col2[4] = a
            love.graphics.setColor(col2)
            --end
            Orectangle("fill",Vadd(t.p,P(TILESIZE/2,-TILESIZE/2)),zx,V(0,TILESIZE,0),V(0,0,z-zx))
            if OUTLINES then
                love.graphics.setColor(linecol)
                Orectangle("line",Vadd(t.p,P(TILESIZE/2,-TILESIZE/2)),zx,V(0,TILESIZE,0),V(0,0,z-zx))
            end
        end
        if zy < z then
            --y axis wall
            --if z-zy > WALKABLE then
            --    love.graphics.setColor(,a)
            --else
            col2 = colormult(0.8,col)--TILECOLORS.RIGHT[t.t]
            --col = TILECOLORS.LEFT[t.t]
            col2[4] = a
            love.graphics.setColor(col2)
            --end
            Orectangle("fill",Vadd(t.p,P(TILESIZE/2,-TILESIZE/2)),zy,V(-TILESIZE,0,0),V(0,0,z-zy))
            if OUTLINES then
                love.graphics.setColor(linecol)
                Orectangle("line",Vadd(t.p,P(TILESIZE/2,-TILESIZE/2)),zy,V(-TILESIZE,0,0),V(0,0,z-zy))
            end
        end
        love.graphics.setColor(col)
        Orectangle("fill",Vsub(t.p,tsize), t.z, V(TILESIZE,0,0), V(0,TILESIZE,0))
        if OUTLINES then
            love.graphics.setColor(linecol)
            Orectangle("line",Vsub(t.p,tsize), t.z, V(TILESIZE,0,0), V(0,TILESIZE,0))
        end
--        end
        if t.z < WATERLEVEL then
            col2 = table.copy(watercolor)
            --further velow waterlevel: more opaque water
            col2[4] = (100 + math.min(100,WATERLEVEL-t.z))
            col2[4] = col2[4] * a/255
            love.graphics.setColor(col2)
            Orectangle("fill",Vsub(t.p,tsize), WATERLEVEL, V(TILESIZE,0,0), V(0,TILESIZE,0))
        end
        
        --draw objects that are above this tile
        if tilemap[x] and tilemap[x][y] then
            table.sort(tilemap[x][y],
                function(a,b)
                    if a.z == b.z then
                        return a.t == PARTICLE and b.t ~= PARTICLE
                    else
                        return a.z<b.z
                    end
                end)
            for i,o in ipairs(tilemap[x][y]) do
                o:draw(a)
            end
        end
    end
end


function shadowtiles(p,maxz,r)
    local shadows = {}
    local maxs = 5
    local tiles = getTiles(p,r+maxs)
    for i,t in ipairs(tiles) do
        if (t.z < maxz) then
            local s = math.min(maxs,(maxz - t.z)/10)
            table.insert(shadows,ShadowTile:new({p=p,tile=t,r=r+s}))
        end
    end
    return shadows
end
function ShadowTile:draw(a)
    if a then
        a = a/4
    else
        a = 64
    end
    love.graphics.setColor(0,0,0,a)

    local mask = tileStencil(self.tile)
    love.graphics.setStencil(mask)
    Ocircle("fill",self.p,self.tile.z,self.r)
    love.graphics.setStencil()
end

function tiledShadow(p,maxz,r)
    --local z = getZ(self.p)
    love.graphics.setColor(0,0,0,100)
    --Ocircle("fill",self.p,z,self.r)
    
    local tiles = getTiles(p,r)
    local tsize = P(TILESIZE/2,TILESIZE/2)
    for i,t in ipairs(tiles) do
        if (t.z < maxz) then
            local mask = tileStencil(t)
            love.graphics.setStencil(mask)
            
            Ocircle("fill",p,t.z,r)
            love.graphics.setStencil()
        end
    end
    
    --fillTiles(getTiles(self.p,self.r))
end

function getMaxZ(p,r)
    local tiles = getTiles(p,r)
    local z
    for i,t in ipairs(tiles) do
        if not z then
            z = t.z
        else
            z = math.max(z,t.z)
        end
    end
    return z
end

function gridpoint(p)
    return P(round(p[1],TILESIZE,TILESIZE/2),round(p[2],TILESIZE,TILESIZE/2))
end

function getZ(p)
    local g = gridpoint(p)
    if zmap[g[1]] and zmap[g[1]][g[2]] then
        return zmap[g[1]][g[2]]
    elseif Vdist(p,player.p) > RELEVANCE then
        return player.z --don't recreate irrelevant tiles
    else
        return newTile(g[1],g[2])
    end
    return player.z
end

function getT(p)
    local g = gridpoint(p)
    if tmap[g[1]] and tmap[g[1]][g[2]] then
        return tmap[g[1]][g[2]]
    else
        return 0
    end
end

function getCol(p)
    local g = gridpoint(p)
    if colmap[g[1]] and colmap[g[1]][g[2]] then
        return colmap[g[1]][g[2]]
    else
        return TILECOLORS.TOP[getT(p)]
    end
end

function newTile(gx,gy) --return the z of the new tile
    explored = explored + 1
    local newz
    --surroundings
    local count = 0
    local sum = 0
    local r,g,b = 0,0,0
    types = {
        [GRASS]=0,
        [DARKGRASS]=0,
        [DIRT]=0,
        [STONE]=0,
        [CLIFF]=0,
        [WATER]=0
    }
    for dx=-2*TILESIZE,2*TILESIZE,TILESIZE do
        if zmap[gx+dx] then
            for dy = -2*TILESIZE,2*TILESIZE,TILESIZE do
                if zmap[gx+dx][gy+dy] then
                    sum = sum+zmap[gx+dx][gy+dy]
                    local othert = tmap[gx+dx][gy+dy]
                    for type2,value in pairs(TILECHANCE[othert]) do
                        types[type2] = types[type2] + value
                    end
                    local col = TILECOLORS.TOP[othert]
                    r,g,b = r+col[1],g+col[2],b+col[3]
                    count = count + 1
                end
            end
        end
    end
    if count == 0 then
        return player.z
    end
    r,g,b = r/count,g/count,b/count
    local newt = false
    local rnum = math.random(0,99)
    for type2,value in pairs(types) do
        local c = value / count
        if rnum < c and not newt then 
            newt = type2
        else
            rnum = rnum - c
        end
    end
    newz = sum/count
    --[[if newz > WATERLEVEL + 50 then
        newz = newz - math.random(8,16)
    elseif newz > WATERLEVEL + 40 then
        newz = newz - math.random(3,6)
    elseif newz < WATERLEVEL - 20 then
        newz = newz + math.random(3,6)
    end]]
    
    --if in area
    local gp = P(gx,gy)
    for i,a in ipairs(areas) do
        local dist = Vdist(a.p,gp)
        if dist < a.r then
            newz = newz + (a.z - newz)*(a.r-dist)/a.r
        end
    end
    
    newz = newz + math.random(VARIANCE[newt][1],VARIANCE[newt][2])
    --this makes the world flat
    --newz = WATERLEVEL + 0.8 * (newz - WATERLEVEL)
     
    --chance to make an "area" that is higher or lower
    if math.random() < 1/200 then
        local r = math.random(4*TILESIZE,7*TILESIZE) --area size
        local z
        if newz < WATERLEVEL - 20 then
            --island or end of lake
            z = WATERLEVEL + math.random(5,25)
        elseif WATERLEVEL+10 < newz and newz < WATERLEVEL + 40 then
            --small lake
            z = newz + math.random(-60,-40) --valley depth
        elseif WATERLEVEL + 40 < newz and newz < WATERLEVEL + 60 then
            --end of mountain (valley)
            z = newz + WATERLEVEL + math.random(-30,-10) --valley depth
        elseif WATERLEVEL + 60 < newz and newz < WATERLEVEL + 100 then
            --end of mountain (valley)
            z = newz + math.random(-90,-50) --valley depth
        elseif WATERLEVEL + 100 < newz then
            --cliff
            r = math.random(6*TILESIZE,10*TILESIZE)
            z = newz + math.random(-140,-80) --valley depth
        else
            --others are small
            z = newz + math.random(-30,30) --valley depth
            r = math.random(2*TILESIZE,5*TILESIZE)
        end
        local p = Vsub(P(gx,gy),player.p)
        p = Vadd(player.p,Vscale(p,Vmagn(p)+r))
        table.insert(areas,{p=p,z=z,r=r,h=newz-z})
    end
    
    if not zmap[gx] then
        zmap[gx] = {}
        tmap[gx] = {}
        colmap[gx] = {}
    end
    zmap[gx][gy] = newz
    tmap[gx][gy] = newt
    local w = COLORWEIGHT[newt] --color weight. 0 is average of surroundings, 1 is own type
    local col = TILECOLORS.TOP[newt]
    colmap[gx][gy] = {r*(1-w) + col[1]*w,g*(1-w) + col[2]*w,b*(1-w) + col[3]*w}
    
    if newz > WATERLEVEL then
        if math.random() < UNITCHANCE[newt] then
            table.insert(others, Other(P(gx,gy), newz))
        elseif math.random() < TREECHANCE[newt] then
            local p = randompoint(P(gx,gy),TILESIZE/2)
            local h = math.random(40,50)
            local r = h*(0.2+math.random()/7)
            table.insert(trees, Tree:new{p=p, z=newz+5, r=r, h=h})
        end
    end
    return newz
end

function colormult(s,col)
    new = {}
    for i=1,3 do
        new[i] = s * col[i] 
    end
    new[4] = col[4]
    return new
end

function coloradd(col1,col2)
    new = {}
    for i=1,#col1 do
        new[i] = col1[i] + col2[i] 
    end
    return new
end

function randompoint(p,r)
    local angle = math.random()*6.28
    local d = math.random()*r
    return P(p[1] + math.cos(angle)*d,p[2]+math.sin(angle)*d)
end