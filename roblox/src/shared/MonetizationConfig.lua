local MonetizationConfig = {}

-- Crie estes passes no Creator Hub depois de publicar a experiência.
-- Substitua 0 pelos IDs reais. IDs zerados mantêm a compra desativada no protótipo.
MonetizationConfig.Passes = {
	AmberLight = {
		id = 0,
		name = "Lanterna âmbar",
		description = "Uma cor alternativa para a lanterna. Não aumenta o alcance nem a força.",
		kind = "cosmetic",
	},
	AuroraBadge = {
		id = 0,
		name = "Distintivo Aurora",
		description = "Um distintivo visual de apoiador sobre o personagem.",
		kind = "cosmetic",
	},
}

return MonetizationConfig
