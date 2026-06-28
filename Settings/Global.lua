local G ---@class GlobalDB
local W, F, E, L, V, P ---@type WindTools, Functions, ElvUI, LocaleTable, PrivateDB, ProfileDB
W, F, E, L, V, P, G = unpack((select(2, ...)))

G.core = {
	compatibilityCheck = true,
	changlogPopup = false,
	elvUIVersionPopup = true,
	cvarAlert = false,
	fixSetPassThroughButtons = false,
	loginMessage = true,
	autoCopyPrivateProfile = {
		enable = false,
		copyFrom = nil,
		initializedCharacters = {},
	},
}

G.developer = {
	logLevel = 2,
	tableAttributeDisplay = {
		enable = false,
		width = 1000,
		height = 600,
	},
}

G.item = {
	contacts = {
		alts = {},
		favorites = {},
		updateAlts = true,
	},
	extraItemsBar = {
		bar1 = {},
		bar2 = {},
		bar3 = {},
		bar4 = {},
		bar5 = {},
	},
}

G.combat = {
	covenantHelper = {
		soulbindRules = {
			characters = {},
		},
	},
}

G.misc = {
	watched = {
		movies = {},
	},
	lfgList = {},
}

G.maps = {
	eventTracker = {},
}

G.social = {
	chatBar = {
		-- Mover position saved at account level so layout is shared across
		-- characters. Populated by EllesmereUI Unlock Mode via the
		-- RegisterUnlockElements API. Nil = use default anchor (above LeftChatPanel).
		position = nil,
	},
}
