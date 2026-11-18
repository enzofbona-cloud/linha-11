-- Confere a montagem dos 12 mapas: cada interação precisa ficar fora de peças
-- sólidas e ter um lugar livre por perto onde o jogador consiga ficar em pé.
T.startServer()
local E = SIM.env

local function box(part)
	local p, s = part.Position, part.Size
	return p.X - s.X / 2, p.X + s.X / 2, p.Y - s.Y / 2, p.Y + s.Y / 2, p.Z - s.Z / 2, p.Z + s.Z / 2
end

local function inside(part, point, margin)
	margin = margin or 0
	local x0, x1, y0, y1, z0, z1 = box(part)
	return point.X > x0 - margin and point.X < x1 + margin and point.Y > y0 - margin and point.Y < y1 + margin
		and point.Z > z0 - margin and point.Z < z1 + margin
end

for _, area in ipairs(E.workspace:GetChildren()) do
	if string.sub(area.Name, 1, 7) == "Linha11" then
		local solids, prompts, floors = {}, {}, {}
		for _, item in ipairs(area:GetDescendants()) do
			if item:IsA("BasePart") and item.CanCollide ~= false and item.Transparency < 1 then
				table.insert(solids, item)
				if item.Size.Y < 1.2 and item.Position.Y < 0.5 then table.insert(floors, item) end
			elseif rawget(item, "__class") == "ProximityPrompt" then
				table.insert(prompts, item)
			end
		end
		T.context = area.Name .. ": "
		local blocked = 0
		for _, prompt in ipairs(prompts) do
			local host = prompt.Parent
			local id = prompt:GetAttribute("ActionId")
			local anchor = host.Position
			local isDoor = string.sub(id, 1, 5) == "Door_" or id == "C2_Door304"
			-- a interação não pode estar dentro de uma peça sólida (exceto a própria e portas)
			if not isDoor and host.Transparency >= 1 then
				for _, solid in ipairs(solids) do
					if solid ~= host and inside(solid, anchor, -0.05) and solid.Size.Y > 0.6 then
						T.fail(id .. " fica dentro de " .. solid.Name)
						break
					end
				end
			end
			-- precisa existir um ponto de pé livre ao alcance (corpo de 2 x 5 x 1)
			local reach = math.max(prompt.MaxActivationDistance - 1, 4)
			local found = false
			for radius = 2, reach, 1 do
				for step = 0, 15 do
					local angle = step / 16 * math.pi * 2
					local foot = E.Vector3.new(anchor.X + math.cos(angle) * radius, 0.3, anchor.Z + math.sin(angle) * radius)
					local onFloor = false
					for _, floor in ipairs(floors) do
						local x0, x1, _, _, z0, z1 = box(floor)
						if foot.X > x0 and foot.X < x1 and foot.Z > z0 and foot.Z < z1 then onFloor = true break end
					end
					if onFloor then
						local free = true
						for _, solid in ipairs(solids) do
							if solid.Size.Y > 0.6 and solid.Position.Y + solid.Size.Y / 2 > 0.6 then
								for _, h in ipairs({ 1, 2.5, 4 }) do
									if inside(solid, E.Vector3.new(foot.X, h, foot.Z), 0.9) then free = false break end
								end
							end
							if not free then break end
						end
						if free then found = true break end
					end
				end
				if found then break end
			end
			if not found then
				blocked += 1
				T.fail(id .. " não tem lugar livre por perto para o jogador ficar")
			end
			T.checks += 1
		end
		print(string.format("%s: %d interações, %d sem acesso", area.Name, #prompts, blocked))
	end
end
T.finish()
