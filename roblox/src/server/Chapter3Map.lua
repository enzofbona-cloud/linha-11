local TweenService=game:GetService("TweenService")
local M={}
local X=300
local world,spawn
local prompts,lights,sockets={},{},{}
local doorA,doorB,closedA,closedB
local techDoor,techDoorClosed
local function v(x,y,z) return Vector3.new(X+x,y,z) end
local function part(parent,name,size,at,color,material,trans,collide,shape)
	local p=Instance.new("Part"); p.Name=name; p.Size=size; p.Position=at; p.Anchored=true
	p.CanCollide=collide~=false; p.CanTouch=false; p.CanQuery=true; p.CastShadow=true
	p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
	p.Color=color or Color3.fromRGB(76,73,68); p.Material=material or Enum.Material.Concrete
	p.Transparency=trans or 0; if shape then p.Shape=shape end; p.Parent=parent; return p
end
local function act(parent,name,x,y,z,id,label,object,hold)
	local p=part(parent,name,Vector3.new(.8,.8,.8),v(x,y,z),Color3.new(),Enum.Material.SmoothPlastic,1,false); p.CanQuery=false
	local q=Instance.new("ProximityPrompt"); q.Name="Interagir"; q.ActionText=label; q.ObjectText=object
	q.KeyboardKeyCode=Enum.KeyCode.E; q.GamepadKeyCode=Enum.KeyCode.ButtonX; q.HoldDuration=hold or .45
	q.MaxActivationDistance=8; q.RequiresLineOfSight=false; q:SetAttribute("ActionId",id); q.Parent=p
	table.insert(prompts,q); return p
end
local function wall(parent,name,x,z,sx,sz)
	return part(parent,name,Vector3.new(sx,11.7,sz),v(x,5.85,z),Color3.fromRGB(98,92,81),Enum.Material.Plaster)
end
local function sign(parent,name,x,y,z,text,size)
	local p=part(parent,name,size,v(x,y,z),Color3.fromRGB(38,39,37),Enum.Material.Metal,0,false)
	local gui=Instance.new("SurfaceGui"); gui.Face=Enum.NormalId.Front; gui.PixelsPerStud=40; gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.Parent=p
	local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.Text=text
	t.TextColor3=Color3.fromRGB(210,195,166); t.Font=Enum.Font.Garamond; t.TextScaled=true; t.Parent=gui
end
local function doc(parent,name,x,y,z,title,body,id)
	local p=part(parent,name,Vector3.new(2.6,.08,1.75),v(x,y,z),Color3.fromRGB(185,174,150),Enum.Material.Fabric,0,false)
	local gui=Instance.new("SurfaceGui"); gui.Face=Enum.NormalId.Top; gui.PixelsPerStud=50; gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.Parent=p
	local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.Text=title.."\n"..body
	t.TextColor3=Color3.fromRGB(47,42,35); t.Font=Enum.Font.Code; t.TextScaled=true; t.TextWrapped=true; t.Parent=gui
	act(parent,name.."_Ler",x,y+.8,z,id,"Ler",title,.4)
end
local function lamp(parent,name,x,z)
	part(parent,name.."_Base",Vector3.new(4,.18,.7),v(x,10.9,z),Color3.fromRGB(62,67,67),Enum.Material.Metal,0,false)
	local b=part(parent,name.."_Luz",Vector3.new(3.6,.08,.45),v(x,10.75,z),Color3.fromRGB(34,34,32),Enum.Material.Glass,.05,false)
	local l=Instance.new("PointLight"); l.Color=Color3.fromRGB(230,170,100); l.Brightness=0; l.Range=18; l.Shadows=false; l.Parent=b
	table.insert(lights,{b=b,l=l})
