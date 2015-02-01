local QRange = 625
local ERange= 1300
local QReady, WReady, EReady, RReady = false, false, false, false

function OnLoad()
    if myHero.charName ~= "Gangplank" then 
    	return 
    end  
    enemyMinions = minionManager(MINION_ENEMY, 600, myHero, MINION_SORT_HEALTH_ASC)
    Gangplank = scriptConfig("Gangplank", "Gangplank") 
     
    Gangplank:addSubMenu("Settings", "settings")
    Gangplank.settings:addSubMenu("ComboSettings", "ComboSettings")
    Gangplank.settings.ComboSettings:addParam("Q", "Use Q", SCRIPT_PARAM_ONOFF, true)
    Gangplank.settings.ComboSettings:addParam("E", "Use E", SCRIPT_PARAM_ONOFF, true)
    Gangplank.settings.ComboSettings:addParam("R", "Use R", SCRIPT_PARAM_ONOFF, true)
    Gangplank.settings.ComboSettings:addParam("RNumEnemies", "R if # additional enemies in range", SCRIPT_PARAM_SLICE, 2, 1, 4, 0)
          

    Gangplank.settings:addSubMenu("AutoCast", "AutoCast")
    Gangplank.settings.AutoCast:addParam("W", "Use W", SCRIPT_PARAM_ONOFF, true)
    Gangplank.settings.AutoCast:addParam("Whp", "W if hp % <", SCRIPT_PARAM_SLICE,  20, 0, 90,0)
    Gangplank.settings.AutoCast:addParam("Es", "Use E", SCRIPT_PARAM_ONOFF, true)
    Gangplank.settings.AutoCast:addParam("ENumAllies", "E if allies >=",  SCRIPT_PARAM_SLICE, 2, 1, 4,0)

    Gangplank.settings:addSubMenu("HarassSettings", "HarassSettings")
    Gangplank.settings.HarassSettings:addParam("Qh", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Gangplank.settings.HarassSettings:addParam("ManaSliderHarass", "Use mana % >=",  SCRIPT_PARAM_SLICE, 30, 0, 100,0)

    Gangplank.settings:addSubMenu("KS", "KS")
    Gangplank.settings.KS:addParam("Qs", "KS with Q", SCRIPT_PARAM_ONOFF, true)
    Gangplank.settings.KS:addParam("Rs", "KS with R", SCRIPT_PARAM_ONOFF, true)
    Gangplank.settings.KS:addParam("Rcheck", "R KS Check Distance (>=)",  SCRIPT_PARAM_SLICE, 1500, 50, 3000,0)

    Gangplank.settings:addSubMenu("Draw", "Draw")
	Gangplank.settings.Draw:addParam("Qd", "Draw Q Range", SCRIPT_PARAM_ONOFF,true)
    Gangplank.settings.Draw:addParam("Ed", "Draw E Range", SCRIPT_PARAM_ONOFF,true)

    Gangplank.settings:addSubMenu("KeyBindings", "KeyBindings")
    Gangplank.settings.KeyBindings:addParam("Combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
    Gangplank.settings.KeyBindings:addParam("Harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, 67)
    Gangplank.settings.KeyBindings:addParam("Farm", "Farm", SCRIPT_PARAM_ONKEYDOWN, false, 68)

    TS = TargetSelector(TARGET_LESS_CAST, 625, DAMAGE_PHYSICAL) 
	TS.name = "Gangplank"
	Gangplank:addTS(TS)
  	PrintChat("Executioner Gangplank 1.0 by Transparent loaded")   
 	
end

function OnTick()
	if not myHero.dead then
		enemyMinions:update() 
		SpellCheck()
		TS:update()
	    AutoHeal()
	    AutoE()
	    KS()

	    if Gangplank.settings.KeyBindings.Combo then
	    	Combo()
	    end

	    if Gangplank.settings.KeyBindings.Harass then
	    	Harass()
	    end

	    if Gangplank.settings.KeyBindings.Farm then
	    	farmQ()
	    end
	end
end 

function farmQ()
	if QReady then
	for index, minion in pairs(enemyMinions.objects) do
        if getDmg("Q",minion,myHero)+myHero.damage+myHero.addDamage > minion.health then 
        	CastQ(minion)
        	break
        end
    end
end
end


function SpellCheck()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
end

function KS()
	AutoUltimate()
	AutoQ()
end

function Combo()
	Target = TS.target
	UltEnemyCount()
	if Target and Target.valid and Target.visible and Target.team ~= myHero.team and not Target.dead then  
	    if QReady and Gangplank.settings.ComboSettings.Q and myHero:GetDistance(Target) < QRange then 
	        CastQ(Target)
	    end

	    if EReady and Gangplank.settings.ComboSettings.E then 
	        CastE()
	    end 
	end
end

function Harass()
	Target = TS.target
	if Target and Target.valid and Target.visible and Target.team ~= myHero.team and not Target.dead and QReady then
		CastQ(Target)
	end
end 



function AutoHeal()
	if WReady and Gangplank.settings.AutoCast.W then
        if (myHero.health / myHero.maxHealth)*100 <= Gangplank.settings.AutoCast.Whp then
        	CastW()
        end
    end
end

function AutoE()
	if EReady and Gangplank.settings.AutoCast.Es then
        if CountAlliesInRange() >= Gangplank.settings.AutoCast.ENumAllies then
        	CastE()
        end
    end
end

function CountAlliesInRange()
    local allies = 0
    for i, unit in ipairs(GetAllyHeroes()) do
        if unit.team == myHero.team and GetDistanceSqr(myHero, unit) <= 1300*1300 then
            allies = allies + 1
        end

    end
    
    return allies
end

function AutoUltimate()
	if RReady and Gangplank.settings.KS.Rs then
		for i, unit in ipairs(GetEnemyHeroes()) do
			if ValidTarget(unit) then
		        if (getDmg("R",unit,myHero)*3)> unit.health and GetDistanceSqr(myHero, unit) >= Gangplank.settings.KS.Rcheck then
		            CastR(unit)
		        end
		    end
		end
	end
end

function UltEnemyCount()
	if RReady and Gangplank.settings.ComboSettings.R then
       for i, unit in ipairs(GetEnemyHeroes()) do
			if ValidTarget(unit) then
			    local count = CountEnemyHeroInRange(600, unit)
			    if count > Gangplank.settings.ComboSettings.RNumEnemies then
			    	CastR(unit)
			    end
			end
		end
	end
end
  
function AutoQ()
	if QReady and Gangplank.settings.KS.Qs then
		for i, unit in ipairs(GetEnemyHeroes()) do
			if ValidTarget(unit) then
		        if (getDmg("Q",unit,myHero) > unit.health) and GetDistanceSqr(myHero, unit) >= 625*625 then
		            CastQ(unit)
		        end
		    end
		end
	end
end

function CastQ(unit)
    CastSpell(_Q,unit)
end  

function CastE()
    Packet("S_CAST", {spellId = _E, fromX = myHero.x, fromY = myHero.z, toX = myHero.x, toY = myHero.z}):send()
end  


function CastW()
     Packet("S_CAST", {spellId = _W, fromX = myHero.x, fromY = myHero.z, toX = myHero.x, toY = myHero.z}):send()
end  

function CastR(unit)
	Packet("S_CAST", {spellId = _R, fromX = myHero.x, fromY = myHero.z, toX = unit.x, toY = unit.z}):send()
end
    
function OnDraw()
    if not myHero.dead then
        if Gangplank.settings.Draw.Qd and QReady then
        	DrawCircle2(myHero.x, myHero.y, myHero.z, QRange, ARGB(255, 0, 255, 0))
        end 

        if Gangplank.settings.Draw.Ed and EReady then
        	DrawCircle2(myHero.x, myHero.y, myHero.z, ERange, ARGB(255, 0, 255, 0))
        end 

        if Gangplank.settings.Draw.Qd and not QReady then
        	DrawCircle2(myHero.x, myHero.y, myHero.z, QRange, RGB(255,0,0))
        end 

        if Gangplank.settings.Draw.Ed and not EReady then
        	DrawCircle2(myHero.x, myHero.y, myHero.z, ERange, RGB(255,0,0))
        end 
    end
end

function DrawCircle2(x, y, z, radius, color)
	local vPos1 = Vector(x, y, z)
	local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
	local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
	local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))

	if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y })  then
		DrawCircleNextLvl(x, y, z, radius, 1, color, 75)	
	end
end

function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
	radius = radius or 300
	quality = math.max(8,math.floor(180/math.deg((math.asin((chordlength/(2*radius)))))))
	quality = 2 * math.pi / quality
	radius = radius*.92
	local points = {}
	for theta = 0, 2 * math.pi + quality, quality do
		local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
		points[#points + 1] = D3DXVECTOR2(c.x, c.y)
	end
	DrawLines2(points, width or 1, color or 4294967295)
end