local TweenService=game:GetService("TweenService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Story=require(ReplicatedStorage.Shared.LaterChapterStory)
local Map={}
local worlds,spawns,prompts,batteries={},{},{},{}
local function base(id) return 500+(id-4)*126 end
local function pos(id,x,y,z) return Vector3.new(base(id)+x,y,z) end
local function part(parent,id,name,size,at,color,material,trans,collide,shape)
	local p=Instance.new("Part"); p.Name=name; p.Size=size; p.Position=at; p.Anchored=true
	p.CanCollide=collide~=false; p.CanTouch=false; p.CanQuery=true; p.CastShadow=true
	p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
	p.Color=color or Color3.fromRGB(74,70,63); p.Material=material or Enum.Material.Concrete
	p.Transparency=trans or 0; if shape then p.Shape=shape end; p.Parent=parent; return p
end
local function anchor(parent,id,name,x,y,z,actionId,action,object,hold)
	local p=part(parent,id,name,Vector3.new(.8,.8,.8),pos(id,x,y,z),Color3.new(),Enum.Material.SmoothPlastic,1,false); p.CanQuery=false
	local prompt=Instance.new("ProximityPrompt"); prompt.Name="Interagir"; prompt.ActionText=action; prompt.ObjectText=object
	prompt.KeyboardKeyCode=Enum.KeyCode.E; prompt.GamepadKeyCode=Enum.KeyCode.ButtonX
	prompt.HoldDuration=hold or .45; prompt.MaxActivationDistance=8; prompt.RequiresLineOfSight=false
	prompt:SetAttribute("ActionId",actionId); prompt.Parent=p; table.insert(prompts,prompt); return p
end
local function label(parent,id,name,x,y,z,text,size)
	local p=part(parent,id,name,size,pos(id,x,y,z),Color3.fromRGB(37,38,36),Enum.Material.Metal,0,false)
	local gui=Instance.new("SurfaceGui"); gui.Face=Enum.NormalId.Front; gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud=38; gui.Parent=p
	local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.Text=text
	t.TextColor3=Color3.fromRGB(209,194,164); t.Font=Enum.Font.Garamond; t.TextScaled=true; t.Parent=gui
end
local function light(parent,id,x,z)
	part(parent,id,"Luminaria_Base",Vector3.new(3.2,.16,.6),pos(id,x,10.9,z),Color3.fromRGB(56,61,61),Enum.Material.Metal,0,false)
	local bulb=part(parent,id,"Luminaria_Difusor",Vector3.new(2.8,.08,.4),pos(id,x,10.77,z),Color3.fromRGB(167,132,82),Enum.Material.Glass,.12,false)
	local l=Instance.new("PointLight"); l.Color=Color3.fromRGB(213,166,104); l.Brightness=.65; l.Range=15; l.Shadows=false; l.Parent=bulb
end
local function document(parent,id,index,x)
	local data=Story.Get(id).Clues[index]
	local paper=part(parent,id,"Documento_"..index,Vector3.new(2.5,.08,1.65),pos(id,x,2.28,3),Color3.fromRGB(186,174,150),Enum.Material.Fabric,0,false)
	local gui=Instance.new("SurfaceGui"); gui.Face=Enum.NormalId.Top; gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud=46; gui.Parent=paper
	local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.Text=data.title.."\n"..string.sub(data.text,1,68)
	t.TextColor3=Color3.fromRGB(44,40,34); t.Font=Enum.Font.Code; t.TextScaled=true; t.TextWrapped=true; t.Parent=gui
	anchor(parent,id,"Ler_Pista_"..index,x,3.05,3,"C"..id.."_Clue"..index,"Examinar",data.title,.35)
end
local function furniture(parent,id,theme)
	local wood=Color3.fromRGB(75,57,43); local metal=Color3.fromRGB(57,63,63); local fabric=Color3.fromRGB(73,69,62)
	if theme=="street" then
		part(parent,id,"Pavimento_Rua",Vector3.new(106,.22,18),pos(id,54,-.22,0),Color3.fromRGB(44,46,46),Enum.Material.Asphalt)
		part(parent,id,"Calcada_Norte",Vector3.new(106,.24,4),pos(id,54,-.05,-10),Color3.fromRGB(92,88,79),Enum.Material.Concrete)
		part(parent,id,"Calcada_Sul",Vector3.new(106,.24,4),pos(id,54,-.05,10),Color3.fromRGB(92,88,79),Enum.Material.Concrete)
		for x=23,31,2 do part(parent,id,"Faixa_Pedestre",Vector3.new(1.1,.04,7),pos(id,x,.02,0),Color3.fromRGB(174,168,152),Enum.Material.Concrete,0,false) end
		for _,x in ipairs({38,48}) do
			part(parent,id,"Abrigo_Onibus_Pilar",Vector3.new(.25,7,.25),pos(id,x,3.5,8),metal,Enum.Material.Metal)
			part(parent,id,"Abrigo_Onibus_Teto",Vector3.new(12,.3,3),pos(id,43,7,8),Color3.fromRGB(50,54,54),Enum.Material.Metal)
			part(parent,id,"Abrigo_Onibus_Vidro",Vector3.new(11,5,.12),pos(id,43,3.2,9.2),Color3.fromRGB(86,99,102),Enum.Material.Glass,.35,false)
		end
		part(parent,id,"Banco_Ponto",Vector3.new(7,.25,1),pos(id,43,1.8,7.2),wood,Enum.Material.WoodPlanks)
		for _,x in ipairs({4,100}) do part(parent,id,"Poste_Rua",Vector3.new(.25,9,.25),pos(id,x,4.5,-9),metal,Enum.Material.Metal); part(parent,id,"Luminaria_Rua",Vector3.new(2,.18,.7),pos(id,x,9,-9),Color3.fromRGB(51,53,52),Enum.Material.Metal) end
		for _,x in ipairs({28,33,89,94}) do part(parent,id,"Barreira_Evacuacao",Vector3.new(1.4,3,.5),pos(id,x,1.5,-8),Color3.fromRGB(119,42,34),Enum.Material.Metal) end
	elseif theme=="callcenter" then
		for _,x in ipairs({23,43,63,83}) do
			part(parent,id,"Mesa_Despacho",Vector3.new(9, .28,4),pos(id,x,2,1),wood,Enum.Material.WoodPlanks)
			part(parent,id,"Console_Operador",Vector3.new(5,1.1,1.7),pos(id,x,2.7,.2),metal,Enum.Material.Metal)
			for n=1,5 do part(parent,id,"Botao_Ramal",Vector3.new(.35,.16,.35),pos(id,x-2.2+n*.8,3.35,-.3),Color3.fromRGB(118,83,54),Enum.Material.Neon,0,false) end
			part(parent,id,"Cadeira_Operador",Vector3.new(2,2.3,2),pos(id,x,1.15,4.2),fabric,Enum.Material.Fabric)
		end
		part(parent,id,"Quadro_Canais",Vector3.new(18,7,.3),pos(id,53,6,-11.6),metal,Enum.Material.CorrodedMetal)
	elseif theme=="archive" then
		for _,x in ipairs({12,27,42,57,72,87}) do
			part(parent,id,"Estante_Arquivo",Vector3.new(.35,8,6),pos(id,x,4,-8),wood,Enum.Material.WoodPlanks)
			for n=1,5 do part(parent,id,"Prateleira_Arquivo",Vector3.new(3,.18,5.7),pos(id,x+1.7,.8+n*1.35,-8),wood,Enum.Material.Wood) end
			for n=1,3 do part(parent,id,"Caixa_Arquivo",Vector3.new(1.7,1,1.2),pos(id,x+1,1.1+n*1.65,-8),Color3.fromRGB(94,79,58),Enum.Material.WoodPlanks) end
		end
		part(parent,id,"Mesa_Consulta",Vector3.new(10,.25,4),pos(id,52,2,5),wood,Enum.Material.WoodPlanks)
	elseif theme=="tunnel" then
		for _,z in ipairs({-8,8}) do
			part(parent,id,"Duto_Servico",Vector3.new(102,.8,.8),pos(id,54,8,z),metal,Enum.Material.Metal,0,false,Enum.PartType.Cylinder)
			part(parent,id,"Cabo_Power",Vector3.new(102,.24,.24),pos(id,54,6.8,z),Color3.fromRGB(25,25,23),Enum.Material.Rubber,0,false)
		end
		for _,x in ipairs({15,35,55,75,95}) do part(parent,id,"Pilar_Tunel",Vector3.new(.5,10,18),pos(id,x,5,0),Color3.fromRGB(66,65,60),Enum.Material.Concrete) end
		local battery=part(parent,id,"Bateria_Pesada",Vector3.new(4,3,3),pos(id,38,1.5,4),Color3.fromRGB(44,53,52),Enum.Material.Metal)
		batteries[id]={part=battery,from=battery.CFrame,to=CFrame.new(pos(id,75,1.5,0))}
		anchor(parent,id,"Alca_Bateria_A",36,2.5,2,"C7_LiftA","Segurar","Alca A",1)
		anchor(parent,id,"Alca_Bateria_B",40,2.5,6,"C7_LiftB","Segurar","Alca B",1)
		anchor(parent,id,"Receptaculo_Bateria",75,2,0,"C7_BatterySocket","Conectar","Suporte da subestacao",.7)
	elseif theme=="triage" then
		for _,x in ipairs({15,36,57,78}) do
			part(parent,id,"Maca_Triagem",Vector3.new(7,1.1,3),pos(id,x,1.2,-7),Color3.fromRGB(92,93,87),Enum.Material.Metal)
			part(parent,id,"Colchao_Triagem",Vector3.new(6.7,.35,2.8),pos(id,x,1.9,-7),Color3.fromRGB(153,147,130),Enum.Material.Fabric)
			part(parent,id,"Biombo_Triagem",Vector3.new(.15,6,5),pos(id,x+5,3,-8),Color3.fromRGB(125,121,111),Enum.Material.Fabric,.18,false)
			part(parent,id,"Carrinho_Medico",Vector3.new(3,2,.8),pos(id,x,1.2,7),metal,Enum.Material.Metal)
		end
	elseif theme=="apartments" then
		for _,x in ipairs({15,35,55,75,95}) do
			part(parent,id,"Porta_Apartamento",Vector3.new(.28,8,5),pos(id,x,4,-10),wood,Enum.Material.WoodPlanks)
			part(parent,id,"Placa_Apartamento",Vector3.new(2,1,.15),pos(id,x,8,-9.7),metal,Enum.Material.Metal,0,false)
			part(parent,id,"Sofa_Transferencia",Vector3.new(6,2,2.4),pos(id,x+5,1.2,7),fabric,Enum.Material.Fabric)
			part(parent,id,"Mesa_Apartamento",Vector3.new(3,.2,2),pos(id,x+9,1.6,7),wood,Enum.Material.WoodPlanks)
		end
	elseif theme=="relay" then
		for _,x in ipairs({25,48,71}) do
			part(parent,id,"Coluna_Repetidor",Vector3.new(5,9,5),pos(id,x,4.5,-7),metal,Enum.Material.Metal)
			part(parent,id,"Volante_Valvula",Vector3.new(2.8,.22,2.8),pos(id,x,6,0),Color3.fromRGB(119,75,48),Enum.Material.Metal,0,false,Enum.PartType.Cylinder)
			for n=1,4 do part(parent,id,"Raio_Valvula",Vector3.new(.18,2.5,.18),pos(id,x,6,0),Color3.fromRGB(146,100,66),Enum.Material.Metal,0,false) end
			part(parent,id,"Tubo_Pressao",Vector3.new(18,.55,.55),pos(id,x,8,0),metal,Enum.Material.Metal,0,false,Enum.PartType.Cylinder)
		end
	elseif theme=="radio" then
		for _,x in ipairs({20,50,80}) do
			part(parent,id,"Console_Radio",Vector3.new(8,1.1,3),pos(id,x,2.4,4),metal,Enum.Material.Metal)
			part(parent,id,"Gravador_Bobina",Vector3.new(3,1.8,1),pos(id,x,3.8,3),Color3.fromRGB(38,40,39),Enum.Material.Metal)
			for _,dx in ipairs({-1,1}) do part(parent,id,"Bobina",Vector3.new(1.2,.18,1.2),pos(id,x+dx,4.8,2.4),Color3.fromRGB(112,99,78),Enum.Material.Metal,0,false,Enum.PartType.Cylinder) end
		end
		part(parent,id,"Mastro_Antena",Vector3.new(.35,25,.35),pos(id,96,12,0),metal,Enum.Material.Metal)
		for _,y in ipairs({6,13,20}) do part(parent,id,"Braco_Antena",Vector3.new(12,.22,.22),pos(id,96,y,0),metal,Enum.Material.Metal,0,false) end
	elseif theme=="aurora" then
		for _,x in ipairs({18,45,72}) do
			part(parent,id,"Porta_Aurora",Vector3.new(.3,8,6),pos(id,x,4,-10),wood,Enum.Material.WoodPlanks)
			part(parent,id,"Mesa_Telefone",Vector3.new(5,2,3),pos(id,x+8,1,7),wood,Enum.Material.WoodPlanks)
			part(parent,id,"Telefone_Emergencia",Vector3.new(1.4,.6,1),pos(id,x+8,2.3,6),metal,Enum.Material.Metal)
		end
		part(parent,id,"Rack_Repetidor",Vector3.new(7,9,4),pos(id,88,4.5,-7),metal,Enum.Material.CorrodedMetal)
	end
end
local function buildOne(id)
	local info=Story.Get(id); local folder=Instance.new("Folder"); folder.Name="Linha11Chapter"..id.."World"; folder:SetAttribute("ChapterId",id); folder.Parent=workspace
	local theme=info.Theme
	local floorMat=theme=="street" and Enum.Material.Asphalt or Enum.Material.Concrete
	part(folder,id,"Piso_Base",Vector3.new(110,.55,26),pos(id,55,-.35,0),Color3.fromRGB(53,51,47),floorMat)
	if theme~="street" then
		part(folder,id,"Teto_Base",Vector3.new(110,.5,26),pos(id,55,11.5,0),Color3.fromRGB(31,32,31),Enum.Material.Concrete)
		part(folder,id,"Parede_Norte",Vector3.new(110,11, .5),pos(id,55,5.5,-12.8),Color3.fromRGB(91,86,77),Enum.Material.Plaster)
		part(folder,id,"Parede_Sul",Vector3.new(110,11,.5),pos(id,55,5.5,12.8),Color3.fromRGB(91,86,77),Enum.Material.Plaster)
		for _,x in ipairs({34,67}) do
			part(folder,id,"Divisoria_Ala_A",Vector3.new(.45,10,9),pos(id,x,5,-8),Color3.fromRGB(80,77,70),Enum.Material.Concrete)
			part(folder,id,"Divisoria_Ala_B",Vector3.new(.45,10,9),pos(id,x,5,8),Color3.fromRGB(80,77,70),Enum.Material.Concrete)
		end
	end
	furniture(folder,id,theme)
	for _,x in ipairs({12,48,86}) do light(folder,id,x,0) end
	for i=1,3 do
		local x=15+(i-1)*20
		part(folder,id,"Mesa_Pista_"..i,Vector3.new(4,.24,2.8),pos(id,x,1.8,3),Color3.fromRGB(75,57,43),Enum.Material.WoodPlanks)
		document(folder,id,i,x,1.95,3)
	end
	for _,side in ipairs({"A","B","C"}) do
		local data=info.StepLabels[side]
		part(folder,id,"Console_"..side,Vector3.new(2.8,2.5,1.4),pos(id,63+(string.byte(side)-65)*13,1.25,-3),Color3.fromRGB(57,63,63),Enum.Material.Metal)
		anchor(folder,id,"Etapa_"..side,63+(string.byte(side)-65)*13,2.4,-2,"C"..id.."_Step"..side,data.Action,data.Object,.55)
	end
	anchor(folder,id,"Registro_Final",99,2,0,"C"..id.."_Report","Registrar","Caderno de campo",.55)
	if id==12 then
		anchor(folder,id,"Transmitir_Prova",91,2,6,"C12_Transmit","Transmitir","Prova integral",.75)
		anchor(folder,id,"Cortar_Linha",91,2,-6,"C12_Cut","Cortar","Repetidor principal",.75)
	end
	if id==8 then anchor(folder,id,"Esconder_Atrás_Biombo",54,2,-7,"Hide_Triage","Esconder","Biombo da enfermaria",.6) end
	local s=Instance.new("SpawnLocation"); s.Name="InicioCapitulo"..id; s.Size=Vector3.new(4,.6,4); s.Position=pos(id,4,.1,0)
	s.Anchored=true; s.Transparency=1; s.CanCollide=false; s.Neutral=true; s.Duration=0; s.Parent=folder
	worlds[id]=folder; spawns[id]=s
end
function Map.BuildAll()
	table.clear(worlds); table.clear(spawns); table.clear(prompts); table.clear(batteries)
	for id=4,12 do
		local old=workspace:FindFirstChild("Linha11Chapter"..id.."World"); if old then old:Destroy() end
		buildOne(id)
	end
	for _,world in pairs(worlds) do for _,item in ipairs(world:GetDescendants()) do if item:IsA("ProximityPrompt") then table.insert(prompts,item) end end end
	return worlds,spawns,prompts
end
function Map.GetAIConfig(id)
	local b=base(id); return {minX=b+2,maxX=b+106,pingMinX=b-8,pingMaxX=b+112,startX=b+101,z=0}
end
function Map.MoveBattery(id)
	local item=batteries[id]; if not item then return false end
	TweenService:Create(item.part,TweenInfo.new(2.5,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{CFrame=item.to}):Play()
	return true
end
return Map