end
local function build()
	local old=workspace:FindFirstChild("Linha11Chapter3World"); if old then old:Destroy() end
	table.clear(prompts); table.clear(lights); table.clear(sockets)
	world=Instance.new("Folder"); world.Name="Linha11Chapter3World"; world.Parent=workspace
	part(world,"Piso_Corredor",Vector3.new(108,.55,14),v(54,-.35,0),Color3.fromRGB(55,52,47),Enum.Material.Concrete)
	part(world,"Teto_Corredor",Vector3.new(108,.5,14),v(54,11.6,0),Color3.fromRGB(31,32,31),Enum.Material.Concrete)
	-- Corredor com aberturas para escada, elevador e sala eletrica.
	wall(world,"Parede_Norte_A",2.5,-6.8,5,.55); wall(world,"Parede_Norte_B",44,-6.8,48,.55); wall(world,"Parede_Norte_C",99,-6.8,18,.55)
	wall(world,"Parede_Sul_A",19,6.8,38,.55); wall(world,"Parede_Sul_B",79,6.8,58,.55)
	techDoor=part(world,"Porta_Sala_Tecnica",Vector3.new(20,9.4,.35),v(79,4.7,-6.8),Color3.fromRGB(62,68,68),Enum.Material.Metal)
	techDoorClosed=techDoor.CFrame
	for _,x in ipairs({8,31,55,82,101}) do lamp(world,"Luminaria_"..x,x,0) end
	-- Escadaria B e corrimaos.
	part(world,"Piso_Escadaria",Vector3.new(24,.4,20),v(12,-.04,-17),Color3.fromRGB(55,52,47),Enum.Material.Concrete)
	wall(world,"Parede_Escada_Leste",24,-17,.45,20); wall(world,"Parede_Escada_Fundo",12,-27,24,.45)
	for i=1,9 do part(world,"Degrau_"..i,Vector3.new(1.7,.45,9),v(3.4+i*1.65,.2+i*.43,-18.3),Color3.fromRGB(75,73,68),Enum.Material.Concrete) end
	for _,z in ipairs({-22.4,-14.2}) do part(world,"Corrimao",Vector3.new(17.5,.16,.16),v(12,3.3,z),Color3.fromRGB(62,68,68),Enum.Material.Metal,0,false) end
	sign(world,"Placa_Escadaria",12,8,-7.65,"ESCADARIA B / ANDAR 3",Vector3.new(5,1,.15))
	-- Elevador lateral com portas deslizantes e poco escuro.
	part(world,"Piso_Elevador",Vector3.new(22,.45,19),v(44,-.05,17),Color3.fromRGB(55,52,47),Enum.Material.Concrete)
	part(world,"Teto_Elevador",Vector3.new(22,.5,19),v(44,11.3,17),Color3.fromRGB(31,32,31),Enum.Material.Concrete)
	wall(world,"Fundo_Elevador",44,26.4,22,.45); wall(world,"Lado_Elevador_A",33,17,.45,19); wall(world,"Lado_Elevador_B",55,17,.45,19)
	part(world,"Poco_Elevador",Vector3.new(10,9,.3),v(44,5,25.9),Color3.fromRGB(8,9,9),Enum.Material.Slate,0,false)
	for x=39,49,2 do part(world,"Cabo_Poco",Vector3.new(.12,10,.12),v(x,5,25.55),Color3.fromRGB(62,68,68),Enum.Material.Metal,0,false) end
	doorA=part(world,"Porta_Elevador_A",Vector3.new(3,7,.28),v(42.5,3.5,6.6),Color3.fromRGB(76,78,75),Enum.Material.Metal)
	doorB=part(world,"Porta_Elevador_B",Vector3.new(3,7,.28),v(45.5,3.5,6.6),Color3.fromRGB(76,78,75),Enum.Material.Metal)
	closedA,closedB=doorA.CFrame,doorB.CFrame
	act(world,"Painel_Elevador",44,2.6,5.3,"C3_ElevatorCall","Abrir","Elevador de servico",.5)
	act(world,"Gravador",44,2.2,17,"C3_Recorder","Examinar","Gravador no piso",.55)
	part(world,"Gravador_Fita",Vector3.new(1.8,.4,1.2),v(44,.42,17),Color3.fromRGB(31,32,31),Enum.Material.Metal,0,false)
	sign(world,"Placa_Elevador",44,8,6.4,"ELEVADOR / SERVICO",Vector3.new(5,.8,.15))
	-- Sala tecnica com dois pontos do circuito separados para a dupla.
	part(world,"Piso_Sala_Tecnica",Vector3.new(31,.45,19),v(78,-.05,-17),Color3.fromRGB(55,52,47),Enum.Material.Concrete)
	part(world,"Teto_Sala_Tecnica",Vector3.new(31,.5,19),v(78,11.3,-17),Color3.fromRGB(31,32,31),Enum.Material.Concrete)
	wall(world,"Fundo_Tecnica",78,-26.4,31,.45); wall(world,"Lado_Tecnica_A",62.5,-17,.45,19); wall(world,"Lado_Tecnica_B",93.5,-17,.45,19)
	part(world,"Painel_Disjuntores",Vector3.new(10,5.8,.3),v(78,5.5,-25.9),Color3.fromRGB(62,68,68),Enum.Material.CorrodedMetal)
	for _,side in ipairs({{"A",72},{"B",85}}) do
		local id,x=side[1],side[2]
		local box=part(world,"Caixa_Retorno_"..id,Vector3.new(3.2,3.7,.65),v(x,4.6,-8.7),Color3.fromRGB(62,68,68),Enum.Material.CorrodedMetal)
		local bulb=part(world,"Indicador_"..id,Vector3.new(.5,.5,.16),v(x,5.3,-8.3),Color3.fromRGB(43,39,34),Enum.Material.Glass,0,false)
		local l=Instance.new("PointLight"); l.Color=Color3.fromRGB(226,160,83); l.Brightness=0; l.Range=8; l.Parent=bulb
		sockets[id]={bulb=bulb,lamp=l}; act(world,"Acionar_"..id,x,3.3,-8.35,"C3_Breaker"..id,"Acionar","Disjuntor "..id,.8)
		part(world,"Chave_Mecanica_"..id,Vector3.new(.35,1,.35),v(x,4.1,-8.25),Color3.fromRGB(34,37,36),Enum.Material.Metal,0,false)
	end
	for _,x in ipairs({70,78,86}) do lamp(world,"Luz_Tecnica_"..x,x,-17) end
	sign(world,"Placa_Retorno",78,9,-7.35,"RETORNO A + B",Vector3.new(6,.9,.14))
	-- Telefone, armario e documentos da investigacao.
	part(world,"Mesa_Telefone",Vector3.new(3.2,.22,1.8),v(8,2.2,2.8),Color3.fromRGB(79,61,45),Enum.Material.WoodPlanks)
	part(world,"Telefone",Vector3.new(1.4,.48,1),v(8,2.55,2.8),Color3.fromRGB(31,32,31),Enum.Material.Metal)
	act(world,"Atender_Telefone",8,3.2,2.8,"C3_Phone","Atender","Telefone de servico",.6)
	act(world,"Registrar",14,2.3,4.5,"C3_Report","Registrar","Caderno de campo",.5)
	part(world,"Armario_Ferramentas",Vector3.new(2.5,5,1.7),v(25,2.5,3.9),Color3.fromRGB(71,77,75),Enum.Material.Metal)
	act(world,"Chave_Tecnica",25,3.3,2.6,"C3_Key","Abrir armario","Armario de manutencao",.75)
	part(world,"Balcao_Livro",Vector3.new(3.4,.3,2.1),v(31,2.1,-2.7),Color3.fromRGB(79,61,45),Enum.Material.WoodPlanks)
	doc(world,"Livro_Elevador",31,2.48,-2.7,"LIVRO DO ELEVADOR","ORDEM 11-B","C3_Log")
	doc(world,"Aviso_Rota",17,2.55,-2.5,"AVISO DE MANUTENCAO","RETORNO A + B","C3_Route")
	local s=Instance.new("SpawnLocation"); s.Name="InicioCapitulo03"; s.Size=Vector3.new(4,.6,4); s.Position=v(4,.1,0)
	s.Anchored=true; s.Transparency=1; s.CanCollide=false; s.Neutral=true; s.Duration=0; s.Parent=world; spawn=s
	M.SetPower(false); M.SetElevatorOpen(false); M.SetTechDoorOpen(false); return world,spawn
