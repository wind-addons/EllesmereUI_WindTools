local addon = select(2, ...)
local W = addon[1]
local E = addon[3]
local DBGet = addon.DBGet
local DBSet = addon.DBSet
local DBGet2 = addon.DBGet2
local DBSet2 = addon.DBSet2
local FontSection = addon.FontSection

local ALREADY_KNOWN_MODE = { COLOR = "Custom Color", MONOCHROME = "Monochrome" }
local ALREADY_KNOWN_MODE_ORDER = { "COLOR", "MONOCHROME" }

local DELETE_FILL_VALUES = { NONE = "Disable", CLICK = "Fill by click", AUTO = "Auto Fill" }
local DELETE_FILL_ORDER = { "NONE", "CLICK", "AUTO" }

local CONTACTS_PAGE_VALUES = {
	ALTS = "Alternate Character",
	FRIENDS = "Online Friends",
	GUILD = "Guild Members",
	FAVORITE = "My Favorites",
}
local CONTACTS_PAGE_ORDER = { "ALTS", "FRIENDS", "GUILD", "FAVORITE" }

addon.RegisterOptionBuilder("item", function(parent, y, cat)
	local Widgets = EllesmereUI.Widgets
	local MH = function(mod, sub) return addon.MakeHeader(cat, mod, sub) end
	local _, h
	local db = E.db.WT.item
	local pdb = E.private.WT.item

	_, h = Widgets:SectionHeader(parent, MH("Delete Item"), y); y = y - h
	do
		local dl = db.delete
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(dl, "enable"), DBSet(dl, "enable"),
			"This module provides several easy-to-use methods of deleting items."); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Use Delete Key", tooltip = "Allow you to use Delete Key for confirming deleting.",
			  getValue = DBGet(dl, "delKey"), setValue = DBSet(dl, "delKey") },
			{ type = "dropdown", text = "Fill In",
			  values = DELETE_FILL_VALUES, order = DELETE_FILL_ORDER,
			  getValue = DBGet(dl, "fillIn"), setValue = DBSet(dl, "fillIn") }
		); y = y - h
	end

	_, h = Widgets:SectionHeader(parent, MH("Already Known"), y); y = y - h
	do
		local ak = db.alreadyKnown
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(ak, "enable"), DBSet(ak, "enable"),
			"Puts a overlay on already known learnable items on vendors and AH."); y = y - h
		_, h = Widgets:Dropdown(parent, "Mode", y,
			ALREADY_KNOWN_MODE,
			DBGet(ak, "mode"), DBSet(ak, "mode"),
			ALREADY_KNOWN_MODE_ORDER); y = y - h
		if ak.mode == "COLOR" then
			_, h = Widgets:ColorPicker(parent, "Color", y,
				function()
					local c = ak.color or {}
					return c.r or 1, c.g or 0, c.b or 0, 1
				end,
				function(r, g, b)
					ak.color = ak.color or {}
					ak.color.r, ak.color.g, ak.color.b = r, g, b
				end, false); y = y - h
		end
	end

	_, h = Widgets:SectionHeader(parent, MH("Fast Loot"), y); y = y - h
	do
		local fl = db.fastLoot
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(fl, "enable"), DBSet(fl, "enable"),
			"This module will accelerate the speed of loot."); y = y - h
		_, h = Widgets:Slider(parent, "Limit", y, 0.05, 0.5, 0.01,
			DBGet(fl, "limit"), DBSet(fl, "limit"),
			"The time delay between every loot operations. (Default is 0.3)"); y = y - h
	end

	_, h = Widgets:SectionHeader(parent, MH("Trade"), y); y = y - h
	do
		local td = db.trade
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(td, "enable"), DBSet(td, "enable"),
			"Add some features on Trade Frame."); y = y - h
		_, h = Widgets:Toggle(parent, "Thanks Button", y,
			DBGet(td, "thanksButton"), DBSet(td, "thanksButton")); y = y - h
	end

	_, h = Widgets:SectionHeader(parent, MH("Contacts"), y); y = y - h
	do
		local ct = db.contacts
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(ct, "enable"), DBSet(ct, "enable"),
			"Add a contact frame beside the mail frame."); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Update Alts", tooltip = "Update the alt list when you log in.",
			  getValue = function() return E.global.WT.item.contacts.updateAlts end,
			  setValue = function(v) E.global.WT.item.contacts.updateAlts = v end },
			{ type = "dropdown", text = "Default Page",
			  values = CONTACTS_PAGE_VALUES, order = CONTACTS_PAGE_ORDER,
			  getValue = DBGet(ct, "defaultPage"), setValue = DBSet(ct, "defaultPage") }
		); y = y - h
	end

	_, h = Widgets:SectionHeader(parent, MH("Inspect"), y); y = y - h
	do
		local is = db.inspect
		local isDis = function() return not is.enable end
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(is, "enable"), DBSet(is, "enable"),
			"This module will add an equipment list beside the character panel and inspect frame."); y = y - h
		_, h = Widgets:SectionHeader(parent, MH("Inspect", "Lists"), y); y = y - h
		_, h = Widgets:DualRow(parent, y,
			{ type = "toggle", text = "Player", tooltip = "Add a frame to your character panel.",
			  getValue = DBGet(is, "player"), setValue = DBSet(is, "player"), disabled = isDis },
			{ type = "toggle", text = "Inspect", tooltip = "Add a frame to Inspect Frame.",
			  getValue = DBGet(is, "inspect"), setValue = DBSet(is, "inspect"), disabled = isDis }
		); y = y - h
		if is.inspect then
			_, h = Widgets:SectionHeader(parent, MH("Inspect", "Additional Information"), y); y = y - h
			_, h = Widgets:Toggle(parent, "Always Show Mine", y,
				DBGet(is, "playerOnInspect"), DBSet(is, "playerOnInspect"),
				"Display character equipments list when you inspect someone."); y = y - h
		end
		_, h = Widgets:SectionHeader(parent, MH("Inspect", "Slot"), y); y = y - h
		y = FontSection(Widgets, parent, y, is.slotText)
		_, h = Widgets:SectionHeader(parent, MH("Inspect", "Item Level"), y); y = y - h
		y = FontSection(Widgets, parent, y, is.levelText)
		_, h = Widgets:SectionHeader(parent, MH("Inspect", "Item Icon"), y); y = y - h
		do
			local ii = is.itemIcon
			_, h = Widgets:DualRow(parent, y,
				{ type = "toggle", text = "Show Icon",
				  getValue = DBGet(ii, "enable"), setValue = DBSet(ii, "enable"), disabled = isDis },
				{ type = "toggle", text = "Quality Border", tooltip = "Show the quality border on the icon.",
				  getValue = DBGet(ii, "qualityBorder"), setValue = DBSet(ii, "qualityBorder"), disabled = isDis }
			); y = y - h
			_, h = Widgets:DualRow(parent, y,
				{ type = "slider", text = "Width", min = 5, max = 40, step = 1,
				  getValue = DBGet(ii, "width"), setValue = DBSet(ii, "width"), disabled = isDis },
				{ type = "slider", text = "Height", min = 5, max = 40, step = 1,
				  getValue = DBGet(ii, "height"), setValue = DBSet(ii, "height"), disabled = isDis }
			); y = y - h
			_, h = Widgets:Toggle(parent, "Indicator", y,
				DBGet(ii, "indicator"), DBSet(ii, "indicator"),
				"Show the special mark on the icon to indicate the crafting quality, tier set, etc."); y = y - h
		end
		_, h = Widgets:SectionHeader(parent, MH("Inspect", "Item Name"), y); y = y - h
		y = FontSection(Widgets, parent, y, is.itemNameText)
		_, h = Widgets:SectionHeader(parent, MH("Inspect", "Enchant Icon"), y); y = y - h
		do
			local ei = is.enchantIcon
			_, h = Widgets:DualRow(parent, y,
				{ type = "toggle", text = "Show Icon",
				  getValue = DBGet(ei, "enable"), setValue = DBSet(ei, "enable"), disabled = isDis },
				{ type = "slider", text = "Size", min = 5, max = 30, step = 1,
				  getValue = DBGet(ei, "size"), setValue = DBSet(ei, "size"), disabled = isDis }
			); y = y - h
		end
		_, h = Widgets:SectionHeader(parent, MH("Inspect", "Gem Icon"), y); y = y - h
		do
			local gi = is.gemIcon
			_, h = Widgets:DualRow(parent, y,
				{ type = "toggle", text = "Show Icon",
				  getValue = DBGet(gi, "enable"), setValue = DBSet(gi, "enable"), disabled = isDis },
				{ type = "toggle", text = "Show Addable Sockets", tooltip = "Show the icon of addable sockets if the item has empty sockets.",
				  getValue = DBGet(gi, "showAddableSockets"), setValue = DBSet(gi, "showAddableSockets"), disabled = isDis }
			); y = y - h
			_, h = Widgets:Slider(parent, "Size", y, 5, 30, 1,
				DBGet(gi, "size"), DBSet(gi, "size"), nil, isDis); y = y - h
		end
	end

	_, h = Widgets:SectionHeader(parent, MH("Item Level"), y); y = y - h
	do
		local il = db.itemLevel
		local ilDis = function() return not il.enable end
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(il, "enable"), DBSet(il, "enable"),
			"Add an extra item level text to some equipment buttons."); y = y - h

		_, h = Widgets:SectionHeader(parent, MH("Item Level", "Flyout Button"), y); y = y - h
		do
			local fo = il.flyout
			_, h = Widgets:Toggle(parent, "Enable", y,
				DBGet(fo, "enable"), DBSet(fo, "enable"), nil, ilDis); y = y - h
			_, h = Widgets:Toggle(parent, "Use Bags Setting", y,
				DBGet(fo, "useBagsFontSetting"), DBSet(fo, "useBagsFontSetting"),
				"Render the item level text with the setting in ElvUI bags.", ilDis); y = y - h
			if not fo.useBagsFontSetting then
				y = FontSection(Widgets, parent, y, fo.font)
			end
		end

		_, h = Widgets:SectionHeader(parent, MH("Item Level", "Scrapping Machine"), y); y = y - h
		do
			local sm = il.scrappingMachine
			_, h = Widgets:Toggle(parent, "Enable", y,
				DBGet(sm, "enable"), DBSet(sm, "enable"), nil, ilDis); y = y - h
			_, h = Widgets:Toggle(parent, "Use Bags Setting", y,
				DBGet(sm, "useBagsFontSetting"), DBSet(sm, "useBagsFontSetting"),
				"Render the item level text with the setting in ElvUI bags.", ilDis); y = y - h
			if not sm.useBagsFontSetting then
				y = FontSection(Widgets, parent, y, sm.font)
			end
		end
	end

	_, h = Widgets:SectionHeader(parent, MH("Extend Merchant Pages"), y); y = y - h
	do
		local emp = pdb.extendMerchantPages
		_, h = Widgets:Toggle(parent, "Enable", y,
			DBGet(emp, "enable"), DBSet(emp, "enable"),
			"Extends the merchant page to show more items."); y = y - h
		_, h = Widgets:Slider(parent, "Number of Pages", y, 2, 6, 1,
			DBGet(emp, "numberOfPages"), DBSet(emp, "numberOfPages"),
			"The number of pages shown in the merchant frame."); y = y - h
	end

	return y
end)