end
function M.Build() return build() end
function M.GetPrompts() return prompts end
function M.SetPower(on)
	for _,r in ipairs(lights) do
		r.l.Brightness=on and 1.15 or 0
		r.b.Material=on and Enum.Material.Neon or Enum.Material.Glass
		r.b.Color=on and Color3.fromRGB(226,160,83) or Color3.fromRGB(35,34,31)
	end
	if world then world:SetAttribute("PowerOn",on) end
end
function M.SetBreaker(id,on)
	local r=sockets[id]; if not r then return false end
	r.bulb.Material=on and Enum.Material.Neon or Enum.Material.Glass; r.bulb.Color=on and Color3.fromRGB(195,112,65) or Color3.fromRGB(43,39,34); r.lamp.Brightness=on and .55 or 0; return true
end
function M.SetElevatorOpen(on)
	if not doorA or not doorB then return false end
	doorA.CanCollide=not on; doorB.CanCollide=not on
	TweenService:Create(doorA,TweenInfo.new(.55,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=closedA*CFrame.new(on and -1.65 or 0,0,0)}):Play()
	TweenService:Create(doorB,TweenInfo.new(.55,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=closedB*CFrame.new(on and 1.65 or 0,0,0)}):Play()
	return true
end
function M.SetTechDoorOpen(on)
	if not techDoor then return false end
	techDoor.CanCollide=not on
	TweenService:Create(techDoor,TweenInfo.new(.65,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=techDoorClosed*CFrame.new(0,on and 9.8 or 0,0)}):Play()
	return true
end
return M
